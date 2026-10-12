# RAPIDO CAPTAIN APP - AUTO ACCEPT ORDER RESEARCH

## **AUTO ACCEPT APP KE LIYE KEY INFORMATION**

---

## **1. APP DETAILS**

- **Package Name:** `com.rapido.passenger`
- **App Type:** Bike Taxi Service
- **Target:** Rapido Captain (Driver App)
- **Platform:** Android

---

## **2. ORDER NOTIFICATION STRUCTURE**

### **Incoming Order Flow:**
```
Order Arrives
↓
Notification shows
↓
Order card appears with timer
↓
Driver has 15-20 seconds to accept
↓
Accept/Reject buttons
```

---

## **3. ORDER CARD VIEW IDs (Common Patterns)**

### **Order Card Container:**
- **Main Card:** `order_card` / `ride_request_card` / `incoming_order_layout`
- **Accept Button:** `btn_accept` / `accept_button` / `acceptRide`
- **Reject Button:** `btn_reject` / `reject_button` / `rejectRide`

### **Order Details:**
- **Fare Amount:** `tv_fare` / `fare_amount` / `ride_fare_text`
- **Pickup Distance:** `tv_pickup_distance` / `distance_text` / `pickup_km`
- **Pickup Address:** `tv_pickup_address` / `pickup_location_text`
- **Drop Address:** `tv_drop_address` / `drop_location_text`
- **Timer:** `timer_text` / `countdown_timer`

---

## **4. ORDER DATA EXTRACTION**

### **Fare Information:**
```
Display Format: "₹150" or "₹150.00"
Location: TextView with id containing "fare"
Parsing: Remove ₹ symbol, parse to double
```

### **Distance Information:**
```
Display Format: "2.5 km" or "2.5km away"
Location: TextView with id containing "distance" or "pickup"
Parsing: Extract numeric value before "km"
```

### **Address Information:**
```
Pickup: Full address string
Drop: Full address string
Format: "Area Name, Locality, City"
```

---

## **5. ACCESSIBILITY SERVICE IDs**

### **Common Resource ID Patterns:**
```
Fare: 
- tv_fare_amount
- fare_text
- ride_fare
- amount_text

Distance:
- tv_distance
- pickup_distance
- distance_from_pickup
- km_away_text

Accept Button:
- btn_accept
- accept_ride_button
- confirmButton
- positiveButton

Order Card:
- order_card_container
- ride_request_layout
- incoming_order_card
- request_card
```

---

## **6. AUTO ACCEPT LOGIC**

### **Detection:**
```kotlin
fun detectRapidoOrder(rootNode: AccessibilityNodeInfo): Boolean {
    // Check for Rapido package
    if (packageName != "com.rapido.passenger") return false
    
    // Look for order card indicators
    val hasOrderCard = findNodeById(rootNode, "order_card") != null
    val hasAcceptButton = findNodeById(rootNode, "btn_accept") != null
    val hasFare = findNodeById(rootNode, "tv_fare") != null
    
    return hasOrderCard && hasAcceptButton && hasFare
}
```

### **Extraction:**
```kotlin
fun extractRapidoOrderData(rootNode: AccessibilityNodeInfo): OrderData? {
    // Extract fare
    val fareNode = findNodeById(rootNode, "tv_fare") 
                   ?: findNodeByText(rootNode, "₹")
    val fareText = fareNode?.text?.toString() ?: return null
    val fare = parseFare(fareText) // "₹150" -> 150.0
    
    // Extract distance
    val distNode = findNodeById(rootNode, "tv_distance")
                   ?: findNodeByText(rootNode, "km")
    val distText = distNode?.text?.toString() ?: "0 km"
    val distance = parseDistance(distText) // "2.5 km" -> 2.5
    
    // Extract addresses
    val pickupNode = findNodeById(rootNode, "tv_pickup_address")
    val dropNode = findNodeById(rootNode, "tv_drop_address")
    val pickup = pickupNode?.text?.toString() ?: ""
    val drop = dropNode?.text?.toString() ?: ""
    
    return OrderData(fare, distance, pickup, drop)
}
```

### **Accept Order:**
```kotlin
fun acceptRapidoOrder(rootNode: AccessibilityNodeInfo): Boolean {
    val acceptButton = findNodeById(rootNode, "btn_accept")
                      ?: findNodeByText(rootNode, "Accept")
                      ?: return false
    
    // Ensure button is clickable
    if (!acceptButton.isClickable) return false
    
    // Perform click
    return acceptButton.performAction(AccessibilityNodeInfo.ACTION_CLICK)
}
```

---

## **7. FILTERING LOGIC**

### **User Settings:**
```kotlin
data class RapidoSettings(
    val minFare: Double,        // Minimum fare (₹)
    val maxFare: Double,        // Maximum fare (₹)
    val maxPickupDistance: Double,  // Max pickup distance (km)
    val maxTripDistance: Double,    // Max trip distance (km)
    val autoAccept: Boolean,    // Enable/disable auto accept
    val acceptCash: Boolean,    // Accept cash payments
    val acceptOnline: Boolean   // Accept online payments
)
```

