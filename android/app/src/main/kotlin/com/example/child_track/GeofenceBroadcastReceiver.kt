package com.truenyx.naviqandroid

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofenceStatusCodes
import com.google.android.gms.location.GeofencingEvent
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * Manifest-registered receiver for native Android geofence transitions.
 *
 * This is the piece that makes geofence detection survive a force-kill: Android
 * invokes a manifest-registered BroadcastReceiver for a matching PendingIntent
 * even when the app process (and any Dart isolate / foreground service) is
 * completely dead, giving it a short execution window to do work. It does NOT
 * spin up the Flutter engine — it POSTs to the backend directly via
 * NativeApiClient, using credentials mirrored into plain SharedPreferences by
 * the Dart side (see ChildRepo.syncAppGroupCredentials).
 */
class GeofenceBroadcastReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "GeofenceReceiver"
        const val ACTION_GEOFENCE_EVENT = "com.truenyx.naviqandroid.GEOFENCE_TRANSITION"
        private const val KEY_PENDING_QUEUE = "flutter.native_pending_geofence_events"

        private fun isoNow(): String {
            val fmt = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
            fmt.timeZone = TimeZone.getTimeZone("UTC")
            return fmt.format(Date())
        }

        private fun transitionTypeToString(transition: Int): String = when (transition) {
            Geofence.GEOFENCE_TRANSITION_ENTER -> "ENTER"
            Geofence.GEOFENCE_TRANSITION_EXIT -> "EXIT"
            Geofence.GEOFENCE_TRANSITION_DWELL -> "DWELL"
            else -> "UNKNOWN"
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val geofencingEvent = GeofencingEvent.fromIntent(intent)
        if (geofencingEvent == null) {
            Log.w(TAG, "onReceive: not a geofencing event intent, ignoring")
            return
        }

        if (geofencingEvent.hasError()) {
            val errorMessage = GeofenceStatusCodes.getStatusCodeString(geofencingEvent.errorCode)
            Log.e(TAG, "GeofencingEvent error: $errorMessage")
            return
        }

        val transitionType = transitionTypeToString(geofencingEvent.geofenceTransition)
        val triggeringIds = geofencingEvent.triggeringGeofences?.map { it.requestId } ?: emptyList()
        if (triggeringIds.isEmpty()) {
            Log.w(TAG, "onReceive: no triggering geofences in event")
            return
        }

        Log.i(TAG, "Geofence transition $transitionType for: $triggeringIds")
        val names = triggeringIds.joinToString(", ") { "$it(${NativeGeofenceManager.getGeofenceName(context, it)})" }
        NativeFileLogger.log(context, "GEOFENCE", "received transition=$transitionType ids=$names")

        // BroadcastReceiver.onReceive gets a very short window (~10s) and must not
        // block on network I/O directly — goAsync() extends that window slightly
        // and lets us finish the work on a background thread.
        val pendingResult = goAsync()
        val appContext = context.applicationContext

        Thread {
            try {
                // Best-effort: flush anything queued from a previous failed attempt first.
                flushPendingQueue(appContext)

                val childId = NativeApiClient.getChildId(appContext)
                if (childId.isNullOrEmpty()) {
                    Log.w(TAG, "No child_id available, dropping geofence event(s)")
                    NativeFileLogger.log(appContext, "GEOFENCE", "dropped: no child_id available")
                    return@Thread
                }

                val timestamp = isoNow()
                for (geofenceId in triggeringIds) {
                    val payload = JSONObject().apply {
                        put("childId", childId)
                        put("geofenceId", geofenceId)
                        put("eventType", transitionType)
                        put("timestamp", timestamp)
                        put("source", "android_native_geofence")
                    }
                    val posted = NativeApiClient.postJson(appContext, "child/geofence-event", payload)
                    Log.i(TAG, "postGeofenceEvent: posted=$posted for $transitionType on $geofenceId")
                    NativeFileLogger.log(
                        appContext, "GEOFENCE",
                        "post transition=$transitionType id=$geofenceId ts=$timestamp posted=$posted"
                    )
                    if (!posted) {
                        enqueuePending(appContext, payload)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error handling geofence event: ${e.message}", e)
                NativeFileLogger.log(appContext, "GEOFENCE", "ERROR ${e.message}")
            } finally {
                pendingResult.finish()
            }
        }.start()
    }

    private fun enqueuePending(context: Context, payload: JSONObject) {
        val prefs = context.getSharedPreferences(NativeGeofenceManager.PREFS_NAME, Context.MODE_PRIVATE)
        val raw = prefs.getString(KEY_PENDING_QUEUE, "[]")
        val queue = try { JSONArray(raw) } catch (e: Exception) { JSONArray() }
        queue.put(payload)
        // Cap the queue so a prolonged outage can't grow this unbounded.
        val trimmed = if (queue.length() > 50) {
            JSONArray().apply {
                for (i in (queue.length() - 50) until queue.length()) put(queue.get(i))
            }
        } else queue
        prefs.edit().putString(KEY_PENDING_QUEUE, trimmed.toString()).apply()
    }

    private fun flushPendingQueue(context: Context) {
        val prefs = context.getSharedPreferences(NativeGeofenceManager.PREFS_NAME, Context.MODE_PRIVATE)
        val raw = prefs.getString(KEY_PENDING_QUEUE, null) ?: return
        val queue = try { JSONArray(raw) } catch (e: Exception) { return }
        if (queue.length() == 0) return

        val stillPending = JSONArray()
        for (i in 0 until queue.length()) {
            val entry = queue.optJSONObject(i) ?: continue
            if (!NativeApiClient.postJson(context, "child/geofence-event", entry)) {
                stillPending.put(entry)
            }
        }
        prefs.edit().putString(KEY_PENDING_QUEUE, stillPending.toString()).apply()
    }
}
