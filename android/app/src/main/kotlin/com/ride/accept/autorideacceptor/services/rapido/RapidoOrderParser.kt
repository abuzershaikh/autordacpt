package com.ride.accept.autorideacceptor.services.rapido

import android.util.Log
import android.view.accessibility.AccessibilityNodeInfo
import com.ride.accept.autorideacceptor.core.NodeUtils
import com.ride.accept.autorideacceptor.core.OrderParser
import com.ride.accept.autorideacceptor.core.ServiceConfig

/**
 * Rapido-specific order parser
 * Handles order detection and auto-acceptance for Rapido Captain (driver) app
 * Strictly requires real verified fare (fare > 0) and visible button before clicking!
 */
class RapidoOrderParser : OrderParser {
    
    override val packageName: String = "com.rapido.rider"
    
    companion object {
        private const val TAG = "RapidoOrderParser"
        
        // Decompiled and common Rapido resource IDs
        private val FARE_IDS = listOf(
            "tv_fare_amount",
            "fare_text",
            "ride_fare",
            "amount_text",
            "tv_fare",
            "tvAmount",
            "order_earnings",
            "amountToBePaid",
            "estimatedAmount",
            "fare_amount"
        )
        
        private val PICKUP_DISTANCE_IDS = listOf(
            "tv_pickup_distance",
            "pickup_distance",
            "distance_from_pickup",
            "km_away_text",
            "distanceToPickup",
            "dryRun",
            "tv_distance"
        )
        
        private val DROP_DISTANCE_IDS = listOf(
            "tv_drop_distance",
            "drop_distance",
            "trip_distance",
            "pickupDropDistance",
            "pickUpToDropDistance",
            "tv_compact_distance",
            "tv_drop_distance_time",
            "ride_distance",
            "total_distance"
        )
        
        private val ACCEPT_BUTTON_IDS = listOf(
            "acceptCTA",
            "accept_cta",
            "actionTitle",
            "btnConsentAccept",
            "ready_for_next_order_button",
            "btn_accept",
            "accept_ride_button",
            "confirmButton",
            "positiveButton",
            "accept_button",
            "btn_accept_order",
            "cta_button",
            "action_button"
        )
        
        private val ORDER_CARD_IDS = listOf(
            "oa_single_order_card_",
            "order_card_view",
            "orderStatusLayout",
            "order_card_container",
            "ride_request_layout",
            "incoming_order_card",
            "request_card",
            "order_card"
        )
        
        private val PICKUP_ADDRESS_IDS = listOf(
            "tv_pickup_address",
            "pickup_location_text",
            "pickup_address",
            "tvPickUp"
        )
        
        private val DROP_ADDRESS_IDS = listOf(
            "tv_drop_address",
            "drop_location_text",
            "drop_address",
            "tvDropAddress"
        )
    }
    
