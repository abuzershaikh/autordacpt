package com.ride.accept.autorideacceptor

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.text.TextUtils
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val CHANNEL_ACCESSIBILITY = "com.ride.accept.autorideacceptor/accessibility"
    private val CHANNEL_SETTINGS = "com.ride.accept.autorideacceptor/settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Accessibility channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_ACCESSIBILITY).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityEnabled" -> {
                    result.success(isAccessibilityEnabled())
                }
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings()
                    result.success(null)
                }
                "isServiceRunning" -> {
                    result.success(AutoAcceptAccessibilityService.isServiceRunning)
                }
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (url != null && url.isNotEmpty()) {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            e.printStackTrace()
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "getAppVersion" -> {
                    try {
                        val pInfo = packageManager.getPackageInfo(packageName, 0)
                        val vName = pInfo.versionName ?: "1.0.0"
                        val vCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            pInfo.longVersionCode.toInt()
                        } else {
                            @Suppress("DEPRECATION")
                            pInfo.versionCode
                        }
                        result.success(mapOf("versionName" to vName, "versionCode" to vCode))
                    } catch (e: Exception) {
                        result.success(mapOf("versionName" to "1.0.0", "versionCode" to 1))
                    }
                }
                "isBatteryOptimizationIgnored" -> {
                    try {
                        val pm = getSystemService(Context.POWER_SERVICE) as? android.os.PowerManager
                        val isIgnored = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            pm?.isIgnoringBatteryOptimizations(packageName) ?: true
                        } else {
                            true
                        }
                        result.success(isIgnored)
                    } catch (e: Exception) {
                        result.success(true)
                    }
                }
                "requestIgnoreBatteryOptimizations" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                            intent.data = Uri.parse("package:$packageName")
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        // Fallback to general battery settings
                        try {
                            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.success(false)
                        }
                    }
                }
                "setVersionBlocked" -> {
                    val isBlocked = call.argument<Boolean>("isBlocked") ?: false
                    val prefs = getSharedPreferences("AutoAcceptSettings", Context.MODE_PRIVATE)
                    prefs.edit().putBoolean("version_blocked", isBlocked).apply()
                    AutoAcceptAccessibilityService.instance?.reloadSettings()
                    result.success(true)
                }
                "testRealClick" -> {
                    val x = (call.argument<Double>("x") ?: 500.0).toFloat()
                    val y = (call.argument<Double>("y") ?: 1000.0).toFloat()
                    val service = AutoAcceptAccessibilityService.instance
                    if (service != null && AutoAcceptAccessibilityService.isServiceRunning) {
                        val tapped = service.performCoordinatesTap(x, y)
                        result.success(tapped)
                    } else {
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Settings channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_SETTINGS).setMethodCallHandler { call, result ->
            when (call.method) {
                "syncUniversalSettings" -> {
                    val jsonSettings = call.argument<String>("settings")
                    if (jsonSettings != null) {
                        saveUniversalSettings(jsonSettings)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "syncSettings" -> {
                    val jsonSettings = call.argument<String>("settings")
                    if (jsonSettings != null) {
                        saveSettingsToSharedPreferences(jsonSettings)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "updateService" -> {
                    val serviceType = call.argument<String>("serviceType")
                    val jsonSettings = call.argument<String>("settings")
                    if (serviceType != null && jsonSettings != null) {
                        updateServiceSettings(serviceType, jsonSettings)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "syncFreeRidesStatus" -> {
                    val hasActivePlan = call.argument<Boolean>("hasActivePlan") ?: false
                    val freeRidesLimit = call.argument<Int>("freeRidesLimit") ?: 2
                    val freeRidesUsed = call.argument<Int>("freeRidesUsed") ?: 0
                    saveFreeRidesStatus(hasActivePlan, freeRidesLimit, freeRidesUsed)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun saveFreeRidesStatus(hasActivePlan: Boolean, limit: Int, used: Int) {
        val prefs = getSharedPreferences("AutoAcceptSettings", Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean("has_active_plan", hasActivePlan)
            .putInt("free_rides_limit", limit)
            .putInt("free_rides_used", used)
            .apply()
        AutoAcceptAccessibilityService.instance?.reloadSettings()
    }

    private fun saveUniversalSettings(jsonSettings: String) {
        val prefs = getSharedPreferences("AutoAcceptSettings", Context.MODE_PRIVATE)
        prefs.edit().putString("universal_settings", jsonSettings).apply()
        AutoAcceptAccessibilityService.instance?.reloadSettings()
    }

    private fun saveSettingsToSharedPreferences(jsonSettings: String) {
        val prefs = getSharedPreferences("AutoAcceptSettings", Context.MODE_PRIVATE)
        prefs.edit().putString("all_settings", jsonSettings).apply()
        AutoAcceptAccessibilityService.instance?.reloadSettings()
    }

    private fun updateServiceSettings(serviceType: String, jsonSettings: String) {
        val prefs = getSharedPreferences("AutoAcceptSettings", Context.MODE_PRIVATE)
        prefs.edit().putString("service_$serviceType", jsonSettings).apply()
        AutoAcceptAccessibilityService.instance?.reloadSettings()
    }

    private fun isAccessibilityEnabled(): Boolean {
        // Fast path: if the service instance is active and running in memory, it is definitely enabled
        if (AutoAcceptAccessibilityService.isServiceRunning && AutoAcceptAccessibilityService.instance != null) {
            return true
        }
        
        // Check 2: Official AccessibilityManager
        try {
            val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as? android.view.accessibility.AccessibilityManager
            val runningServices = am?.getEnabledAccessibilityServiceList(android.accessibilityservice.AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
            if (runningServices != null) {
                for (service in runningServices) {
                    val id = service.id ?: ""
                    if (id.contains("AutoAcceptAccessibilityService", ignoreCase = true) ||
                        id.contains(packageName, ignoreCase = true)) {
                        return true
                    }
                }
            }
        } catch (_: Exception) {}

        val canonicalService = "${packageName}/${AutoAcceptAccessibilityService::class.java.canonicalName}"
        val simpleService = "${packageName}/.${AutoAcceptAccessibilityService::class.java.simpleName}"
        val shortService = "${packageName}/${AutoAcceptAccessibilityService::class.java.name}"
        
        return try {
            val enabledServices = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            ) ?: return false
            
            val colonSplitter = TextUtils.SimpleStringSplitter(':')
            colonSplitter.setString(enabledServices)
            
            while (colonSplitter.hasNext()) {
                val componentName = colonSplitter.next()
                if (componentName.equals(canonicalService, ignoreCase = true) ||
                    componentName.equals(simpleService, ignoreCase = true) ||
                    componentName.equals(shortService, ignoreCase = true) ||
                    componentName.contains("AutoAcceptAccessibilityService", ignoreCase = true)) {
                    return true
                }
            }
            false
        } catch (e: Exception) {
            false
        }
    }

    private fun openAccessibilitySettings() {
        try {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
