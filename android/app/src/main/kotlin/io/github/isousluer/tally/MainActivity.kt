package io.github.isousluer.tally

import android.app.PictureInPictureParams
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.Context
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.Manifest
import android.media.AudioManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.os.Build
import android.os.StatFs
import android.provider.Settings
import android.util.Rational
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the Flutter UI and exposes a few device controls the player needs:
 * screen brightness, media volume, picture-in-picture and TV detection.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null

    /** True while a video is open, so leaving the app enters picture-in-picture. */
    private var autoPip = false
    private var pipAspect = Rational(16, 9)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        instance = this
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tally/device")
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "getBrightness" -> result.success(currentBrightness())
                "setBrightness" -> {
                    val v = (call.arguments as Number).toFloat().coerceIn(0.01f, 1f)
                    setWindowBrightness(v)
                    result.success(null)
                }
                "resetBrightness" -> {
                    setWindowBrightness(WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE)
                    result.success(null)
                }
                "getVolume" -> {
                    val am = audio()
                    val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC).coerceAtLeast(1)
                    result.success(am.getStreamVolume(AudioManager.STREAM_MUSIC).toDouble() / max)
                }
                "setVolume" -> {
                    val am = audio()
                    val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                    val v = (call.arguments as Number).toDouble().coerceIn(0.0, 1.0)
                    am.setStreamVolume(AudioManager.STREAM_MUSIC, Math.round(v * max).toInt(), 0)
                    result.success(null)
                }
                "pipSupported" -> result.success(pipSupported())
                "setAutoPip" -> {
                    val args = call.arguments as Map<*, *>
                    autoPip = args["enabled"] as Boolean
                    val w = (args["width"] as? Number)?.toInt() ?: 16
                    val h = (args["height"] as? Number)?.toInt() ?: 9
                    pipAspect = clampAspect(w, h)
                    updatePipParams()
                    result.success(null)
                }
                "enterPip" -> result.success(enterPip())
                "startAudioOnly" -> {
                    val args = call.arguments as Map<*, *>
                    askForNotifications()
                    val intent = Intent(this, PlaybackService::class.java)
                        .putExtra(PlaybackService.EXTRA_TITLE, args["title"] as? String)
                        .putExtra(PlaybackService.EXTRA_TEXT, args["text"] as? String)
                        .putExtra(PlaybackService.EXTRA_STOP, args["stop"] as? String)
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent) else startService(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }
                "stopAudioOnly" -> {
                    stopService(Intent(this, PlaybackService::class.java))
                    result.success(null)
                }
                "onMobileData" -> result.success(onMobileData())
                "freeSpace" -> result.success(
                    try {
                        StatFs(((call.arguments as? String) ?: cacheDir.absolutePath)).availableBytes
                    } catch (_: Exception) {
                        null
                    }
                )
                "openExternally" -> {
                    val args = call.arguments as Map<*, *>
                    result.success(openExternally(args["url"] as String, args["title"] as? String))
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Called by the notification's Stop button. */
    fun notifyAudioStopped() {
        runOnUiThread { channel?.invokeMethod("audioStopped", null) }
    }

    /** Android 13 and later need the viewer's yes to show the playback notification. */
    private fun askForNotifications() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 3)
        }
    }

    /** True when the phone is online through mobile data rather than Wi-Fi. */
    private fun onMobileData(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val caps = cm.getNetworkCapabilities(cm.activeNetwork) ?: return false
        return caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) &&
            !caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
    }

    override fun onDestroy() {
        if (instance === this) instance = null
        stopService(Intent(this, PlaybackService::class.java))
        super.onDestroy()
    }

    /** Hands a stream to another video app, letting the viewer pick which one. */
    private fun openExternally(url: String, title: String?): Boolean {
        val view = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(Uri.parse(url), "video/*")
            if (title != null) {
                putExtra("title", title) // MX Player, VLC and most others
                putExtra(Intent.EXTRA_TITLE, title)
            }
        }
        return try {
            startActivity(Intent.createChooser(view, title))
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }

    private fun audio() = getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private fun currentBrightness(): Double {
        val override = window.attributes.screenBrightness
        if (override >= 0) return override.toDouble()
        return try {
            Settings.System.getInt(contentResolver, Settings.System.SCREEN_BRIGHTNESS) / 255.0
        } catch (e: Exception) {
            0.5
        }
    }

    private fun setWindowBrightness(v: Float) {
        val lp = window.attributes
        lp.screenBrightness = v
        window.attributes = lp
    }

    private fun pipSupported() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
        packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)

    // Android only accepts ratios between 1:2.39 and 2.39:1.
    private fun clampAspect(w: Int, h: Int): Rational {
        if (w <= 0 || h <= 0) return Rational(16, 9)
        val r = w.toDouble() / h
        return when {
            r > 2.39 -> Rational(239, 100)
            r < 1 / 2.39 -> Rational(100, 239)
            else -> Rational(w, h)
        }
    }

    private fun updatePipParams() {
        if (!pipSupported()) return
        val b = PictureInPictureParams.Builder().setAspectRatio(pipAspect)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) b.setAutoEnterEnabled(autoPip)
        try {
            setPictureInPictureParams(b.build())
        } catch (_: Exception) {
        }
    }

    private fun enterPip(): Boolean {
        if (!pipSupported()) return false
        return try {
            enterPictureInPictureMode(PictureInPictureParams.Builder().setAspectRatio(pipAspect).build())
        } catch (_: Exception) {
            false
        }
    }

    // Android 8–11 have no auto-enter flag, so enter manually on Home.
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (autoPip && Build.VERSION.SDK_INT < Build.VERSION_CODES.S) enterPip()
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        channel?.invokeMethod("pipChanged", isInPictureInPictureMode)
    }

    companion object {
        /** The running activity, for the playback service to call back. */
        var instance: MainActivity? = null
    }
}