    override fun detectAndAcceptOrder(
        rootNode: AccessibilityNodeInfo,
        config: ServiceConfig,
        clickHandler: (AccessibilityNodeInfo) -> Boolean
    ) {
        try {
            // Step 1: Detect if screen has order indicators
            if (!isRapidoOrder(rootNode)) {
                return
            }
            
            // Step 2: Extract order data (FARE MUST BE > 0)
            val orderData = extractOrderData(rootNode)
            
            // CRITICAL USER RULE: Only click when real amount is shown (> 0).
            // When fare is 0 or missing, DO NOT CLICK!
            if (orderData == null || orderData.fare <= 0.0) {
                Log.i(TAG, "⚠️ [Rapido Order Seen] But fare is not loaded yet (fare=0). Waiting for valid fare before clicking...")
                return
            }
            
            Log.i(TAG, "✓ [Rapido Order Verified] Fare=₹${orderData.fare}, PickupDist=${orderData.pickupDistance}km, TripDist=${orderData.tripDistance}km")
            
            // Step 3: Check user filters
            val filterRejectReason = getFilterRejectionReason(orderData, config)
            if (filterRejectReason != null) {
                Log.w(TAG, "❌ [Rapido Order Filter Rejection] $filterRejectReason")
                com.ride.accept.autorideacceptor.AutoAcceptAccessibilityService.instance?.dispatchRideTelemetryToVps(
                    "rapido",
                    "rejected",
                    fare = orderData.fare,
                    distanceKm = orderData.tripDistance,
                    pickupDistance = orderData.pickupDistance,
                    reason = filterRejectReason,
                    userMinFare = config.minFare,
                    userMaxFare = config.maxFare,
                    userMaxPickup = config.pickupDistance,
                    userMaxTrip = config.tripDistance
                )
                return
            }
            
            // Step 4: Find visible, genuine accept button
            val acceptButton = findAcceptButton(rootNode)
            if (acceptButton != null && NodeUtils.isNodeVisible(acceptButton)) {
                val accepted = clickHandler(acceptButton)
                if (accepted) {
                    Log.i(TAG, "🎯 [Rapido ACCEPT Triggered] Button click sent! Fare=₹${orderData.fare}")
                    com.ride.accept.autorideacceptor.AutoAcceptAccessibilityService.instance?.dispatchRideTelemetryToVps(
                        "rapido",
                        "accepted",
                        fare = orderData.fare,
                        distanceKm = orderData.tripDistance,
                        pickupDistance = orderData.pickupDistance,
                        userMinFare = config.minFare,
                        userMaxFare = config.maxFare,
                        userMaxPickup = config.pickupDistance,
                        userMaxTrip = config.tripDistance
                    )
                    return
                }
            }
            
            // Fallback: Click verified order card if button not separated, but only if card is visible
            val orderCard = findOrderCard(rootNode)
            if (orderCard != null && NodeUtils.isNodeVisible(orderCard)) {
                val accepted = clickHandler(orderCard)
                if (accepted) {
                    Log.i(TAG, "🎯 [Rapido ACCEPT Triggered] Order card click sent! Fare=₹${orderData.fare}")
                    com.ride.accept.autorideacceptor.AutoAcceptAccessibilityService.instance?.dispatchRideTelemetryToVps(
                        "rapido",
                        "accepted",
                        fare = orderData.fare,
                        distanceKm = orderData.tripDistance,
                        pickupDistance = orderData.pickupDistance,
                        userMinFare = config.minFare,
                        userMaxFare = config.maxFare,
                        userMaxPickup = config.pickupDistance,
                        userMaxTrip = config.tripDistance
                    )
                    return
                }
            }
            
            val notFoundReason = "Order card detected but Accept CTA button not visible on screen"
            Log.w(TAG, "⚠️ Rapido order verified (₹${orderData.fare}) but no visible accept button or card found on screen!")
            com.ride.accept.autorideacceptor.AutoAcceptAccessibilityService.instance?.dispatchRideTelemetryToVps(
                "rapido",
                "missed",
                fare = orderData.fare,
                distanceKm = orderData.tripDistance,
                pickupDistance = orderData.pickupDistance,
                reason = notFoundReason,
                userMinFare = config.minFare,
                userMaxFare = config.maxFare,
                userMaxPickup = config.pickupDistance,
                userMaxTrip = config.tripDistance
            )
            
        } catch (e: Exception) {
            Log.e(TAG, "Error in Rapido detectAndAcceptOrder", e)
        }
    }
    
    /**
     * Check if current screen is a Rapido order
     */
    private fun isRapidoOrder(rootNode: AccessibilityNodeInfo): Boolean {
        // Look for order card
        val hasOrderCard = ORDER_CARD_IDS.any { id ->
            NodeUtils.findNodeByResourceId(rootNode, id) != null
        }
        
        // Look for accept button
        val hasAcceptButton = ACCEPT_BUTTON_IDS.any { id ->
            NodeUtils.findNodeByResourceId(rootNode, id) != null
        } || NodeUtils.findAcceptButtons(rootNode).isNotEmpty()
        
        // Look for fare indicator
        val hasFare = FARE_IDS.any { id ->
            NodeUtils.findNodeByResourceId(rootNode, id) != null
        } || NodeUtils.findNodesByText(rootNode, "₹").isNotEmpty()
        
        return (hasOrderCard && hasFare) || (hasAcceptButton && hasFare)
    }
    
    /**
     * Extract order data from accessibility nodes
     * STRICT: returns null if fare is 0.0 or not found
     */
    private fun extractOrderData(rootNode: AccessibilityNodeInfo): OrderData? {
        val fare = extractFare(rootNode) ?: return null
        if (fare <= 0.0) return null
        
        val (pickupDistance, tripDistance) = extractDistances(rootNode)
        val pickupAddress = extractPickupAddress(rootNode)
        val dropAddress = extractDropAddress(rootNode)
        
        return OrderData(
            fare = fare,
            pickupDistance = pickupDistance,
            tripDistance = tripDistance,
            pickupAddress = pickupAddress,
            dropAddress = dropAddress
        )
    }
    
    /**
     * Extract fare amount from order card
     */
    private fun extractFare(rootNode: AccessibilityNodeInfo): Double? {
        for (id in FARE_IDS) {
            val node = NodeUtils.findNodeByResourceId(rootNode, id)
            if (node != null && NodeUtils.isNodeVisible(node)) {
                val text = node.text?.toString() ?: ""
                val fare = NodeUtils.parseFare(text)
                if (fare > 0.0) return fare
            }
        }
        
        // Fallback: Find by ₹ symbol
        val fareNodes = NodeUtils.findNodesByText(rootNode, "₹")
        for (fn in fareNodes) {
            if (NodeUtils.isNodeVisible(fn)) {
                val text = fn.text?.toString() ?: ""
                val fare = NodeUtils.parseFare(text)
                if (fare > 0.0) return fare
            }
        }
        
        return null
    }
    
