package com.ride.accept.autorideacceptor.core

import android.view.accessibility.AccessibilityNodeInfo

/**
 * Base interface for all service order parsers
 */
interface OrderParser {
    
    /**
     * Service package name to monitor
     */
    val packageName: String
    
    /**
     * Detect and accept orders based on user settings
     */
    fun detectAndAcceptOrder(
        rootNode: AccessibilityNodeInfo,
        config: ServiceConfig,
        clickHandler: (AccessibilityNodeInfo) -> Boolean
    )
}

/**
 * Common order data structure
 */
data class OrderData(
    val node: AccessibilityNodeInfo,
    val fare: Double,
    val distance: Double,
    val pickup: String,
    val drop: String,
    val orderId: String? = null
)

/**
 * User configuration for each service
 */
data class ServiceConfig(
    val isEnabled: Boolean,
    val autoAccept: Boolean,
    val minFare: Double,
    val maxFare: Double,
    val pickupDistance: Double,
    val tripDistance: Double,
    val paymentMethod: String = "any",
    val vehicleTypes: List<String> = emptyList()
)
