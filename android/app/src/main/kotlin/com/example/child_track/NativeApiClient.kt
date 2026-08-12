package com.truenyx.naviqandroid

import android.content.Context
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

/**
 * Shared native HTTP client for background receivers (geofence transitions,
 * location pings) that must POST to the backend without the Flutter engine
 * running. Reads credentials mirrored into plain SharedPreferences by Dart
 * (see ChildRepo.syncAppGroupCredentials).
 */
object NativeApiClient {
    private const val PREFS_NAME = NativeGeofenceManager.PREFS_NAME
    private const val KEY_AUTH_TOKEN = "flutter.native_auth_token"
    private const val KEY_CHILD_ID = "flutter.child_id"
    const val DEFAULT_API_BASE = "https://naviq-server.codescap.com/api/v1/"
    private const val CONNECT_TIMEOUT_MS = 6000
    private const val READ_TIMEOUT_MS = 6000

    fun getChildId(context: Context): String? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString(KEY_CHILD_ID, null)
    }

    private fun getAuthToken(context: Context): String? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString(KEY_AUTH_TOKEN, null)
    }

    /** Delay before a single 401 retry — see [postJson]. */
    private const val AUTH_RETRY_DELAY_MS = 2000L

    /**
     * POST JSON to `${DEFAULT_API_BASE}$path`. Returns true if the request was
     * actually processed by the app (2xx success, or a non-401 4xx — a
     * validation rejection that would just repeat forever, not worth
     * retrying). Returns false — worth retrying later, via the caller's own
     * pending-queue — for network/timeout failures, 5xx server errors, and a
     * 401 that didn't clear after one retry.
     *
     * 401 used to be lumped in with "non-401 4xx" (`responseCode < 500`) and
     * counted as posted — silently and *permanently* discarding the event,
     * since callers only enqueue for retry when this returns false. That was
     * wrong specifically for 401: child sessions have no refresh_token and
     * their JWTs don't expire by design (see dio_client.dart's onError
     * handler for the Dart-side version of this same fix), so a 401 reaching
     * this native, engine-less path is almost always a token-read race —
     * this receiver read SharedPreferences at the exact moment the Dart side
     * was mid-write to the same key (ChildRepo.syncAppGroupCredentials), not
     * a genuinely dead session. One retry after a short delay, re-reading
     * whatever token is current by then, covers that race without treating
     * an actually-invalid 400/403/404/etc. as retryable forever.
     */
    fun postJson(context: Context, path: String, payload: JSONObject): Boolean {
        val token = getAuthToken(context)
        if (token.isNullOrEmpty()) return false

        val firstCode = doPost(path, token, payload)
        if (firstCode != 401) return firstCode in 200 until 500

        Thread.sleep(AUTH_RETRY_DELAY_MS)
        val retryToken = getAuthToken(context)
        if (retryToken.isNullOrEmpty()) return false
        val retryCode = doPost(path, retryToken, payload)
        return retryCode in 200..299
    }

    /** Fires one POST attempt. Returns the HTTP status code, or -1 on a network/timeout exception. */
    private fun doPost(path: String, token: String, payload: JSONObject): Int {
        var connection: HttpURLConnection? = null
        return try {
            val url = URL(DEFAULT_API_BASE + path)
            connection = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                doOutput = true
                connectTimeout = CONNECT_TIMEOUT_MS
                readTimeout = READ_TIMEOUT_MS
                setRequestProperty("Content-Type", "application/json")
                setRequestProperty("Authorization", "Bearer $token")
            }
            connection.outputStream.use { it.write(payload.toString().toByteArray(Charsets.UTF_8)) }
            connection.responseCode
        } catch (e: Exception) {
            -1
        } finally {
            connection?.disconnect()
        }
    }
}
