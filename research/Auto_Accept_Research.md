# PORTER PARTNER APP - AUTO ACCEPT ORDER RESEARCH

## **AUTO ACCEPT APP KE LIYE KEY INFORMATION**

---

## **1. ORDER DATA STRUCTURE**

### **TrayOrder Entity** (`in/porter/allocation/mobile/journeys/trayjourney/domain/entities/TrayOrder.java`)

```java
class TrayOrder {
    String f59541a;              // Order ID
    String f59542b;              // Optional field
    String f59543c;              // Optional field
    TrayDryRun f59544d;          // Distance from current location
    TrayAddresses f59545e;       // Pickup & Drop addresses
    TrayDriverFare f59546f;      // Fare/Price information
    List<TrayVas> f59547g;       // VAS services (COD, POD, etc)
    String f59548h;              // Optional field
}
```

---

## **2. FARE/PRICE INFORMATION**

### **TrayDriverFare** (`TrayDriverFare.java`)

```java
class TrayDriverFare {
    String f59534a;              // Currency symbol (₹)
    TrayFareValue f59535b;       // Total fare object
    Double f59536c;              // Surge multiplier (optional)
}
```

### **Fare Value Structure:**
```java
TrayFareValue {
    double f59539b;              // Actual fare amount (e.g., 450.0)
}
```

### **Get Fare Amount:**
```java
double fareAmount = order.f59546f.f59535b.f59539b;
```

---

## **3. DISTANCE INFORMATION**

### **TrayDryRun** (`TrayDryRun.java`)

```java
class TrayDryRun {
    double f59537a;              // Distance in kilometers from current location
}
```

### **Get Distance:**
```java
double distanceKm = order.f59544d.f59537a;
```

---

## **4. ORDER CARD VIEW IDs**

### **Single Order Card:**
- **Container:** `R.id.acceptOrderCard` (CardView)
- **Accept Button:** `R.id.acceptOrderCard` (clickable)
- **Binding Class:** `d80.a5`

### **Order Details Inside Card:**
- **Fare:** `R.id.tvAmount` (BoldTextView)
- **Distance:** `R.id.dryRun` (TextView)
- **Pickup:** `R.id.tvPickUp` (RegularTextView)
- **Drop:** `R.id.tvDropAddress` (BoldTextView)

---

## **5. MULTIPLE ORDERS HANDLING**

### **Order Tray/List:**
Multiple orders are shown in a list/tray format using:
- Package: `in.porter.allocation.mobile.journeys.trayjourney`
- Component: `TrayOrderList` (Jetpack Compose)
- Each order is an `AnimatedTrayOrderItem`

### **Order Container:**
```
List<TrayOrder> orders
↓
Each TrayOrder shown in card
↓
User can see multiple orders simultaneously
```

---

## **6. AUTO ACCEPT LOGIC - SUGGESTIONS**

### **Step 1: Get All Orders**
```
1. Wait for order tray to open
2. Get all TrayOrder objects from the list
3. Extract data from each order
```

### **Step 2: Filter by Distance**
```java
// User sets max distance (e.g., 5 km)
double maxDistance = 5.0;

List<TrayOrder> filteredOrders = orders.stream()
    .filter(order -> order.f59544d != null && 
                     order.f59544d.f59537a <= maxDistance)
    .collect(Collectors.toList());
```

### **Step 3: Sort by Fare (Highest First)**
```java
filteredOrders.sort((order1, order2) -> {
    double fare1 = order1.f59546f.f59535b.f59539b;
    double fare2 = order2.f59546f.f59535b.f59539b;
    return Double.compare(fare2, fare1);  // Descending order
});
```

### **Step 4: Get Highest Fare Order**
```java
TrayOrder bestOrder = filteredOrders.get(0);
String orderId = bestOrder.f59541a;
double fare = bestOrder.f59546f.f59535b.f59539b;
double distance = bestOrder.f59544d.f59537a;
```

### **Step 5: Click Accept Button**
```
1. Find card view for bestOrder
2. Perform click on acceptOrderCard
3. Wait for acceptance confirmation
```

---

## **7. ACCESSIBILITY SERVICE APPROACH**

### **For Auto Accept App:**

```java
// Pseudo code for Accessibility Service

onAccessibilityEvent(AccessibilityEvent event) {
    if (event.getClassName().contains("TrayOrder")) {
        // Orders list opened
        
        List<AccessibilityNodeInfo> orderCards = 
            findViewsByResourceId("acceptOrderCard");
        
        List<OrderData> orders = new ArrayList<>();
        
        for (AccessibilityNodeInfo card : orderCards) {
            // Extract fare
            AccessibilityNodeInfo fareView = 
                card.findViewByResourceId("tvAmount");
            String fareText = fareView.getText().toString();
            double fare = parseFare(fareText);
            
            // Extract distance
            AccessibilityNodeInfo distView = 
                card.findViewByResourceId("dryRun");
            String distText = distView.getText().toString();
            double distance = parseDistance(distText);
            
            orders.add(new OrderData(card, fare, distance));
        }
        
        // Filter by user's max distance
        orders = orders.stream()
            .filter(o -> o.distance <= userMaxDistance)
            .collect(Collectors.toList());
        
        // Sort by fare (highest first)
        orders.sort((o1, o2) -> 
            Double.compare(o2.fare, o1.fare));
        
        // Click highest fare order
        if (!orders.isEmpty()) {
            OrderData best = orders.get(0);
            best.cardNode.performAction(
                AccessibilityNodeInfo.ACTION_CLICK);
        }
    }
}
```

