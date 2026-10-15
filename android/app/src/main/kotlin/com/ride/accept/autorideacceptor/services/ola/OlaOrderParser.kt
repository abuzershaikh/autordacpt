package com.ride.accept.autorideacceptor.services.ola

import android.util.Log
import android.view.accessibility.AccessibilityNodeInfo
import com.ride.accept.autorideacceptor.core.NodeUtils
import com.ride.accept.autorideacceptor.core.OrderParser
import com.ride.accept.autorideacceptor.core.ServiceConfig

/**
 * Ola Driver (com.olacabs.oladriver / com.olacabs.partner) Order Parser
 * Handles incoming ride detection and auto-acceptance for Ola Driver app.
 * Reverse-engineered directly from Ola Driver APK layouts and resources.
 * Strictly enforces real positive fare (fare > 0.0) and visible button before clicking!
 */
class OlaOrderParser : OrderParser {

    override val packageName: String = "com.olacabs.oladriver"

    companion object {
        private const val TAG = "OlaOrderParser"

        // Verified Ola APK Accept Button IDs
        private val ACCEPT_BUTTON_IDS = listOf(
            "btn_accept",                      // SecureAcceptButton in motivator_card & motivator_card_v2
            "btn_accept_lyt",                  // RelativeLayout container around btn_accept
            "booking_detail_accept",          // TextView/Button in local_booking, citytaxi, booking_notification
            "accept_btn",                      // ID in Ola driver core layout
            "accept_delivery",                 // ID in booking_p2p_v2
            "booking_action",                  // Action container in booking_notification
            "btn_share_accept",                // Share ride accept button
            "booking_detail_ok",               // OK / Confirm button in booking dialogs
            "anchorLayoutAcceptRides"          // Floating overlay accept anchor
        )

        // Verified Ola APK Fare & Earnings IDs
        private val FARE_IDS = listOf(
            "value",                           // TextView in item_prim_motivator & item_sec_motivator
            "m3",                              // Price headline TextView in motivator_card
            "tv_compact_price",                // Price in item_incoming_booking_compact
            "booking_bid_price",               // Price in booking_notification
            "amount",                          // Standalone amount view
            "amount_to_pay_textview",          // Amount text
            "m1",                              // Motivator 1 (price/earnings)
            "m4",                              // Motivator 4
            "m5",                              // Motivator 5
            "m16"                              // Motivator 16 in motivator_card_v2
        )

        // Verified Ola APK Order Card / Overlay Container IDs
        private val ORDER_CARD_IDS = listOf(
            "motivator_overlay_card_container", // Floating overlay card
            "motivator_overlay_container",      // SwipeUpView container
            "card_constraint_layout",          // Card ConstraintLayout in motivator_card
            "booking_card",                     // Card in booking_p2p_v2 & auto unicast
            "booking_card_layout",              // Card layout
            "booking_info_layout",              // Info container
            "income_booking_layout",            // Incoming booking layout
            "ll_compact_booking",               // Compact incoming booking item
            "bottom_booking_actions_container", // Action container in notification
            "card_view"                         // CardView in compact item
        )

        // Verified Ola APK Pickup & Drop IDs
        private val PICKUP_ADDRESS_IDS = listOf(
            "tv_detail_pickup_address",
            "tv_waypoint_1_address",
            "booking_detail_pickup_address",
            "booking_detail_pickup"
        )

        private val DROP_ADDRESS_IDS = listOf(
            "tv_detail_drop_address",
            "tv_waypoint_2_address",
            "booking_detail_drop_address",
            "booking_detail_drop_locality"
        )

        private val DISTANCE_IDS = listOf(
            "tv_pickup_distance_time",
            "tv_drop_distance_time",
            "tv_compact_distance"
        )

        // Negative words/phrases to reject onboarding, auth, or idle screens
        private val REJECT_SCREEN_KEYWORDS = listOf(
            "upload document",
            "vehicle rc",
            "driving licence",
            "profile photo",
            "cancel application",
            "start upload",
            "select your vehicle",
            "developers option",
            "driver rating"
        )
    }

