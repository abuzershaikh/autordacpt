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
     * Parse fare from text (₹450, ₹ 450, ₹450.50, Rs. 450, 450/-, etc.)
     */
    fun parseFare(fareText: String): Double {
        if (fareText.isBlank()) return 0.0
        try {
            // Find currency-adjacent or leading number like ₹ 450 or Rs. 450.50
            val regex = Regex("""(?:₹|rs\.?|inr)?\s*([0-9]+(?:[.,][0-9]{1,2})?)""", RegexOption.IGNORE_CASE)
            val match = regex.find(fareText)
            if (match != null) {
                val candidate = match.groupValues[1].replace(",", ".")
                val parsed = candidate.toDoubleOrNull()
                if (parsed != null && parsed > 0.0) return parsed
            }
            
            // Standalone number sequence
            val fallbackMatch = Regex("""\b([0-9]+(?:\.[0-9]+)?)\b""").find(fareText)
            if (fallbackMatch != null) {
                return fallbackMatch.groupValues[1].toDoubleOrNull() ?: 0.0
            }
        } catch (_: Exception) {}
        return 0.0
    }
    
    /**
     * Parse distance from text (2.5 km away, 3.2km, 500 m, 300 m away, etc.)
     * Returns distance normalized to kilometers (e.g. 500 m -> 0.5 km)
     */
    fun parseDistance(distanceText: String): Double {
        if (distanceText.isBlank()) return 0.0
        try {
            val lower = distanceText.lowercase().trim()
            
            // Check for explicit meters first (e.g. 500 m, 300m away, 800 meter)
            val meterRegex = Regex("""([0-9]+(?:\.[0-9]+)?)\s*(?:m|mtr|meter|meters)\b""", RegexOption.IGNORE_CASE)
            val meterMatch = meterRegex.find(lower)
            if (meterMatch != null && !lower.contains("km")) {
                val meters = meterMatch.groupValues[1].toDoubleOrNull() ?: 0.0
                if (meters > 0.0) {
                    return meters / 1000.0
                }
            }
            
            // Check for kilometers (e.g. 2.5 km, 9.5km, 10 kms)
            val kmRegex = Regex("""([0-9]+(?:\.[0-9]+)?)\s*(?:km|kms)\b""", RegexOption.IGNORE_CASE)
            val kmMatch = kmRegex.find(lower)
            if (kmMatch != null) {
                return kmMatch.groupValues[1].toDoubleOrNull() ?: 0.0
            }
            
            // Fallback: raw numeric sequence
            val fallbackMatch = Regex("""\b([0-9]+(?:\.[0-9]+)?)\b""").find(lower)
            if (fallbackMatch != null) {
                return fallbackMatch.groupValues[1].toDoubleOrNull() ?: 0.0
            }
        } catch (_: Exception) {}
        return 0.0
    }
}