### **Filter Order:**
```kotlin
fun shouldAcceptOrder(
    orderData: OrderData,
    settings: RapidoSettings
): Boolean {
    // Check fare range
    if (orderData.fare < settings.minFare) return false
    if (orderData.fare > settings.maxFare) return false
    
    // Check pickup distance
    if (orderData.pickupDistance > settings.maxPickupDistance) return false
    
    // Check trip distance (if available)
    if (orderData.tripDistance > settings.maxTripDistance) return false
    
    // Check payment method (if detectable)
    // ...
    
    return true
}
```

---

## **8. COMPLETE FLOW**

```
┌─────────────────────────────────────┐
│ Rapido Order Arrives                │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ Accessibility Service Detects       │
│ - Package: com.rapido.passenger     │
│ - View: Order Card Visible          │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ Extract Order Data                  │
│ - Fare: ₹150                        │
│ - Distance: 2.5 km                  │
│ - Pickup: Location A                │
│ - Drop: Location B                  │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ Check User Settings                 │
│ - Min Fare: ₹100 ✓                  │
│ - Max Fare: ₹500 ✓                  │
│ - Max Distance: 5 km ✓              │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ Auto Accept                         │
│ - Click "Accept" button             │
│ - Wait for confirmation             │
└─────────────────────────────────────┘
```

---

## **9. PARSING FUNCTIONS**

### **Parse Fare:**
```kotlin
fun parseFare(text: String): Double {
    // Input: "₹150" or "₹150.00" or "150"
    return text
        .replace("₹", "")
        .replace(",", "")
        .trim()
        .toDoubleOrNull() ?: 0.0
}
```

### **Parse Distance:**
```kotlin
fun parseDistance(text: String): Double {
    // Input: "2.5 km" or "2.5km away" or "3 km"
    val match = Regex("(\\d+\\.?\\d*)").find(text)
    return match?.value?.toDoubleOrNull() ?: 0.0
}
```

### **Parse Address:**
```kotlin
fun parseAddress(text: String): String {
    // Clean up address text
    return text.trim()
}
```

---

## **10. RESOURCE ID DISCOVERY**

### **Method 1: Using Layout Inspector**
1. Connect device with Rapido app open
2. Open Android Studio → Layout Inspector
3. Inspect order card views
4. Note down all resource IDs

### **Method 2: Using Accessibility Inspector**
```kotlin
fun logAllViewIds(node: AccessibilityNodeInfo, prefix: String = "") {
    val viewId = node.viewIdResourceName
    val className = node.className
    val text = node.text
    
    Log.d("Rapido", "$prefix ID: $viewId, Class: $className, Text: $text")
    
    for (i in 0 until node.childCount) {
        logAllViewIds(node.getChild(i), "$prefix  ")
    }
}
```

### **Method 3: APK Decompilation**
```bash
# Use jadx or apktool to decompile
jadx rapido.apk
# Search for layout XMLs and view IDs
```

---

## **11. FALLBACK STRATEGIES**

### **If Resource IDs Don't Work:**

#### **Strategy 1: Text-based Detection**
```kotlin
fun findByText(rootNode: AccessibilityNodeInfo, searchText: String): AccessibilityNodeInfo? {
    if (rootNode.text?.contains(searchText, ignoreCase = true) == true) {
        return rootNode
    }
    for (i in 0 until rootNode.childCount) {
        val found = findByText(rootNode.getChild(i), searchText)
        if (found != null) return found
    }
    return null
}

// Usage
val fareNode = findByText(rootNode, "₹")
val acceptButton = findByText(rootNode, "Accept")
```

#### **Strategy 2: Position-based Detection**
```kotlin
// Assume fare is always in top-right
// Accept button is always at bottom
fun findByPosition(rootNode: AccessibilityNodeInfo): Pair<View?, View?> {
    val allViews = getAllViews(rootNode)
    val fareView = allViews.filter { it.text?.contains("₹") == true }
                           .maxByOrNull { it.boundsInScreen.top }
    val acceptButton = allViews.filter { it.className == "Button" }
                              .filter { it.text?.contains("Accept") == true }
                              .minByOrNull { it.boundsInScreen.top }
    return Pair(fareView, acceptButton)
}
```

#### **Strategy 3: Class-based Detection**
```kotlin
fun findButtonByClass(rootNode: AccessibilityNodeInfo): AccessibilityNodeInfo? {
    if (rootNode.className == "android.widget.Button" && 
        rootNode.isClickable) {
        return rootNode
    }
    for (i in 0 until rootNode.childCount) {
        val found = findButtonByClass(rootNode.getChild(i))
        if (found != null) return found
    }
    return null
}
```