    override fun detectAndAcceptOrder(
        rootNode: AccessibilityNodeInfo,
        config: ServiceConfig,
        clickHandler: (AccessibilityNodeInfo) -> Boolean
    ) {
        try {
            // Step 1: Check if screen is an onboarding or setup screen
            if (isNonBookingScreen(rootNode)) {
                return
            }

            // Step 2: Detect if screen has Ola order indicators
            if (!isOlaOrder(rootNode)) {
                return
            }

            // Step 3: Extract order data (FARE MUST BE > 0)
            val orderData = extractOrderData(rootNode)

            // CRITICAL USER MANDATE: Only click when real amount is shown (> 0).
            // When fare is 0 or missing, DO NOT CLICK!
            if (orderData == null || orderData.fare <= 0.0) {
                Log.d(TAG, "No valid fare amount detected for Ola order (fare=0). Skipping.")
                return
            }

            Log.i(TAG, "✓ Verified Ola Order detected: Fare=₹${orderData.fare}, Dist=${orderData.pickupDistance}km")

            // Step 4: Check user filters
            val filterRejectReason = getFilterRejectionReason(orderData, config)
            if (filterRejectReason != null) {
                Log.d(TAG, "Ola order rejected by filters: $filterRejectReason")
                com.ride.accept.autorideacceptor.AutoAcceptAccessibilityService.instance?.dispatchRideTelemetryToVps(
                    "ola",
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

            // Step 5: Find visible, genuine accept button
            val acceptButton = findAcceptButton(rootNode)
            if (acceptButton != null && NodeUtils.isNodeVisible(acceptButton)) {
                val accepted = clickHandler(acceptButton)
                if (accepted) {
                    Log.i(TAG, "🎯 Ola order accepted via button with real hardware tap! Fare=₹${orderData.fare}")
                    com.ride.accept.autorideacceptor.AutoAcceptAccessibilityService.instance?.dispatchRideTelemetryToVps(
                        "ola",
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

            // Fallback: Click verified order card if button is not separated
            val orderCard = findOrderCard(rootNode)
            if (orderCard != null && NodeUtils.isNodeVisible(orderCard)) {
                val accepted = clickHandler(orderCard)
                if (accepted) {
                    Log.i(TAG, "🎯 Ola order accepted via verified card: ₹${orderData.fare}")
                    com.ride.accept.autorideacceptor.AutoAcceptAccessibilityService.instance?.dispatchRideTelemetryToVps(
                        "ola",
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
            Log.d(TAG, "No visible clickable target found for Ola order")
            com.ride.accept.autorideacceptor.AutoAcceptAccessibilityService.instance?.dispatchRideTelemetryToVps(
                "ola",
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
            Log.e(TAG, "Error in Ola detectAndAcceptOrder", e)
        }
    }

    /**
     * Check if screen is an onboarding, registration, or non-booking screen
     */
    private fun isNonBookingScreen(rootNode: AccessibilityNodeInfo): Boolean {
        for (keyword in REJECT_SCREEN_KEYWORDS) {
            val matchingNodes = NodeUtils.findNodesByText(rootNode, keyword)
            if (matchingNodes.isNotEmpty()) {
                return true
            }
        }
        return false
    }

    /**
     * Check if current screen contains an incoming Ola booking
     */
    private fun isOlaOrder(rootNode: AccessibilityNodeInfo): Boolean {
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
     * Strictly returns null if fare is 0.0 or not found
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

        // Fallback: Find by ₹ or Rs symbol
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

    /**
     * Extract pickup and trip distances for Ola accurately
     * Distinguishes driver-to-customer pickup leg from customer-to-destination trip leg!
     */
    private fun extractDistances(rootNode: AccessibilityNodeInfo): Pair<Double, Double> {
        val distNodes = NodeUtils.findNodesByText(rootNode, "km")
        val candidates = mutableListOf<Double>()
        for (dn in distNodes) {
            if (NodeUtils.isNodeVisible(dn)) {
                val text = dn.text?.toString() ?: ""
                val dist = NodeUtils.parseDistance(text)
                if (dist > 0.0) candidates.add(dist)
            }
        }
        val unique = candidates.distinct().sorted()
        return if (unique.size >= 2) {
            // Smaller is driver pickup, larger is rider trip
            Pair(unique.first(), unique.last())
        } else if (unique.size == 1) {
            val single = unique.first()
            if (single > 4.0) Pair(0.0, single) else Pair(single, 0.0)
        } else {
            Pair(0.0, 0.0)
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
     * Check if order passes user filters
     */
    private fun shouldAcceptOrder(orderData: OrderData, config: ServiceConfig): Boolean {
        if (!config.autoAccept) {
            Log.d(TAG, "Auto-accept disabled in settings")
            return false
        }

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

        Log.i(TAG, "Ola order passed all filters ✓ (Fare=₹${orderData.fare})")
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
     * Find genuine, visible Accept button
     */
    private fun findAcceptButton(rootNode: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        // Try by verified Ola resource IDs
        for (id in ACCEPT_BUTTON_IDS) {
            val button = NodeUtils.findNodeByResourceId(rootNode, id)
            if (button != null && NodeUtils.isNodeVisible(button)) {
                return button
            }
        }

        // Try by genuine accept button labels ("Accept", "Swipe to accept", "Slide to accept")
        val acceptButtons = NodeUtils.findAcceptButtons(rootNode)
        if (acceptButtons.isNotEmpty()) {
            return acceptButtons.first()
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
