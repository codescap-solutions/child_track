package com.truenyx.naviqandroid

import android.content.Context
import android.util.Log
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

/**
 * Watchdog only — NOT the primary location-ping delivery mechanism (that's
 * NativeLocationPingManager's FusedLocationProviderClient + PendingIntent
 * registration). This periodically re-arms that registration in case Play
 * Services silently dropped it, which is a known real-world occurrence after
 * a Play Services update or a device reboot.
 *
 * 15 minutes is WorkManager's hard floor for periodic work (PeriodicWorkRequest
 * .MIN_PERIODIC_INTERVAL_MILLIS) — it cannot be configured shorter.
 */
class LocationWatchdogWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        val childId = NativeApiClient.getChildId(applicationContext)
        if (!childId.isNullOrEmpty()) {
            Log.i("LocationWatchdog", "Re-arming native background location updates")
            NativeFileLogger.log(applicationContext, "WATCHDOG", "re-arming location pings")
            NativeLocationPingManager.start(applicationContext)
        }
        return Result.success()
    }

    companion object {
        private const val WORK_NAME = "native_location_watchdog"

        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<LocationWatchdogWorker>(15, TimeUnit.MINUTES).build()
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request
            )
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        }
    }
}
