package com.ride.accept.autorideacceptor.services.porter

import android.util.Log
import android.view.accessibility.AccessibilityNodeInfo
import com.ride.accept.autorideacceptor.core.OrderData
import com.ride.accept.autorideacceptor.core.OrderParser
import com.ride.accept.autorideacceptor.core.ServiceConfig
import com.ride.accept.autorideacceptor.core.NodeUtils

/**
 * Porter Order Parser
 * Handles order detection and auto-acceptance for Porter Driver / Partner app
 * Safeguarded against empty screens, dialogs, and invisible views.
 */
class PorterOrderParser : OrderParser {
    
    companion object {
        private const val TAG = "PorterOrderParser"
        
        // Resource IDs for Porter Order Cards
        private val CARD_IDS = listOf(
            "acceptOrderCard",
            "orderCard",
            "tray_order_item",
            "order_card_container",
            "orderCardLayout",
            "card_order",
            "tray_order_layout"
        )
        private val FARE_IDS = listOf(
            "tvAmount",
            "tv_fare",
            "tv_amount",
            "amount",
            "fare",
            "tvPrice",
            "price",
            "fare_amount"
        )
        private val DISTANCE_IDS = listOf(
            "dryRun",
            "tv_distance",
            "distance",
            "tvDistance",
            "distance_text",
            "pickup_distance"
        )
        private val PICKUP_IDS = listOf(
            "tvPickUp",
            "tv_pickup",
            "pickup_address",
            "tvPickupAddress"
        )
        private val DROP_IDS = listOf(
            "tvDropAddress",
            "tv_drop",
            "drop_address",
            "tvDrop"
        )
        private val BUTTON_IDS = listOf(
            "acceptOrderCard",
            "btnAccept",
            "btn_accept",
            "acceptButton",
            "btnConsentAccept",
            "btn_accept_order",
            "btnAcceptOrder",
            "cta_button",
            "action_button"
        )
    }
    
    override val packageName = "in.porter.rider"
    
