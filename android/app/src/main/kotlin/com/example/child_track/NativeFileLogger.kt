package com.truenyx.naviqandroid

import android.content.Context
import android.util.Log
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * Persistent, pullable log for the native background components (geofencing,
 * location pings, watchdog) — exists specifically so behavior survives a
 * force-kill test that Logcat can't: once the process is dead there's no live
 * Logcat session watching it, and by the time you reconnect adb the ring
 * buffer has usually rotated past what happened anyway.
 *
 * Written to the app's external files dir (no permission needed on API 19+),
 * so it's retrievable any time via:
 *   adb pull /sdcard/Android/data/com.truenyx.naviqandroid/files/logs/native_bg.log
 */
object NativeFileLogger {
    private const val TAG = "NativeFileLogger"
    private const val LOG_DIR = "logs"
    private const val LOG_FILE = "native_bg.log"
    private const val MAX_BYTES = 2 * 1024 * 1024 // 2MB — trim to newest half past this

    private fun isoNow(): String {
        val fmt = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        fmt.timeZone = TimeZone.getTimeZone("UTC")
        return fmt.format(Date())
    }

    private fun logFile(context: Context): File? {
        val dir = context.applicationContext.getExternalFilesDir(LOG_DIR) ?: return null
        if (!dir.exists()) dir.mkdirs()
        return File(dir, LOG_FILE)
    }

    @Synchronized
    fun log(context: Context, tag: String, message: String) {
        try {
            val file = logFile(context) ?: return
            trimIfNeeded(file)
            file.appendText("${isoNow()} [$tag] $message\n")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to write native log: ${e.message}")
        }
    }

    private fun trimIfNeeded(file: File) {
        if (!file.exists() || file.length() <= MAX_BYTES) return
        try {
            val lines = file.readLines()
            val keep = lines.subList(lines.size / 2, lines.size)
            file.writeText(keep.joinToString("\n", postfix = "\n"))
        } catch (e: Exception) {
            // Best-effort trim; if it fails, just let the file keep growing rather than lose it.
        }
    }
}
