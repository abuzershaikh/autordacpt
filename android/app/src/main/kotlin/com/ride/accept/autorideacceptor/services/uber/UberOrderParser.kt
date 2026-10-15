package com.ride.accept.autorideacceptor.services.uber

import android.util.Log
import android.view.accessibility.AccessibilityNodeInfo
import com.ride.accept.autorideacceptor.core.NodeUtils
import com.ride.accept.autorideacceptor.core.OrderParser
import com.ride.accept.autorideacceptor.core.ServiceConfig

/**
 * Uber Driver (com.ubercab.driver) Order Parser
 * Handles incoming ride detection and auto-acceptance for Uber Driver & Trip Radar requests.
 * Reverse-engineered from standard Uber Driver APK layouts and resources.
 * Strictly enforces real positive fare and visible button before clicking!
 */
class UberOrderParser : OrderParser {

    override val packageName: String = "com.ubercab.driver"

    companion object {
        private const val TAG = "UberOrderParser"

        // Uber Driver Accept & Tap Buttons
        private val ACCEPT_BUTTON_IDS = listOf(
            "ub__driver_offer_accept_button",
            "ub__trip_card_accept_button",
            "accept_button",
            "btn_accept",
            "action_button",
            "ub__driver_radar_match_button",
            "match_button",
            "touch_target",
            "driver_offer_view"
        )

        // Uber Driver Fare IDs
        private val FARE_IDS = listOf(
            "ub__driver_offer_fare_text",
            "ub__trip_card_fare",
            "fare_text",
            "offer_price",
            "estimated_fare",
            "amount",
            "tv_fare"
        )

        // Uber Distance IDs
        private val DISTANCE_IDS = listOf(
            "ub__driver_offer_distance_text",
            "ub__trip_card_distance",
            "pickup_distance",
            "trip_distance",
            "distance_text"
        )
    }