    override fun detectAndAcceptOrder(
        rootNode: AccessibilityNodeInfo,
        config: ServiceConfig,
        clickHandler: (AccessibilityNodeInfo) -> Boolean
    ) {
        // Step 1: Find all genuine visible order cards
        val orderCards = mutableListOf<AccessibilityNodeInfo>()
        for (cardId in CARD_IDS) {
            val found = NodeUtils.findNodesByResourceId(rootNode, cardId)
            if (found.isNotEmpty()) {
                orderCards.addAll(found)
                break
            }
        }
        
        // Step 2: If no card found by ID, look for genuine visible Accept buttons
        if (orderCards.isEmpty()) {
            val acceptButtons = NodeUtils.findAcceptButtons(rootNode)
            if (acceptButtons.isNotEmpty()) {
                // Must also confirm that a fare symbol ₹ is present somewhere on screen
                val rupeeNodes = NodeUtils.findNodesByText(rootNode, "₹")
                if (rupeeNodes.isNotEmpty()) {
                    orderCards.addAll(acceptButtons)
                }
            }
        }
        
        // If no verified cards or accept buttons exist, screen is idle / empty. DO NOTHING!
        if (orderCards.isEmpty()) {
            return
        }
        
        val orders = mutableListOf<OrderData>()
        
        // Step 3: Extract and verify data for each card (Must have fare > 0)
        for (card in orderCards) {
            try {
                val orderData = extractOrderData(card, rootNode)
                if (orderData != null && orderData.fare > 0.0) {
                    orders.add(orderData)
                    Log.i(TAG, "✓ Verified Porter Order: Fare=₹${orderData.fare}, Dist=${orderData.distance}km, Pickup=${orderData.pickup}")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error extracting order data", e)
            }
        }
        
        // CRITICAL SAFEGUARD: If no verified orders with real fare were found,
        // DO NOT CLICK ANYTHING! Return immediately so empty screens/dialogs are never clicked!
        if (orders.isEmpty()) {
            Log.d(TAG, "No verified Porter order with valid fare detected. Screen is empty/idle. Skipping.")
            return
        }
        
        // Step 4: Apply user filters
        val filteredOrders = applyFilters(orders, config)
        if (filteredOrders.isEmpty()) {
            val first = orders.firstOrNull()
            var reason = "Filtered out by rider criteria"
            if (first != null) {
                if (first.fare < config.minFare) reason = "Fare ₹${first.fare.toInt()} < Rider Min ₹${config.minFare.toInt()}"
                else if (first.fare > config.maxFare) reason = "Fare ₹${first.fare.toInt()} > Rider Max ₹${config.maxFare.toInt()}"
                else if (config.pickupDistance > 0 && first.pickupDistance > config.pickupDistance) reason = "Pickup ${first.pickupDistance}km > Rider Max ${config.pickupDistance}km"
                else if (config.tripDistance > 0 && first.tripDistance > config.tripDistance) reason = "Trip ${first.tripDistance}km > Rider Max ${config.tripDistance}km"
            }
            Log.d(TAG, "Orders filtered out by criteria: $reason")
            com.ride.accept.autorideacceptor.AutoAcceptAccessibilityService.instance?.dispatchRideTelemetryToVps(
                "porter",
                "rejected",
                fare = first?.fare ?: 0.0,
                distanceKm = first?.tripDistance ?: 0.0,
                pickupDistance = first?.pickupDistance ?: 0.0,
                reason = reason,
                userMinFare = config.minFare,
                userMaxFare = config.maxFare,
                userMaxPickup = config.pickupDistance,
                userMaxTrip = config.tripDistance
            )
            return
        }
        
        // Step 5: Sort by fare (highest first)
        val sortedOrders = filteredOrders.sortedByDescending { it.fare }
        val bestOrder = sortedOrders.first()
        Log.i(TAG, "🎯 ACCEPTING VERIFIED PORTER ORDER: Fare=₹${bestOrder.fare}, Dist=${bestOrder.distance}km")
        
        // Step 6: Find specific accept button inside bestOrder or use verified card
        var clickTarget = bestOrder.node
        for (btnId in BUTTON_IDS) {
            val btn = NodeUtils.findNodeByResourceId(bestOrder.node, btnId)
            if (btn != null && NodeUtils.isNodeVisible(btn)) {
                clickTarget = btn
                break
            }
        }
        
        if (clickTarget == bestOrder.node) {
            val innerAcceptBtns = NodeUtils.findAcceptButtons(bestOrder.node)
            if (innerAcceptBtns.isNotEmpty()) {
                clickTarget = innerAcceptBtns.first()
            }
        }
        
        val clicked = clickHandler(clickTarget)
        if (clicked) {
            Log.i(TAG, "✅ Porter order accepted with real hardware tap! Fare=₹${bestOrder.fare}")
            com.ride.accept.autorideacceptor.AutoAcceptAccessibilityService.instance?.dispatchRideTelemetryToVps(
                "porter",
                "accepted",
                fare = bestOrder.fare,
                distanceKm = bestOrder.tripDistance,
                pickupDistance = bestOrder.pickupDistance,
                userMinFare = config.minFare,
                userMaxFare = config.maxFare,
                userMaxPickup = config.pickupDistance,
                userMaxTrip = config.tripDistance
            )
        } else {
            Log.e(TAG, "❌ Failed to click Porter accept target")
            com.ride.accept.autorideacceptor.AutoAcceptAccessibilityService.instance?.dispatchRideTelemetryToVps(
                "porter",
                "missed",
                fare = bestOrder.fare,
                pickupDistance = bestOrder.distance,
                reason = "Click failed or target not clickable",
                userMinFare = config.minFare,
                userMaxFare = config.maxFare,
                userMaxPickup = config.pickupDistance,
                userMaxTrip = config.tripDistance
            )
        }
    }
    
    /**
     * Extract order data from card node
     */
    private fun extractOrderData(cardNode: AccessibilityNodeInfo, rootNode: AccessibilityNodeInfo): OrderData? {
        try {
            // Extract fare strictly from card and avoid earnings/wallet/top-bar
            var fare = 0.0
            for (fareId in FARE_IDS) {
                val fareNode = NodeUtils.findNodeByResourceId(cardNode, fareId)
                if (fareNode != null && NodeUtils.isNodeVisible(fareNode) && !NodeUtils.isTopBarHeaderNode(fareNode)) {
                    val fareText = fareNode.text?.toString() ?: ""
                    if (!NodeUtils.isEarningsOrWalletText(fareText)) {
                        val parsed = NodeUtils.parseFare(fareText)
                        if (parsed > 0.0) {
                            fare = parsed
                            break
                        }
                    }
                }
            }
            
            // Fallback fare: Search for ₹ in card
            if (fare <= 0.0) {
                val rupeeNodes = NodeUtils.findNodesByText(cardNode, "₹")
                for (rn in rupeeNodes) {
                    if (NodeUtils.isNodeVisible(rn) && !NodeUtils.isTopBarHeaderNode(rn)) {
                        val text = rn.text?.toString() ?: ""
                        val parentText = rn.parent?.text?.toString() ?: ""
                        if (!NodeUtils.isEarningsOrWalletText(text) && !NodeUtils.isEarningsOrWalletText(parentText)) {
                            val parsed = NodeUtils.parseFare(text)
                            if (parsed > 0.0) {
                                fare = parsed
                                break
                            }
                        }
                    }
                }
            }
            
            // Fallback: If not in card, search root for ₹ strictly skipping top-bar & wallet
            if (fare <= 0.0) {
                val rupeeNodes = NodeUtils.findNodesByText(rootNode, "₹")
                for (rn in rupeeNodes) {
                    if (NodeUtils.isNodeVisible(rn) && !NodeUtils.isTopBarHeaderNode(rn)) {
                        val text = rn.text?.toString() ?: ""
                        val parentText = rn.parent?.text?.toString() ?: ""
                        if (!NodeUtils.isEarningsOrWalletText(text) && !NodeUtils.isEarningsOrWalletText(parentText)) {
                            val parsed = NodeUtils.parseFare(text)
                            if (parsed > 0.0) {
                                fare = parsed
                                break
                            }
                        }
                    }
                }
            }
            
            // An order offer MUST have a valid fare!
            if (fare <= 0.0) return null
            
            // Extract distances (pickup vs trip)
            var pickupDist = 0.0
            val dryRunNode = NodeUtils.findNodeByResourceId(cardNode, "dryRun")
            if (dryRunNode != null && NodeUtils.isNodeVisible(dryRunNode)) {
                pickupDist = NodeUtils.parseDistance(dryRunNode.text?.toString() ?: "")
            }

            var tripDist = 0.0
            for (distId in listOf("tv_distance", "distance", "tvDistance", "distance_text")) {
                val distNode = NodeUtils.findNodeByResourceId(cardNode, distId)
                if (distNode != null && NodeUtils.isNodeVisible(distNode)) {
                    val parsed = NodeUtils.parseDistance(distNode.text?.toString() ?: "")
                    if (parsed > 0.0) {
                        tripDist = parsed
                        break
                    }
                }
            }

            // Fallback: If not separated by ID, inspect all "km" nodes in card
            if (pickupDist <= 0.0 || tripDist <= 0.0) {
                val kmNodes = NodeUtils.findNodesByText(cardNode, "km")
                val kmValues = kmNodes.filter { NodeUtils.isNodeVisible(it) }
                    .map { NodeUtils.parseDistance(it.text?.toString() ?: "") }
                    .filter { it > 0.0 }
                    .distinct()
                    .sorted()
                if (kmValues.size >= 2) {
                    if (pickupDist <= 0.0) pickupDist = kmValues.first()
                    if (tripDist <= 0.0) tripDist = kmValues.last()
                } else if (kmValues.size == 1) {
                    val single = kmValues.first()
                    if (single > 4.0) {
                        if (tripDist <= 0.0) tripDist = single
                    } else {
                        if (pickupDist <= 0.0) pickupDist = single
                    }
                }
            }
            val primaryDistance = if (tripDist > 0.0) tripDist else pickupDist
            
            // Extract pickup
            var pickup = "Porter Pickup"
            for (pId in PICKUP_IDS) {
                val pNode = NodeUtils.findNodeByResourceId(cardNode, pId)
                if (pNode != null) {
                    pickup = pNode.text?.toString() ?: pickup
                    break
                }
            }
            
            // Extract drop
            var drop = "Porter Drop"
            for (dId in DROP_IDS) {
                val dNode = NodeUtils.findNodeByResourceId(cardNode, dId)
                if (dNode != null) {
                    drop = dNode.text?.toString() ?: drop
                    break
                }
            }
            
            return OrderData(
                node = cardNode,
                fare = fare,
                distance = primaryDistance,
                pickup = pickup,
                drop = drop,
                pickupDistance = pickupDist,
                tripDistance = tripDist
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting order data", e)
            return null
        }
    }
    
    /**
     * Apply user filters to orders
     */
    private fun applyFilters(orders: List<OrderData>, config: ServiceConfig): List<OrderData> {
        return orders.filter { order ->
            val fareOk = order.fare >= config.minFare && order.fare <= config.maxFare
            val pickupOk = config.pickupDistance <= 0.0 || order.pickupDistance <= 0.0 || order.pickupDistance <= config.pickupDistance
            val tripOk = config.tripDistance <= 0.0 || order.tripDistance <= 0.0 || order.tripDistance <= config.tripDistance
            fareOk && pickupOk && tripOk
        }
    }
}