    private data class RawDistance(
        val distanceKm: Double,
        val text: String,
        val isExplicitPickup: Boolean,
        val isExplicitDrop: Boolean
    )
    
    /**
     * Extract both pickup distance and trip distance
     * Accurately distinguishes driver-to-customer pickup leg from customer destination trip leg!
     */
    private fun extractDistances(rootNode: AccessibilityNodeInfo): Pair<Double, Double> {
        // 1. Try explicit resource IDs
        var explicitPickup = 0.0
        for (id in PICKUP_DISTANCE_IDS) {
            val node = NodeUtils.findNodeByResourceId(rootNode, id)
            if (node != null && NodeUtils.isNodeVisible(node)) {
                val dist = NodeUtils.parseDistance(node.text?.toString() ?: "")
                if (dist > 0.0) {
                    explicitPickup = dist
                    break
                }
            }
        }
        
        var explicitDrop = 0.0
        for (id in DROP_DISTANCE_IDS) {
            val node = NodeUtils.findNodeByResourceId(rootNode, id)
            if (node != null && NodeUtils.isNodeVisible(node)) {
                val dist = NodeUtils.parseDistance(node.text?.toString() ?: "")
                if (dist > 0.0) {
                    explicitDrop = dist
                    break
                }
            }
        }
        
        if (explicitPickup > 0.0 && explicitDrop > 0.0) {
            return Pair(explicitPickup, explicitDrop)
        }
        
        // 2. Scan all visible nodes for distance strings
        val candidates = mutableListOf<RawDistance>()
        collectDistanceCandidates(rootNode, candidates)
        
        if (candidates.isNotEmpty()) {
            Log.d(TAG, "🔍 Distance candidates on screen: ${candidates.map { "${it.text} -> ${it.distanceKm}km (p:${it.isExplicitPickup}, d:${it.isExplicitDrop})" }}")
        }
        
        if (candidates.isEmpty()) {
            return Pair(explicitPickup, explicitDrop)
        }
        
        // Check for explicitly labeled candidates
        val pickupCandidate = candidates.firstOrNull { it.isExplicitPickup }
        val dropCandidate = candidates.firstOrNull { it.isExplicitDrop }
        
        val pDist = if (explicitPickup > 0.0) explicitPickup else (pickupCandidate?.distanceKm ?: 0.0)
        val tDist = if (explicitDrop > 0.0) explicitDrop else (dropCandidate?.distanceKm ?: 0.0)
        
        if (pDist > 0.0 && tDist > 0.0) {
            return Pair(pDist, tDist)
        }
        
        // If 2 distinct distances exist without explicit labels:
        // In ride orders, pickup (driver to customer) is smaller, and trip (customer ride across town) is larger!
        val uniqueDistances = candidates.map { it.distanceKm }.distinct().sorted()
        if (uniqueDistances.size >= 2) {
            val smaller = uniqueDistances.first()
            val larger = uniqueDistances.last()
            return Pair(smaller, larger)
        }
        
        // Only 1 distance candidate found
        val single = candidates.first().distanceKm
        if (pDist > 0.0) return Pair(pDist, 0.0)
        if (tDist > 0.0) return Pair(0.0, tDist)
        
        // If single distance is large (> 4.0 km), driver is not 9.5 km away from rider for an auto/bike ride;
        // it is almost certainly the customer's trip distance!
        return if (single > 4.0) {
            Log.d(TAG, "Single distance candidate $single km > 4.0 km, classifying as trip distance (pickup unknown/nearby)")
            Pair(0.0, single)
        } else {
            Pair(single, 0.0)
        }
    }
    
