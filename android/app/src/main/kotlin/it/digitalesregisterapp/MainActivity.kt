package io.wertwerk.digitalesregister

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The app lock (#114): see lib/services/app_lock_platform.dart.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dr/app_lock")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setRecentsHidden" -> {
                        // True when Android hides the preview itself.
                        val byAndroid =
                            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU
                        if (byAndroid) {
                            setRecentsScreenshotEnabled(call.arguments != true)
                        }
                        result.success(byAndroid)
                    }
                    "moveTaskToBack" -> {
                        moveTaskToBack(true)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        // Battery optimization and the background check (#318): see
        // lib/services/battery_optimization.dart.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dr/battery")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isIgnoring" -> {
                        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(power.isIgnoringBatteryOptimizations(packageName))
                    }
                    "openSettings" -> {
                        openBatterySettings()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // The list of apps that are not optimized; the app's own page when a
    // device has no such list. No permission is needed for either.
    private fun openBatterySettings() {
        val list = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
        val details = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.parse("package:$packageName"),
        )
        try {
            startActivity(list)
        } catch (e: ActivityNotFoundException) {
            startActivity(details)
        }
    }
}
