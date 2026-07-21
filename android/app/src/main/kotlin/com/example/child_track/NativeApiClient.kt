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
     * POST JSON to `${DEFAULT_API_BASE}$path`. Returns true if the request reached
     * the server (any HTTP response, including 4xx validation errors) — only
     * network/timeout failures return false, since those are the only cases
     * worth retrying later.
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
            connection.responseCode in 200..599
        } catch (e: Exception) {
            false
        } finally {
            connection?.disconnect()
        }
    }
}
