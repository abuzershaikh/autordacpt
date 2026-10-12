package com.ride.accept.autorideacceptor

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.accessibilityservice.GestureDescription
import android.content.Context
import android.graphics.Path
import android.graphics.Rect
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Toast
import com.ride.accept.autorideacceptor.core.NodeUtils
import com.ride.accept.autorideacceptor.core.OrderParser
import com.ride.accept.autorideacceptor.core.ServiceConfig
import com.ride.accept.autorideacceptor.services.ola.OlaOrderParser
import com.ride.accept.autorideacceptor.services.porter.PorterOrderParser
import com.ride.accept.autorideacceptor.services.rapido.RapidoOrderParser
import com.ride.accept.autorideacceptor.services.uber.UberOrderParser
import org.json.JSONObject

class AutoAcceptAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "AutoAcceptService"
        var isServiceRunning = false
        var instance: AutoAcceptAccessibilityService? = null
    }

    // Service parsers registry
    private val serviceParsers = mutableMapOf<String, OrderParser>()
    private val serviceConfigs = mutableMapOf<String, ServiceConfig>()
    private var lastClickTimeMs: Long = 0L
    
    // Universal configuration applied across all apps
    private var universalConfig = ServiceConfig(
        isEnabled = true,
        autoAccept = true,
        minFare = 40.0,
        maxFare = 25000.0,
        pickupDistance = 5.0,
        tripDistance = 3000.0
    )

    // Plan & Free Rides state (Default: 10 free trial rides per user, then paid plan required)
    private var hasActivePlan: Boolean = false
    private var freeRidesLimit: Int = 10
    private var freeRidesUsed: Int = 0
    private var lastTrialToastTime: Long = 0L

    // 24/7 Background execution & Version block control
    private var wakeLock: android.os.PowerManager.WakeLock? = null
    private var isVersionBlocked: Boolean = false

    override fun onServiceConnected() {
        super.onServiceConnected()
        isServiceRunning = true
        instance = this
        
        initializeParsers()
        loadSettings()

        // Initialize WakeLock for background responsiveness
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as? android.os.PowerManager
            wakeLock = pm?.newWakeLock(android.os.PowerManager.PARTIAL_WAKE_LOCK, "AutoRideAccept::BackgroundWakeLock")
        } catch (_: Exception) {}

        // Launch ongoing background notification
        startForegroundServiceNotification()
        
        Log.i(TAG, "✓ Accessibility Service Connected successfully & running in background")
        
        // Zero-latency configuration for ultra-fast (<= 5ms) event delivery
        val info = serviceInfo ?: AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.flags = info.flags or
                AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS or
                AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
        info.notificationTimeout = 0 // 0ms delay: Instant event dispatch!
        serviceInfo = info
    }

    private fun startForegroundServiceNotification() {
        try {
            val channelId = "autoride_background_engine"
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? android.app.NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && notificationManager != null) {
                val channel = android.app.NotificationChannel(
                    channelId,
                    "🛺 SnapRider Background Engine",
                    android.app.NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Keeps 🛺 SnapRider active in background for Rapido, Porter, Ola & Uber"
                    setShowBadge(false)
                }
                notificationManager.createNotificationChannel(channel)
            }

            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                android.app.Notification.Builder(this, channelId)
            } else {
                @Suppress("DEPRECATION")
                android.app.Notification.Builder(this)
            }

            val appIntent = packageManager.getLaunchIntentForPackage(packageName)
            val pendingIntent = if (appIntent != null) {
                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    android.app.PendingIntent.FLAG_IMMUTABLE or android.app.PendingIntent.FLAG_UPDATE_CURRENT
                } else {
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT
                }
                android.app.PendingIntent.getActivity(this, 0, appIntent, flags)
            } else null

            builder.setContentTitle("🛺 SnapRider Active")
                .setContentText("Monitoring Rapido, Porter, Ola & Uber orders in background.")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setOngoing(true)
            if (pendingIntent != null) {
                builder.setContentIntent(pendingIntent)
            }

            notificationManager?.notify(1001, builder.build())
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start background notification: ${e.message}")
        }
    }

    /**
     * Initialize all service parsers (Porter, Rapido, Ola, Uber)
     */
    private fun initializeParsers() {
        val porterParser = PorterOrderParser()
        val rapidoParser = RapidoOrderParser()
        val olaParser = OlaOrderParser()
        val uberParser = UberOrderParser()

        serviceParsers["porter"] = porterParser
        serviceParsers["rapido"] = rapidoParser
        serviceParsers["ola"] = olaParser
        serviceParsers["uber"] = uberParser
        
        // Support all package name aliases
        serviceParsers["in.porter.rider"] = porterParser
        serviceParsers["in.porter.driver"] = porterParser
        serviceParsers["in.theporter.partner"] = porterParser
        serviceParsers["in.porter.partner"] = porterParser
        serviceParsers["in.porter.allocator"] = porterParser
        serviceParsers["com.theporter.android.driverapp"] = porterParser
        
        serviceParsers["com.rapido.rider"] = rapidoParser
        serviceParsers["com.rapido.captain"] = rapidoParser
        serviceParsers["com.rapido.passenger"] = rapidoParser
        serviceParsers["com.rapido.partner"] = rapidoParser

        serviceParsers["com.olacabs.oladriver"] = olaParser
        serviceParsers["com.olacabs.partner"] = olaParser
        serviceParsers["com.olacabs.customer"] = olaParser

        serviceParsers["com.ubercab.driver"] = uberParser
        serviceParsers["com.ubercab.partner"] = uberParser
        
        Log.i(TAG, "Registered service parsers for Porter, Rapido, Ola & Uber with universal package aliases")
    }

    /**
     * Reload settings from SharedPreferences
     */
    fun reloadSettings() {
        loadSettings()
        Log.i(TAG, "Settings reloaded from SharedPreferences")
    }

    /**
     * Load user settings from SharedPreferences
     */
    private fun loadSettings() {
        try {
            val prefs = getSharedPreferences("AutoAcceptSettings", Context.MODE_PRIVATE)
            
            // 0. Version Blocked status
            isVersionBlocked = prefs.getBoolean("version_blocked", false)

            // Plan and Free Rides state (default 10 free rides)
            hasActivePlan = prefs.getBoolean("has_active_plan", false)
            freeRidesLimit = prefs.getInt("free_rides_limit", 10)
            freeRidesUsed = prefs.getInt("free_rides_used", 0)

            // 1. Universal settings (Applies across all apps)
            val universalJson = prefs.getString("universal_settings", null)
            if (universalJson != null) {
                val json = JSONObject(universalJson)
                val rideFilters = json.optJSONObject("rideFilters") ?: json
                universalConfig = ServiceConfig(
                    isEnabled = json.optBoolean("isEnabled", true),
                    autoAccept = json.optBoolean("autoAccept", true),
                    minFare = rideFilters.optDouble("minFare", 40.0),
                    maxFare = rideFilters.optDouble("maxFare", 25000.0),
                    pickupDistance = rideFilters.optDouble("pickupDistance", 5.0),
                    tripDistance = rideFilters.optDouble("tripDistance", 3000.0)
                )
                if (json.has("hasActivePlan")) {
                    hasActivePlan = json.optBoolean("hasActivePlan", hasActivePlan)
                }
                if (json.has("freeRidesLimit")) {
                    freeRidesLimit = json.optInt("freeRidesLimit", freeRidesLimit)
                }
                if (json.has("freeRidesUsed")) {
                    freeRidesUsed = json.optInt("freeRidesUsed", freeRidesUsed)
                }
                Log.i(TAG, "✓ Universal settings loaded: autoAccept=${universalConfig.autoAccept}, minFare=₹${universalConfig.minFare}, maxFare=₹${universalConfig.maxFare}")
            }
            Log.i(TAG, "✓ Plan & Free Rides loaded: hasActivePlan=$hasActivePlan, used=$freeRidesUsed, limit=$freeRidesLimit")

            // 2. Batch settings JSON
            val allSettingsJson = prefs.getString("all_settings", null)
            if (allSettingsJson != null) {
                val json = JSONObject(allSettingsJson)
                if (json.has("porter")) {
                    applyServiceConfig("porter", json.getJSONObject("porter"))
                }
                if (json.has("rapido")) {
                    applyServiceConfig("rapido", json.getJSONObject("rapido"))
                }
                if (json.has("ola")) {
                    applyServiceConfig("ola", json.getJSONObject("ola"))
                }
                // Flutter alias mappings
                if (json.has("service1")) {
                    applyServiceConfig("rapido", json.getJSONObject("service1"))
                }
                if (json.has("service2")) {
                    applyServiceConfig("porter", json.getJSONObject("service2"))
                }
            }
            
            // 3. Individual service keys
            loadServiceConfigFromKey("porter", prefs)
            loadServiceConfigFromKey("rapido", prefs)
            loadServiceConfigFromKey("ola", prefs)
            loadServiceConfigFromKey("service1", prefs, targetKey = "rapido")
            loadServiceConfigFromKey("service2", prefs, targetKey = "porter")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error loading settings", e)
        }
    }

    private fun loadServiceConfigFromKey(serviceKey: String, prefs: android.content.SharedPreferences, targetKey: String = serviceKey) {
        val jsonString = prefs.getString("service_$serviceKey", null) ?: return
        try {
            val json = JSONObject(jsonString)
            applyServiceConfig(targetKey, json)
        } catch (e: Exception) {
            Log.e(TAG, "Error loading $serviceKey config from key", e)
        }
    }

    private fun applyServiceConfig(serviceKey: String, json: JSONObject) {
        try {
            val rideFilters = json.optJSONObject("rideFilters") ?: JSONObject()
            val config = ServiceConfig(
                isEnabled = json.optBoolean("isEnabled", true),
                autoAccept = json.optBoolean("autoAccept", true),
                minFare = rideFilters.optDouble("minFare", 50.0),
                maxFare = rideFilters.optDouble("maxFare", 25000.0),
                pickupDistance = rideFilters.optDouble("pickupDistance", 5.0),
                tripDistance = rideFilters.optDouble("tripDistance", 3000.0)
            )
            
            serviceConfigs[serviceKey] = config
            Log.i(TAG, "✓ Applied $serviceKey settings: autoAccept=${config.autoAccept}, minFare=₹${config.minFare}, maxFare=₹${config.maxFare}")
        } catch (e: Exception) {
            Log.e(TAG, "Error applying $serviceKey config", e)
        }
    }

    private fun getParserForPackage(packageName: String): OrderParser? {
        val lower = packageName.lowercase()
        return when {
            lower.contains("porter") -> serviceParsers["porter"]
            lower.contains("rapido") -> serviceParsers["rapido"]
            lower.contains("ola") -> serviceParsers["ola"]
            lower.contains("uber") -> serviceParsers["uber"]
            lower.contains("autorideacceptor") -> serviceParsers["porter"] // Support test simulation
            else -> serviceParsers[packageName]
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        // If version has been blocked by admin in VPS, disable all auto-accept
        if (isVersionBlocked) {
            Log.w(TAG, "Auto-accept paused: App version is blocked by VPS Control Engine. Update required.")
            return
        }

        // Keep CPU awake momentarily during background event inspection
        try {
            wakeLock?.acquire(2000)
        } catch (_: Exception) {}
        
        val eventPackage = event.packageName?.toString() ?: ""
        
        // 1. Collect all candidate root nodes
        // (Active window + Floating Overlays / PIP Bubbles / System Alerts over homescreen/Maps)
        val candidateRoots = mutableListOf<AccessibilityNodeInfo>()
        
        rootInActiveWindow?.let { candidateRoots.add(it) }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            try {
                for (window in windows) {
                    val root = window.root
                    if (root != null) {
                        candidateRoots.add(root)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error retrieving windows for overlay detection", e)
            }
        }
        
        for (rootNode in candidateRoots) {
            try {
                val nodePackage = rootNode.packageName?.toString() ?: eventPackage
                val parser = getParserForPackage(nodePackage) ?: getParserFromContent(rootNode)
                
                if (parser != null) {
                    val serviceKey = when {
                        nodePackage.contains("porter", ignoreCase = true) -> "porter"
                        nodePackage.contains("rapido", ignoreCase = true) -> "rapido"
                        nodePackage.contains("ola", ignoreCase = true) -> "ola"
                        nodePackage.contains("uber", ignoreCase = true) -> "uber"
                        else -> "ola"
                    }
                    
                    val config = if (universalConfig.isEnabled && universalConfig.autoAccept) {
                        val specific = serviceConfigs[serviceKey]
                        if (specific != null) {
                            specific.copy(isEnabled = true, autoAccept = true)
                        } else {
                            universalConfig
                        }
                    } else {
                        serviceConfigs[serviceKey] ?: universalConfig
                    }
                    
                    if (config.isEnabled && config.autoAccept) {
                        // Check free rides trial vs paid plan
                        val prefs = getSharedPreferences("AutoAcceptSettings", Context.MODE_PRIVATE)
                        val isPlanActive = prefs.getBoolean("has_active_plan", hasActivePlan)
                        val limit = prefs.getInt("free_rides_limit", freeRidesLimit)
                        val used = prefs.getInt("free_rides_used", freeRidesUsed)

                        if (!isPlanActive && used >= limit) {
                            val trialReason = "Trial Expired ($used/$limit free rides consumed)"
                            Log.w(TAG, "⛔ [FREE TRIAL EXPIRED] $trialReason. Auto-accept blocked. User must purchase plan.")
                            showTrialExpiredToast(used, limit)
                            dispatchRideTelemetryToVps(serviceKey, "missed", reason = trialReason)
                            continue
                        }

                        parser.detectAndAcceptOrder(rootNode, config) { targetNode ->
                            val clicked = performRealHardwareClick(targetNode, parser.packageName)
                            if (clicked) {
                                dispatchRideTelemetryToVps(serviceKey, "accepted")
                                if (!isPlanActive) {
                                    val updatedUsed = used + 1
                                    prefs.edit().putInt("free_rides_used", updatedUsed).apply()
                                    freeRidesUsed = updatedUsed
                                    try {
                                        val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                                        flutterPrefs.edit().putInt("flutter.free_rides_used_count", updatedUsed).apply()
                                    } catch (_: Exception) {}
                                    Log.i(TAG, "🎁 [FREE RIDE CONSUMED] Count now: $updatedUsed/$limit")
                                    if (updatedUsed >= limit) {
                                        showTrialExpiredToast(updatedUsed, limit)
                                    }
                                }
                            } else {
                                dispatchRideTelemetryToVps(serviceKey, "missed", reason = "Click not registered or button not clickable")
                            }
                            clicked
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error evaluating candidate root", e)
            }
        }
    }

    /**
     * Inspect root content for Porter, Rapido, Ola, Uber markers when drawn inside
     * floating overlay windows or system alert popups over the homescreen
     */
    private fun getParserFromContent(rootNode: AccessibilityNodeInfo): OrderParser? {
        try {
            // Check Rapido floating overlay markers
            if (NodeUtils.findNodesByResourceId(rootNode, "oa_single_order_card_").isNotEmpty() ||
                NodeUtils.findNodesByResourceId(rootNode, "acceptCTA").isNotEmpty() ||
                NodeUtils.findNodesByResourceId(rootNode, "accept_cta").isNotEmpty()
            ) {
                return serviceParsers["rapido"]
            }
            
            // Check Porter floating overlay markers
            if (NodeUtils.findNodesByResourceId(rootNode, "acceptOrderCard").isNotEmpty() ||
                NodeUtils.findNodesByResourceId(rootNode, "tray_order_item").isNotEmpty()
            ) {
                return serviceParsers["porter"]
            }

            // Check Ola floating overlay markers
            if (NodeUtils.findNodesByResourceId(rootNode, "btn_accept").isNotEmpty() ||
                NodeUtils.findNodesByResourceId(rootNode, "btn_accept_lyt").isNotEmpty() ||
                NodeUtils.findNodesByResourceId(rootNode, "booking_detail_accept").isNotEmpty() ||
                NodeUtils.findNodesByResourceId(rootNode, "motivator_overlay_card_container").isNotEmpty()
            ) {
                return serviceParsers["ola"]
            }

            // Check Uber floating overlay markers
            if (NodeUtils.findNodesByResourceId(rootNode, "ub__driver_offer_accept_button").isNotEmpty() ||
                NodeUtils.findNodesByResourceId(rootNode, "ub__trip_card_accept_button").isNotEmpty() ||
                NodeUtils.findNodesByText(rootNode, "Trip Radar").isNotEmpty()
            ) {
                return serviceParsers["uber"]
            }
        } catch (_: Exception) {}
        return null
    }

    /**
     * Send asynchronous ride telemetry (Porter, Rapido, Ola, Uber) to the VPS Control Engine
     */
    /**
     * Send asynchronous ride telemetry (Porter, Rapido, Ola, Uber) to the VPS Control Engine
     */
    fun dispatchRideTelemetryToVps(
        platform: String,
        status: String,
        fare: Double = 0.0,
        distanceKm: Double = 0.0,
        pickupDistance: Double = 0.0,
        responseTimeMs: Int = 0,
        orderId: String? = null,
        reason: String? = null,
        userMinFare: Double = universalConfig.minFare,
        userMaxFare: Double = universalConfig.maxFare,
        userMaxPickup: Double = universalConfig.pickupDistance,
        userMaxTrip: Double = universalConfig.tripDistance
    ) {
        Thread {
            try {
                val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val vpsUrl = flutterPrefs.getString("flutter.vps_base_url", "http://139.84.158.149:5000") ?: "http://139.84.158.149:5000"
                val uid = flutterPrefs.getString("flutter.firebase_uid", "rider_device") ?: "rider_device"
                
                val cleanUrl = vpsUrl.trim().trimEnd('/')
                val url = java.net.URL("$cleanUrl/api/rides/event")
                val conn = url.openConnection() as java.net.HttpURLConnection
                conn.requestMethod = "POST"
                conn.setRequestProperty("Content-Type", "application/json")
                conn.doOutput = true
                conn.connectTimeout = 3000
                conn.readTimeout = 3000
                
                val json = JSONObject().apply {
                    put("uid", uid)
                    put("platform", platform.lowercase())
                    put("status", status)
                    put("fare", fare)
                    put("pickupDistance", pickupDistance)
                    put("tripDistance", distanceKm)
                    put("responseTimeMs", responseTimeMs)
                    put("orderId", orderId ?: "")
                    put("reason", reason ?: "")
                    put("userMinFare", userMinFare)
                    put("userMaxFare", userMaxFare)
                    put("userMaxPickup", userMaxPickup)
                    put("userMaxTrip", userMaxTrip)
                    put("deviceBrand", Build.BRAND)
                    put("deviceModel", Build.MODEL)
                }
                
                val os = conn.outputStream
                os.write(json.toString().toByteArray())
                os.flush()
                os.close()
                
                val code = conn.responseCode
                Log.d(TAG, "📡 Ride telemetry sent to VPS: $platform $status (HTTP $code)")
                conn.disconnect()
            } catch (e: Exception) {
                // Silently skip if VPS offline
            }
        }.start()
    }

    /**
     * ASLI REAL HARDWARE TOUCH CLICK:
     * Dispatches real physical touch input (MotionEvent ACTION_DOWN -> ACTION_UP)
     * at the exact screen coordinates of the button/card via Android's dispatchGesture API.
     * Also supports "Swipe to Accept" / "Slide to Accept" sliders.
     * Executed with 0ms start latency for sub-frame (<= 5ms) auto-click speed!
     */
    fun performRealHardwareClick(nodeInfo: AccessibilityNodeInfo, sourcePackage: String? = null): Boolean {
        // 0. Trial Expiration Check: Must have active plan or remaining free rides
        val prefs = getSharedPreferences("AutoAcceptSettings", Context.MODE_PRIVATE)
        val isPlanActive = prefs.getBoolean("has_active_plan", hasActivePlan)
        val limit = prefs.getInt("free_rides_limit", freeRidesLimit)
        val used = prefs.getInt("free_rides_used", freeRidesUsed)
        if (!isPlanActive && used >= limit) {
            Log.w(TAG, "⛔ [FREE TRIAL EXPIRED] Real click blocked! $used/$limit free rides used. User must purchase plan.")
            showTrialExpiredToast(used, limit)
            return false
        }

        // 1. Strict Visibility Check: Node MUST be visible to the user
        if (!NodeUtils.isNodeVisible(nodeInfo)) {
            Log.w(TAG, "⛔ REJECTED: Target node is INVISIBLE to user (isVisibleToUser=false)!")
            return false
        }
        
        val displayMetrics = resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels
        val screenHeight = displayMetrics.heightPixels
        
        // 2. Find valid visible screen bounds of the button
        var clickableTarget = nodeInfo
        if (!clickableTarget.isClickable) {
            var curr = nodeInfo.parent
            var depth = 0
            while (curr != null && depth < 4) {
                if (curr.isClickable && NodeUtils.isNodeVisible(curr)) {
                    clickableTarget = curr
                    Log.i(TAG, "🎯 Resolved clickable parent button: bounds=${Rect().apply { curr.getBoundsInScreen(this) }}")
                    break
                }
                curr = curr.parent
                depth++
            }
        }

        val screenBounds = Rect()
        clickableTarget.getBoundsInScreen(screenBounds)
        
        // If node has 0 size, check immediate parent only if parent is a reasonable button size
        if (screenBounds.width() <= 0 || screenBounds.height() <= 0) {
            val parent = nodeInfo.parent
            if (parent != null && NodeUtils.isNodeVisible(parent)) {
                parent.getBoundsInScreen(screenBounds)
            }
        }
        
        // REJECT if bounds are zero, tiny, or full-screen frame
        if (screenBounds.width() < 30 || screenBounds.height() < 30) {
            Log.w(TAG, "⛔ REJECTED: Target node has invalid tiny bounds (${screenBounds.width()}x${screenBounds.height()})!")
            return false
        }
        
        // If the bounds cover the entire screen (e.g. root FrameLayout), REJECT! It is not a button!
        if (screenBounds.width() >= screenWidth && screenBounds.height() >= (screenHeight * 0.7)) {
            Log.w(TAG, "⛔ REJECTED: Bounds cover full screen (${screenBounds.width()}x${screenBounds.height()}). Not a button!")
            return false
        }
        
        // Verify within visible screen area
        if (screenBounds.right <= 0 || screenBounds.bottom <= 0 || 
            screenBounds.left >= screenWidth || screenBounds.top >= screenHeight) {
            Log.w(TAG, "⛔ REJECTED: Target node is completely off-screen! Bounds: $screenBounds")
            return false
        }
        
        val now = System.currentTimeMillis()
        if (now - lastClickTimeMs < 1000L) {
            Log.d(TAG, "⏳ Click throttled (debounce: ${now - lastClickTimeMs}ms since last click)")
            return false
        }
        lastClickTimeMs = now

        Log.i(TAG, "⚡ Initiating ASLI REAL CLICK on verified visible target at bounds: $screenBounds...")
        
        val targetPkg = (sourcePackage ?: nodeInfo.packageName?.toString() ?: "").lowercase()
        val isOla = targetPkg.contains("ola")
        var gestureDispatched = false
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val centerX = screenBounds.centerX().toFloat()
            val centerY = screenBounds.centerY().toFloat()
            
            // Check if this is a slider ("Slide to accept", "Swipe to accept", "स्वाइप")
            val nodeText = (nodeInfo.text?.toString() ?: "") + " " + 
                           (nodeInfo.contentDescription?.toString() ?: "") + " " +
                           (clickableTarget.text?.toString() ?: "") + " " +
                           (clickableTarget.contentDescription?.toString() ?: "")
            val isSlider = nodeText.contains("slide", ignoreCase = true) || 
                           nodeText.contains("swipe", ignoreCase = true) ||
                           nodeText.contains("स्वाइप", ignoreCase = true) ||
                           nodeText.contains("स्लाइड", ignoreCase = true)
            
            val path = Path()
            val duration: Long
            
            if (isSlider) {
                // Real swipe gesture across the slider (left to right)
                val startX = screenBounds.left + (screenBounds.width() * 0.15f)
                val endX = screenBounds.right - (screenBounds.width() * 0.10f)
                path.moveTo(startX, centerY)
                path.lineTo(endX, centerY)
                duration = (270L..330L).random() // Natural 270-330ms smooth physical swipe
                Log.i(TAG, "👉 Dispatched REAL SWIPE gesture from ($startX, $centerY) to ($endX, $centerY) with duration ${duration}ms")
            } else {
                // Real physical human-like tap gesture:
                // 1. Natural micro-jitter in coordinates (±3 to 4 pixels within button bounds)
                val jitterX = (-4..4).random().toFloat()
                val jitterY = (-3..3).random().toFloat()
                val tapX = (centerX + jitterX).coerceIn(screenBounds.left + 5f, screenBounds.right - 5f)
                val tapY = (centerY + jitterY).coerceIn(screenBounds.top + 5f, screenBounds.bottom - 5f)
                
                path.moveTo(tapX, tapY)
                path.lineTo(tapX, tapY + 1f) // CRITICAL: 1px micro-motion finishes gesture in 50ms (avoids Samsung 5-sec hold!)
                // 2. Randomized human touch hold time between 52ms and 78ms (never a fixed robotic value)
                duration = (52L..78L).random()
                Log.i(TAG, "👆 Dispatched HUMAN REAL TAP at ($tapX, $tapY) with natural random duration: ${duration}ms")
            }
            
            val stroke = GestureDescription.StrokeDescription(path, 0L, duration)
            val gesture = GestureDescription.Builder().addStroke(stroke).build()
            
            gestureDispatched = dispatchGesture(gesture, object : GestureResultCallback() {
                override fun onCompleted(gestureDescription: GestureDescription?) {
                    super.onCompleted(gestureDescription)
                    Log.i(TAG, "✅ [SUCCESS] Real hardware touch event completed on screen at ($centerX, $centerY)!")
                }
                override fun onCancelled(gestureDescription: GestureDescription?) {
                    super.onCancelled(gestureDescription)
                    Log.w(TAG, "⚠️ Real hardware gesture cancelled, trying fallback")
                }
            }, null)
            
            // Trigger haptic vibration confirmation so driver feels the click
            triggerHapticFeedback()
        }
        
        // 2. Dual Backup: Direct accessibility ACTION_CLICK
        // STRICT OLA ANTI-FRAUD RULE: NEVER execute fallback ACTION_CLICK on Ola!
        // Ola's SecureAcceptButton actively checks isTouchEventInProgress == false in performClick()
        // and sends FraudClickPackageLog to Ola's backend security server when ACTION_CLICK is fired.
        var a11yClicked = false
        if (isOla) {
            Log.i(TAG, "🛡️ [OLA ANTI-FRAUD SHIELD] Fallback ACTION_CLICK strictly DISABLED for Ola! Relying 100% on real physical touch gesture.")
        } else {
            // For non-Ola apps (Rapido, Porter), execute direct ACTION_CLICK as instant dual backup!
            try {
                if (nodeInfo.isClickable) {
                    a11yClicked = nodeInfo.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                }
                if (!a11yClicked) {
                    var parent = nodeInfo.parent
                    var depth = 0
                    while (parent != null && depth < 4) {
                        if (parent.isClickable) {
                            a11yClicked = parent.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                            if (a11yClicked) break
                        }
                        parent = parent.parent
                        depth++
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Accessibility action fallback error", e)
            }
        }
        
        Log.i(TAG, "Click dispatched: realTouchGesture=$gestureDispatched, a11yClicked=$a11yClicked, isOla=$isOla")
        return gestureDispatched || a11yClicked
    }

    /**
     * Dispatch an arbitrary real hardware tap on screen coordinates (x, y)
     * Used for testing, calibration, and simulated auto-accept.
     */
    fun performCoordinatesTap(x: Float, y: Float, durationMs: Long = 50L): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return false
        val path = Path().apply {
            moveTo(x, y)
            lineTo(x, y)
        }
        val stroke = GestureDescription.StrokeDescription(path, 0L, durationMs)
        val gesture = GestureDescription.Builder().addStroke(stroke).build()
        val dispatched = dispatchGesture(gesture, object : GestureResultCallback() {
            override fun onCompleted(gestureDescription: GestureDescription?) {
                super.onCompleted(gestureDescription)
                Log.i(TAG, "✓ Real tap gesture completed at screen coords ($x, $y)")
            }
            override fun onCancelled(gestureDescription: GestureDescription?) {
                super.onCancelled(gestureDescription)
                Log.w(TAG, "⚠ Real tap gesture cancelled at screen coords ($x, $y)")
            }
        }, null)
        
        triggerHapticFeedback()
        return dispatched
    }

    /**
     * Physical haptic feedback on successful click
     */
    private fun triggerHapticFeedback() {
        try {
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vibratorManager?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createOneShot(80, VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(80)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Haptic feedback error", e)
        }
    }

    /**
     * Show non-intrusive on-screen notification when 2 free rides are consumed
     */
    private fun showTrialExpiredToast(used: Int = freeRidesUsed, limit: Int = freeRidesLimit) {
        val now = System.currentTimeMillis()
        if (now - lastTrialToastTime > 12000L) { // Throttle every 12 seconds
            lastTrialToastTime = now
            Handler(Looper.getMainLooper()).post {
                Toast.makeText(
                    applicationContext,
                    "⚠️ Free Trial Completed ($used/$limit used)! Buy 1-Day Plan (₹15) or Weekly Plan (₹49) to continue.",
                    Toast.LENGTH_LONG
                ).show()
            }
        }
    }

    override fun onInterrupt() {
        Log.w(TAG, "Accessibility service interrupted by system")
    }

    override fun onDestroy() {
        super.onDestroy()
        isServiceRunning = false
        instance = null
        serviceParsers.clear()
        serviceConfigs.clear()
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (_: Exception) {}
        Log.i(TAG, "Accessibility service destroyed and resources cleaned up")
    }
}