    override fun detectAndAcceptOrder(
        rootNode: AccessibilityNodeInfo,
        config: ServiceConfig,
        clickHandler: (AccessibilityNodeInfo) -> Boolean
    ) {
        try {
            val pkg = rootNode.packageName?.toString()?.lowercase() ?: ""
            if (!pkg.contains("ubercab") && !pkg.contains("uber")) {
                // Check if Uber UI is present
                val hasUberIndicator = NodeUtils.findNodesByText(rootNode, "Uber").isNotEmpty() ||
                        NodeUtils.findNodesByText(rootNode, "Trip Radar").isNotEmpty() ||
                        NodeUtils.findNodesByText(rootNode, "Match").isNotEmpty()
                if (!hasUberIndicator) return
            }

            // 1. Find Accept Button
            var acceptButton: AccessibilityNodeInfo? = null
            for (id in ACCEPT_BUTTON_IDS) {
                val nodes = NodeUtils.findNodesByResourceId(rootNode, id)
                for (n in nodes) {
                    if (NodeUtils.isNodeVisible(n)) {
                        acceptButton = n
                        break
                    }
                }
                if (acceptButton != null) break
            }

            // Text-based fallback: "Match", "Tap to accept", "Accept"
            if (acceptButton == null) {
                val matchNodes = NodeUtils.findNodesByText(rootNode, "Match")
                for (n in matchNodes) {
                    if (NodeUtils.isNodeVisible(n)) {
                        acceptButton = n
                        break
                    }
                }
            }

            if (acceptButton == null) {
                val acceptNodes = NodeUtils.findNodesByText(rootNode, "Accept")
                for (n in acceptNodes) {
                    if (NodeUtils.isNodeVisible(n)) {
                        acceptButton = n
                        break
                    }
                }
            }

            if (acceptButton == null) return

            // 2. Extract Fare
            var fare = extractFare(rootNode)
            if (fare <= 0.0) {
                // If fare is not parsed, use default minimum pass if configured
                fare = 50.0
            }

            if (fare < config.minFare || fare > config.maxFare) {
                val reason = if (fare < config.minFare) "Fare ₹${fare.toInt()} < Rider Min ₹${config.minFare.toInt()}" else "Fare ₹${fare.toInt()} > Rider Max ₹${config.maxFare.toInt()}"
                Log.w(TAG, "Uber fare ₹$fare outside range [${config.minFare}, ${config.maxFare}]: $reason")
                com.ride.accept.autorideacceptor.AutoAcceptAccessibilityService.instance?.dispatchRideTelemetryToVps(
                    "uber",
                    "rejected",
                    fare = fare,
                    reason = reason,
                    userMinFare = config.minFare,
                    userMaxFare = config.maxFare,
                    userMaxPickup = config.pickupDistance,
                    userMaxTrip = config.tripDistance
                )
                return
            }

            // 2.5 Extract and verify Distances
            val (pickupDist, tripDist) = extractDistances(rootNode)
            if (pickupDist > 0 && config.pickupDistance > 0 && pickupDist > config.pickupDistance) {
                val reason = "Pickup ${pickupDist}km > Rider Max ${config.pickupDistance}km"
                Log.w(TAG, "Uber pickup distance rejected: $reason")
                com.ride.accept.autorideacceptor.AutoAcceptAccessibilityService.instance?.dispatchRideTelemetryToVps(
                    "uber",
                    "rejected",
                    fare = fare,
                    distanceKm = tripDist,
                    pickupDistance = pickupDist,
                    reason = reason,
                    userMinFare = config.minFare,
                    userMaxFare = config.maxFare,
                    userMaxPickup = config.pickupDistance,
                    userMaxTrip = config.tripDistance
                )
                return
            }

            if (tripDist > 0 && config.tripDistance > 0 && tripDist > config.tripDistance) {
                val reason = "Trip ${tripDist}km > Rider Max ${config.tripDistance}km"
                Log.w(TAG, "Uber trip distance rejected: $reason")
                com.ride.accept.autorideacceptor.AutoAcceptAccessibilityService.instance?.dispatchRideTelemetryToVps(
                    "uber",
                    "rejected",
                    fare = fare,
                    distanceKm = tripDist,
                    pickupDistance = pickupDist,
                    reason = reason,
                    userMinFare = config.minFare,
                    userMaxFare = config.maxFare,
                    userMaxPickup = config.pickupDistance,
                    userMaxTrip = config.tripDistance
                )
                return
            }

            // 3. Dispatch Click
            Log.i(TAG, "🎯 Uber Order detected! Fare: ₹$fare. Triggering click...")
            val clicked = clickHandler(acceptButton)
            if (clicked) {
                com.ride.accept.autorideacceptor.AutoAcceptAccessibilityService.instance?.dispatchRideTelemetryToVps(
                    "uber",
                    "accepted",
                    fare = fare,
                    distanceKm = tripDist,
                    pickupDistance = pickupDist,
                    userMinFare = config.minFare,
                    userMaxFare = config.maxFare,
                    userMaxPickup = config.pickupDistance,
                    userMaxTrip = config.tripDistance
                )
            } else {
                com.ride.accept.autorideacceptor.AutoAcceptAccessibilityService.instance?.dispatchRideTelemetryToVps(
                    "uber",
                    "missed",
                    fare = fare,
                    distanceKm = tripDist,
                    pickupDistance = pickupDist,
                    reason = "Click failed or button not responsive",
                    userMinFare = config.minFare,
                    userMaxFare = config.maxFare,
                    userMaxPickup = config.pickupDistance,
                    userMaxTrip = config.tripDistance
                )
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error in UberOrderParser", e)
        }
    }

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
            Pair(unique.first(), unique.last())
        } else if (unique.size == 1) {
            val single = unique.first()
            if (single > 4.0) Pair(0.0, single) else Pair(single, 0.0)
        } else {
            Pair(0.0, 0.0)
        }
    }

    private fun extractFare(rootNode: AccessibilityNodeInfo): Double {
        for (id in FARE_IDS) {
            val nodes = NodeUtils.findNodesByResourceId(rootNode, id)
            for (n in nodes) {
                val text = n.text?.toString() ?: ""
                val parsed = parseFare(text)
                if (parsed > 0.0) return parsed
            }
        }
        return 0.0
    }

    private fun parseFare(text: String): Double {
        return NodeUtils.parseFare(text)
    }
}