    private fun collectDistanceCandidates(node: AccessibilityNodeInfo, result: MutableList<RawDistance>) {
        if (NodeUtils.isNodeVisible(node)) {
            val text = node.text?.toString() ?: ""
            val desc = node.contentDescription?.toString() ?: ""
            val combined = "$text $desc".trim()
            
            if (combined.isNotBlank()) {
                val lower = combined.lowercase()
                val hasDistanceIndicator = lower.contains("km") || 
                    lower.contains("away") || 
                    Regex("""\b\d+\s*(?:m|mtr|meter|meters)\b""").containsMatchIn(lower)
                
                if (hasDistanceIndicator) {
                    val parsed = NodeUtils.parseDistance(combined)
                    if (parsed > 0.0) {
                        val isPickup = lower.contains("away") || lower.contains("pickup") || lower.contains("pick up") || lower.contains("from you")
                        val isDrop = lower.contains("drop") || lower.contains("trip") || lower.contains("destination") || lower.contains("ride")
                        result.add(RawDistance(parsed, combined, isPickup, isDrop))
                    }
                }
            }
        }
        
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            collectDistanceCandidates(child, result)
        }
    }
    
    private fun extractPickupAddress(rootNode: AccessibilityNodeInfo): String {
        for (id in PICKUP_ADDRESS_IDS) {
            val node = NodeUtils.findNodeByResourceId(rootNode, id)
            if (node != null && NodeUtils.isNodeVisible(node)) {
                return node.text?.toString() ?: ""
            }
        }
        return ""
    }
    
    private fun extractDropAddress(rootNode: AccessibilityNodeInfo): String {
        for (id in DROP_ADDRESS_IDS) {
            val node = NodeUtils.findNodeByResourceId(rootNode, id)
            if (node != null && NodeUtils.isNodeVisible(node)) {
                return node.text?.toString() ?: ""
            }
        }
        return ""
    }
    
    /**
     * Check if order should be accepted based on user settings
     */
    private fun shouldAcceptOrder(orderData: OrderData, config: ServiceConfig): Boolean {
        if (!config.autoAccept) {
            Log.d(TAG, "Auto-accept disabled in settings")
            return false
        }
        
        // Amount must be valid positive number
        if (orderData.fare <= 0.0) {
            Log.d(TAG, "Fare is 0, rejecting order")
            return false
        }
        
        if (orderData.fare < config.minFare) {
            Log.d(TAG, "Fare too low: ₹${orderData.fare} < ₹${config.minFare}")
            return false
        }
        
        if (orderData.fare > config.maxFare) {
            Log.d(TAG, "Fare too high: ₹${orderData.fare} > ₹${config.maxFare}")
            return false
        }
        
        if (orderData.pickupDistance > 0 && config.pickupDistance > 0 && orderData.pickupDistance > config.pickupDistance) {
            Log.d(TAG, "Pickup too far: ${orderData.pickupDistance}km > ${config.pickupDistance}km")
            return false
        }
        
        if (orderData.tripDistance > 0 && config.tripDistance > 0 && orderData.tripDistance > config.tripDistance) {
            Log.d(TAG, "Trip too long: ${orderData.tripDistance}km > ${config.tripDistance}km")
            return false
        }
        
        Log.i(TAG, "Order passed all filters ✓ (Fare=₹${orderData.fare})")
        return true
    }

    /**
     * Get specific rejection reason for diagnostic telemetry & rider assistance
     */
    private fun getFilterRejectionReason(orderData: OrderData, config: ServiceConfig): String? {
        if (!config.autoAccept) return "Auto-accept toggle disabled in settings"
        if (orderData.fare <= 0.0) return "Order fare is ₹0 or unreadable"
        if (orderData.fare < config.minFare) return "Fare ₹${orderData.fare.toInt()} < Rider Min ₹${config.minFare.toInt()}"
        if (orderData.fare > config.maxFare) return "Fare ₹${orderData.fare.toInt()} > Rider Max ₹${config.maxFare.toInt()}"
        if (orderData.pickupDistance > 0 && config.pickupDistance > 0 && orderData.pickupDistance > config.pickupDistance) return "Pickup ${orderData.pickupDistance}km > Rider Max ${config.pickupDistance}km"
        if (orderData.tripDistance > 0 && config.tripDistance > 0 && orderData.tripDistance > config.tripDistance) return "Trip ${orderData.tripDistance}km > Rider Max ${config.tripDistance}km"
        return null
    }
    
    /**
     * Find the accept button
     * Strictly verifies visibility and excludes sentence text
     */
    private fun findAcceptButton(rootNode: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        // Try by resource ID
        for (id in ACCEPT_BUTTON_IDS) {
            val button = NodeUtils.findNodeByResourceId(rootNode, id)
            if (button != null && NodeUtils.isNodeVisible(button)) {
                Log.i(TAG, "🎯 [Accept Button Matched by ID] id='$id', text='${button.text}', clickable=${button.isClickable}")
                return button
            }
        }
        
        // Find genuine accept buttons
        val acceptButtons = NodeUtils.findAcceptButtons(rootNode)
        if (acceptButtons.isNotEmpty()) {
            val btn = acceptButtons.first()
            Log.i(TAG, "🎯 [Accept Button Matched by Text] text='${btn.text}', desc='${btn.contentDescription}', clickable=${btn.isClickable}")
            return btn
        }
        
        return null
    }

    private fun findOrderCard(rootNode: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        for (id in ORDER_CARD_IDS) {
            val card = NodeUtils.findNodeByResourceId(rootNode, id)
            if (card != null && NodeUtils.isNodeVisible(card)) return card
        }
        return null
    }
    
    private data class OrderData(
        val fare: Double,
        val pickupDistance: Double,
        val tripDistance: Double,
        val pickupAddress: String,
        val dropAddress: String
    )
}
