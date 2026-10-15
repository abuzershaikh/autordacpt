package com.ride.accept.autorideacceptor.core

import android.os.Build
import android.view.accessibility.AccessibilityNodeInfo

/**
 * Utility functions for AccessibilityNodeInfo operations
 */
object NodeUtils {
    
    /**
     * Find all visible nodes with specific resource ID
     */
    fun findNodesByResourceId(node: AccessibilityNodeInfo, resourceId: String): List<AccessibilityNodeInfo> {
        val nodes = mutableListOf<AccessibilityNodeInfo>()
        findNodesByResourceIdRecursive(node, resourceId, nodes)
        return nodes
    }
    
    private fun findNodesByResourceIdRecursive(
        node: AccessibilityNodeInfo,
        resourceId: String,
        result: MutableList<AccessibilityNodeInfo>
    ) {
        if (node.viewIdResourceName?.contains(resourceId, ignoreCase = true) == true) {
            if (isNodeVisible(node)) {
                result.add(node)
            }
        }
        
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            findNodesByResourceIdRecursive(child, resourceId, result)
        }
    }
    
    /**
     * Find single visible node with specific resource ID
     */
    fun findNodeByResourceId(node: AccessibilityNodeInfo, resourceId: String): AccessibilityNodeInfo? {
        if (node.viewIdResourceName?.contains(resourceId, ignoreCase = true) == true) {
            if (isNodeVisible(node)) {
                return node
            }
        }
        
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val found = findNodeByResourceId(child, resourceId)
            if (found != null) return found
        }
        
        return null
    }
    
    /**
     * Check if a node is genuinely visible to the user on screen
     */
    fun isNodeVisible(node: AccessibilityNodeInfo): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
            if (!node.isVisibleToUser) return false
        }
        return true
    }
    
    /**
     * Strict check to identify if a node is an actual "Accept" button
     * Rejects sentences, dialogs, warnings, and invisible views.
     */
    fun isAcceptButton(node: AccessibilityNodeInfo): Boolean {
        if (!isNodeVisible(node)) return false
        
        val text = (node.text?.toString() ?: "").trim()
        val desc = (node.contentDescription?.toString() ?: "").trim()
        val label = if (text.isNotBlank()) text else desc
        
        if (label.isBlank()) return false
        if (label.length > 25) return false // Full sentences like "You cannot accept orders..." are NOT buttons!
        
        val lower = label.lowercase()
        
        // Exclude system/informational phrases containing "accept"
        val negativePhrases = listOf(
            "cannot",
            "not accept",
            "unable",
            "acceptance",
            "rate",
            "score",
            "turn off",
            "developer",
            "history",
            "searching",
            "refresh",
            "check account",
            "status",
            "option"
        )
        if (negativePhrases.any { lower.contains(it) }) return false
        
        val exactAcceptWords = listOf(
            "accept",
            "accept order",
            "accept ride",
            "swipe to accept",
            "slide to accept",
            "ready for next order",
            "स्वीकार करें",
            "स्वीकार",
            "स्वीकार करा"
        )
        
        return exactAcceptWords.any { lower == it || lower.startsWith(it) }
    }
    
    /**
     * Find genuine Accept buttons across node hierarchy
     */
    fun findAcceptButtons(rootNode: AccessibilityNodeInfo): List<AccessibilityNodeInfo> {
        val buttons = mutableListOf<AccessibilityNodeInfo>()
        findAcceptButtonsRecursive(rootNode, buttons)
        return buttons
    }
    
    private fun findAcceptButtonsRecursive(node: AccessibilityNodeInfo, result: MutableList<AccessibilityNodeInfo>) {
        if (isAcceptButton(node)) {
            result.add(node)
        }
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            findAcceptButtonsRecursive(child, result)
        }
    }
    
    /**
     * Find visible nodes by text or contentDescription
     */
    fun findNodesByText(node: AccessibilityNodeInfo, text: String): List<AccessibilityNodeInfo> {
        val nodes = mutableListOf<AccessibilityNodeInfo>()
        findNodesByTextRecursive(node, text, nodes)
        return nodes
    }
    
    private fun findNodesByTextRecursive(
        node: AccessibilityNodeInfo,
        text: String,
        result: MutableList<AccessibilityNodeInfo>
    ) {
        val nodeText = node.text?.toString() ?: ""
        val contentDesc = node.contentDescription?.toString() ?: ""
        if (nodeText.contains(text, ignoreCase = true) || contentDesc.contains(text, ignoreCase = true)) {
            if (isNodeVisible(node)) {
                result.add(node)
            }
        }
        
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            findNodesByTextRecursive(child, text, result)
        }
    }
    
    /**
     * Checks if text belongs to driver earnings, wallet balance, incentive, or address labels.
     * Prevents daily earnings (e.g. ₹1,200) or wallet balance from being mistaken as the current order fare!
     */
    fun isEarningsOrWalletText(text: String): Boolean {
        if (text.isBlank()) return false
        val lower = text.lowercase()
        val keywords = listOf(
            "today",
            "earning",
            "earnings",
            "wallet",
            "balance",
            "incentive",
            "target",
            "bonus",
            "penalty",
            "payout",
            "kamai",
            "kamayi",
            "कमाई",
            "बैलेंस",
            "इंसेंटिव",
            "order #",
            "order no",
            "sector",
            "street",
            "road",
            "flat",
            "floor"
        )
        return keywords.any { lower.contains(it) }
    }

    /**
     * Checks if node is positioned in the topmost status bar/header area of the screen (top 260px)
     * where persistent daily earnings or wallet balance icons are displayed.
     */
    fun isTopBarHeaderNode(node: AccessibilityNodeInfo): Boolean {
        return try {
            val rect = android.graphics.Rect()
            node.getBoundsInScreen(rect)
            rect.bottom in 1..260
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Parse fare from text (₹450, ₹ 450, ₹1,250, ₹12,500, ₹1,25,000, ₹450.50, Rs. 450, 450/-, etc.)
     * Handles any number of digits with Indian or standard thousands separators (commas)
     * and optional decimal paise (.XX).
     * STRICT: Rejects earnings/wallet balances and random address numbers!
     */
    fun parseFare(fareText: String): Double {
        if (fareText.isBlank()) return 0.0
        if (isEarningsOrWalletText(fareText)) return 0.0
        try {
            // Priority 1: Currency symbol (₹, Rs, INR) followed by number with optional thousands commas and decimals
            // Handles both comma-separated (₹12,500, ₹1,25,000) and plain numbers (₹1200, ₹12500, ₹450.50, etc.)
            val currencyRegex = Regex(
                """(?:₹|rs\.?|inr)\s*([0-9]{1,3}(?:,[0-9]{2,3})+(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)""",
                RegexOption.IGNORE_CASE
            )
            val currencyMatch = currencyRegex.find(fareText)
            if (currencyMatch != null) {
                val rawNumber = currencyMatch.groupValues[1].replace(",", "")
                val parsed = rawNumber.toDoubleOrNull()
                if (parsed != null && parsed > 0.0) return parsed
            }

            // Priority 2: Number followed by /- (e.g. 450/-, 1200/-, 1,250/-, 12500/-)
            val suffixRegex = Regex("""([0-9]{1,3}(?:,[0-9]{2,3})+(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)\s*(?:/-)""")
            val suffixMatch = suffixRegex.find(fareText)
            if (suffixMatch != null) {
                val rawNumber = suffixMatch.groupValues[1].replace(",", "")
                val parsed = rawNumber.toDoubleOrNull()
                if (parsed != null && parsed > 0.0) return parsed
            }

            // Priority 3: Standalone number with commas (e.g. "1,250" or "12,500" or "1,25,000")
            val commaNumberRegex = Regex("""\b([0-9]{1,3}(?:,[0-9]{2,3})+(?:\.[0-9]{1,2})?)\b""")
            val commaMatch = commaNumberRegex.find(fareText)
            if (commaMatch != null) {
                val rawNumber = commaMatch.groupValues[1].replace(",", "")
                val parsed = rawNumber.toDoubleOrNull()
                if (parsed != null && parsed > 0.0) return parsed
            }

            // Priority 4: Pure numeric text (the node itself is strictly just digits, e.g. "45" or "120.50")
            // Rejects sentences and addresses like "Sector 40, Street 2" or "Order 15"
            val trimmed = fareText.trim()
            val pureNumericRegex = Regex("""^([0-9]{1,5}(?:\.[0-9]{1,2})?)$""")
            val pureMatch = pureNumericRegex.find(trimmed)
            if (pureMatch != null) {
                val parsed = pureMatch.groupValues[1].toDoubleOrNull()
                if (parsed != null && parsed > 0.0) return parsed
            }
        } catch (_: Exception) {}
        return 0.0
    }
    
    /**
     * Parse distance from text (2.5 km away, 3.2km, 3.2 किमी, 500 m, 300 m away, etc.)
     * Returns distance normalized to kilometers (e.g. 500 m -> 0.5 km)
     * Strictly avoids misinterpreting minutes (15 min) or fares (₹450) as distance!
     */
    fun parseDistance(distanceText: String): Double {
        if (distanceText.isBlank()) return 0.0
        try {
            val lower = distanceText.lowercase().trim()

            // 1. Check for kilometers (e.g. 2.5 km, 9.5km, 10 kms, 2,5 km, 3.5 किमी)
            val kmRegex = Regex("""([0-9]+(?:[.,][0-9]+)?)\s*(?:km|kms|किमी)\b""", RegexOption.IGNORE_CASE)
            val kmMatch = kmRegex.find(lower)
            if (kmMatch != null) {
                val candidate = kmMatch.groupValues[1].replace(",", ".")
                val parsed = candidate.toDoubleOrNull()
                if (parsed != null && parsed > 0.0) return parsed
            }

            // 2. Check for explicit meters (e.g. 500 m, 800 meter, 300 meters, 500 मीटर)
            // Exclude "min", "mins", "minute", "minutes"
            val meterRegex = Regex("""([0-9]+(?:\.[0-9]+)?)\s*(?:m|mtr|meter|meters|मीटर)\b(?!\s*(?:in|ute))""", RegexOption.IGNORE_CASE)
            val meterMatch = meterRegex.find(lower)
            if (meterMatch != null && !lower.contains("min") && !lower.contains("km") && !lower.contains("किमी")) {
                val meters = meterMatch.groupValues[1].toDoubleOrNull() ?: 0.0
                if (meters > 0.0) {
                    return meters / 1000.0
                }
            }

            // 3. Number directly preceding "away" / "दूर" with distance context (e.g. "2.5 away", "2.5 किमी दूर")
            // Make sure it doesn't say "min away" or "mins away"
            if (!lower.contains("min")) {
                val awayRegex = Regex("""([0-9]+(?:[.,][0-9]+)?)\s*(?:km\s*|किमी\s*)?(?:away|दूर)\b""", RegexOption.IGNORE_CASE)
                val awayMatch = awayRegex.find(lower)
                if (awayMatch != null) {
                    val candidate = awayMatch.groupValues[1].replace(",", ".")
                    val parsed = candidate.toDoubleOrNull()
                    if (parsed != null && parsed > 0.0) return parsed
                }
            }
        } catch (_: Exception) {}
        return 0.0
    }
}

