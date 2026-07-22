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

    /**
     * POST JSON to `${DEFAULT_API_BASE}$path`. Returns true if the request was
     * actually processed by the app (2xx success, or 4xx — a validation/auth
     * rejection that would just repeat forever, not worth retrying). Returns
     * false — worth retrying later — for network/timeout failures AND 5xx
     * server errors, since a transient server bug (e.g. an unhandled
     * exception on the backend) must not silently and permanently drop the
     * event the way treating it as "posted" would.
     */
    fun postJson(context: Context, path: String, payload: JSONObject): Boolean {
        val token = getAuthToken(context)
        if (token.isNullOrEmpty()) return false

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
            connection.responseCode < 500
        } catch (e: Exception) {
            false
        } finally {
            connection?.disconnect()
        }
    }
}