---

## **8. KEY RESOURCE IDs FOR EXTRACTION**

| Data | Resource ID | Type | Parsing |
|------|-------------|------|---------|
| Fare Amount | `R.id.tvAmount` | BoldTextView | Remove ₹, parse double |
| Distance | `R.id.dryRun` | TextView | Extract km value |
| Pickup | `R.id.tvPickUp` | RegularTextView | String |
| Drop | `R.id.tvDropAddress` | BoldTextView | String |
| Order ID | Internal | N/A | From TrayOrder object |

---

## **9. PARSING EXAMPLES**

### **Parse Fare:**
```java
// Text: "₹450" or "₹450.50"
String fareText = "₹450";
fareText = fareText.replace("₹", "").trim();
double fare = Double.parseDouble(fareText);
```

### **Parse Distance:**
```java
// Text: "2.5 km away" or "3 km"
String distText = "2.5 km away";
distText = distText.replaceAll("[^0-9.]", "").trim();
double distance = Double.parseDouble(distText);
```

---

## **10. SURGE ORDERS**

### **Detect Surge:**
```java
boolean isSurge = order.f59546f.f59536c != null;
double surgeMultiplier = order.f59546f.f59536c; // e.g., 1.5x
```

### **Priority for Surge:**
```java
// Optional: Give higher priority to surge orders
if (isSurge) {
    fare *= 1.2; // Boost priority by 20%
}
```

---

## **11. ACCEPTANCE FLOW**

```
User Opens App
↓
Orders appear in tray (TrayOrderList)
↓
Auto Accept Service detects orders
↓
Extract fare & distance from each order
↓
Filter by max distance (user setting)
↓
Sort by fare (highest first)
↓
Click accept on highest fare order
↓
Wait for confirmation
↓
Repeat for next order if needed
```

---

## **12. USER SETTINGS (App Should Have)**

```
1. Max Distance (km): [User Input] (e.g., 5 km)
2. Min Fare (₹): [User Input] (e.g., ₹200)
3. Auto Accept: [ON/OFF toggle]
4. Priority: [Fare/Distance/Mixed]
5. Exclude Areas: [List of areas to avoid]
```

---

## **13. IMPORTANT FILES REFERENCE**

| File | Purpose |
|------|---------|
| `TrayOrder.java` | Order data model |
| `TrayDriverFare.java` | Fare information |
| `TrayDryRun.java` | Distance from current location |
| `d80/a5.java` | Accept card binding |
| `d80/p0.java` | Order details binding |
| `ParallelAcceptOrderView.java` | Single order view |

---

## **14. SORTING ALGORITHM**

### **Method 1: Highest Fare Only**
```java
orders.sort((o1, o2) -> 
    Double.compare(
        o2.f59546f.f59535b.f59539b,
        o1.f59546f.f59535b.f59539b
    ));
```

### **Method 2: Fare per KM (Efficiency)**
```java
orders.sort((o1, o2) -> {
    double fare1 = o1.f59546f.f59535b.f59539b;
    double dist1 = o1.f59544d.f59537a;
    double farePerKm1 = fare1 / dist1;
    
    double fare2 = o2.f59546f.f59535b.f59539b;
    double dist2 = o2.f59544d.f59537a;
    double farePerKm2 = fare2 / dist2;
    
    return Double.compare(farePerKm2, farePerKm1);
});
```

### **Method 3: Weighted Score**
```java
double getScore(TrayOrder order, double weightFare, double weightDist) {
    double fare = order.f59546f.f59535b.f59539b;
    double distance = order.f59544d.f59537a;
    
    // Normalize and weight
    double fareScore = fare * weightFare;
    double distScore = (10 - distance) * weightDist; // Closer = higher
    
    return fareScore + distScore;
}

// Sort by score
orders.sort((o1, o2) -> 
    Double.compare(getScore(o2, 0.7, 0.3), 
                   getScore(o1, 0.7, 0.3)));
```

---

## **15. TESTING SCENARIOS**

```
Test 1: Single order - should accept
Test 2: Multiple orders - accept highest fare
Test 3: All orders > max distance - accept none
Test 4: Mixed distances - filter then accept
Test 5: Same fare, different distance - accept closer
Test 6: Surge order present - accept surge if higher
```

---

## **SUMMARY FOR AUTO ACCEPT APP:**

1. **Get all orders** from TrayOrder list
2. **Extract fare** from `f59546f.f59535b.f59539b`
3. **Extract distance** from `f59544d.f59537a`
4. **Filter** by user's max distance setting
5. **Sort** by fare (highest first)
6. **Click** accept button on best order
7. **Repeat** if multiple accepts allowed

---

**END OF DOCUMENT**
