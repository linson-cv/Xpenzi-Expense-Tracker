package com.navlinlabs.xpenzi

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.HapticFeedbackConstants
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val HAPTIC_CHANNEL = "com.navlinlabs.xpenzi/haptics"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HAPTIC_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "vibrate") {
                    val type = call.arguments as? String
                    triggerHardwareHaptic(type)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun triggerHardwareHaptic(type: String?) {
        try {
            val vibrator: Vibrator? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                manager?.defaultVibrator
            } else {
                getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }

            if (vibrator != null && vibrator.hasVibrator()) {
                val (durationMs, amplitude) = when (type) {
                    "HapticFeedbackType.selectionClick" -> Pair(10L, 60)
                    "HapticFeedbackType.lightImpact" -> Pair(15L, 90)
                    "HapticFeedbackType.mediumImpact" -> Pair(22L, 150)
                    "HapticFeedbackType.heavyImpact" -> Pair(35L, 230)
                    else -> Pair(35L, VibrationEffect.DEFAULT_AMPLITUDE)
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val finalAmp = if (vibrator.hasAmplitudeControl()) {
                        amplitude
                    } else {
                        VibrationEffect.DEFAULT_AMPLITUDE
                    }
                    val effect = VibrationEffect.createOneShot(durationMs, finalAmp)
                    val audioAttrs = AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
                        .build()
                    vibrator.vibrate(effect, audioAttrs)
                } else {
                    vibrator.vibrate(durationMs)
                }
            } else {
                window?.decorView?.performHapticFeedback(
                    HapticFeedbackConstants.LONG_PRESS,
                    HapticFeedbackConstants.FLAG_IGNORE_GLOBAL_SETTING
                )
            }
        } catch (_: Throwable) {
        }
    }
}