---

## **12. ERROR HANDLING**

### **Common Issues:**

1. **Order Already Accepted:**
```kotlin
fun isOrderAlreadyAccepted(rootNode: AccessibilityNodeInfo): Boolean {
    val statusNode = findByText(rootNode, "Accepted") 
                     ?: findByText(rootNode, "Ride Started")
    return statusNode != null
}
```

2. **Order Expired:**
```kotlin
fun isOrderExpired(rootNode: AccessibilityNodeInfo): Boolean {
    val expiredNode = findByText(rootNode, "Expired")
                      ?: findByText(rootNode, "Missed")
    return expiredNode != null
}
```

3. **Network Error:**
```kotlin
fun isNetworkError(rootNode: AccessibilityNodeInfo): Boolean {
    val errorNode = findByText(rootNode, "No internet")
                    ?: findByText(rootNode, "Connection lost")
    return errorNode != null
}
```

---

## **13. TESTING CHECKLIST**

```
□ Detect incoming order notification
□ Extract fare correctly
□ Extract distance correctly
□ Extract pickup/drop addresses
□ Filter by minimum fare
□ Filter by maximum fare
□ Filter by pickup distance
□ Auto-click accept button
□ Handle order expiry
□ Handle network errors
□ Handle already accepted orders
□ Test with multiple rapid orders
□ Test with different fare amounts
□ Test with different distances
```

---

## **14. SAMPLE ORDER DATA**

### **Example 1: Short Distance**
```
Fare: ₹80
Pickup Distance: 1.2 km
Trip Distance: 3.5 km
Pickup: MG Road, Bangalore
Drop: Indiranagar, Bangalore
Payment: Cash
```

### **Example 2: Long Distance**
```
Fare: ₹250
Pickup Distance: 4.5 km
Trip Distance: 15 km
Pickup: Koramangala, Bangalore
Drop: Whitefield, Bangalore
Payment: Online
```

### **Example 3: High Fare**
```
Fare: ₹450
Pickup Distance: 2.0 km
Trip Distance: 25 km
Pickup: Electronic City, Bangalore
Drop: Airport, Bangalore
Payment: Online
```

---

## **15. PRIORITY SETTINGS**

### **Sort Orders By:**

1. **Highest Fare First:**
```kotlin
orders.sortByDescending { it.fare }
```

2. **Closest Pickup First:**
```kotlin
orders.sortBy { it.pickupDistance }
```

3. **Best Fare Per KM:**
```kotlin
orders.sortByDescending { it.fare / it.tripDistance }
```

4. **Weighted Score:**
```kotlin
fun calculateScore(order: OrderData): Double {
    val fareWeight = 0.7
    val distanceWeight = 0.3
    val fareScore = order.fare / 500.0 // Normalize to 0-1
    val distScore = (10.0 - order.pickupDistance) / 10.0 // Closer = better
    return (fareScore * fareWeight) + (distScore * distanceWeight)
}

orders.sortByDescending { calculateScore(it) }
```

---

## **IMPLEMENTATION SUMMARY**

### **For Rapido Parser:**

```kotlin
class RapidoOrderParser : OrderParser {
    override fun detectAndAcceptOrder(
        rootNode: AccessibilityNodeInfo,
        settings: ServiceSettings
    ): Boolean {
        // 1. Detect Rapido order
        if (!isRapidoOrder(rootNode)) return false
        
        // 2. Extract order data
        val orderData = extractOrderData(rootNode) ?: return false
        
        // 3. Check filters
        if (!shouldAccept(orderData, settings)) return false
        
        // 4. Click accept
        return clickAcceptButton(rootNode)
    }
    
    private fun isRapidoOrder(node: AccessibilityNodeInfo): Boolean {
        // Check for order indicators
        return hasOrderCard(node) && hasAcceptButton(node)
    }
    
    private fun extractOrderData(node: AccessibilityNodeInfo): OrderData? {
        val fare = extractFare(node) ?: return null
        val distance = extractDistance(node)
        val pickup = extractPickupAddress(node)
        val drop = extractDropAddress(node)
        return OrderData(fare, distance, pickup, drop)
    }
    
    private fun shouldAccept(
        data: OrderData,
        settings: ServiceSettings
    ): Boolean {
        val filters = settings.rideFilters
        return data.fare >= filters.minFare &&
               data.fare <= filters.maxFare &&
               data.pickupDistance <= filters.pickupDistance &&
               data.tripDistance <= filters.tripDistance
    }
    
    private fun clickAcceptButton(node: AccessibilityNodeInfo): Boolean {
        val acceptButton = findAcceptButton(node) ?: return false
        return acceptButton.performAction(ACTION_CLICK)
    }
}
```

---

**END OF DOCUMENT**

**Note:** Actual resource IDs need to be discovered using Layout Inspector or by testing with live Rapido app. This document provides the framework and common patterns for implementation.
