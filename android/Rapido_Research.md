# RAPIDO CAPTAIN APP - COMPLETE AUTO ACCEPT RESEARCH

## **DECOMPILATION STATUS**
✅ **Completed:** Rapido Captain APK decompiled successfully  
📁 **Location:** `e:\research\rapido_decompiled\`  
⚠️ **Errors:** 777 errors (normal for obfuscated apps)

---

## **1. ORDER DATA STRUCTURES**

### **1.1 OrderDetails Class (Completed Orders)**
**Location:** `com.rapido.rider.order.domain.models.OrderDetails`

```java
public final class OrderDetails {
    // Order Identification
    String orderId;                  // Unique order ID
    String uniqueId;                 // Alternative ID
    String status;                   // Order status
    String orderType;                // Type of ride
    
    // Financial Information
    double estimatedAmount;          // Estimated fare ⭐
    double amountToBePaid;           // Actual amount to pay ⭐
    String paymentStatus;            
    String paymentType;              
    
    // Distance Information
    double distanceToPickup;         // Distance from captain to pickup ⭐
    double pickUpToDropDistance;     // Ride distance ⭐
    
    // Address Information
    AddressInfo pickUpAddressInfo;   // Pickup location details ⭐
    AddressInfo dropAddressInfo;     // Drop location details ⭐
    
    // Nested AddressInfo class
    public static class AddressInfo {
        String address;
        String landmark;
        double latitude;
        double longitude;
        String locationName;
    }
}
```

### **1.2 PreOrder Class (Live/Incoming Orders)**
**Location:** `com.rapido.rider.preorder.domain.models.PreOrder`

```java
@Keep
public final class PreOrder {
    // Identification
    private String orderId;                    ⭐
    private String orderType;
    private String version;
    
    // Timing & Delays
    private int captainAcceptTimer;            // Countdown timer
    private int timeToEnableAcceptButton;      ⭐ IMPORTANT: Delay before button enabled
    private long orderAcceptanceWaitTimerInMs; // Wait timer
    private long orderCreated;
    private long acceptedAt;
    private long unavailableAt;
    
    // Amount & Distance
    private double amount;                     ⭐ Main fare
    private double pickupDropDistance;         ⭐ Ride distance  
    private double distanceToPickup;           ⭐ Distance to pickup
    private double pickupETA;                  // Time to pickup
    private double dropETA;                    // Time to drop
    private double firstMileIncentive;         // Extra earning
    private int orderTipAmount;                // Tip amount
    private double minutes;                    // Ride duration
    
    // Locations
    private Location pickLocation;             ⭐
    private Location dropLocation;             ⭐
    
    // Payment
    private String paymentType;
    
    // Order Properties
    private boolean isBatchedOrder;            // Batch delivery
    private boolean isPAPEnabled;              // Pre-assigned priority
    private boolean isOnRideBooking;           // ORB (order while on ride)
    private boolean isPreferredRoute;          
    private boolean isBatchable;
    private int batchOrderSize;
    private int orderRank;                     ⭐ Priority ranking
    private int priority;                      ⭐ Order priority
    
    // Service Details
    private String serviceDetailId;
    private String serviceName;
    private String serviceIconUrl;
    
    // Display & UI
    private OrderEarnings orderEarnings;       // Earnings breakdown
    private OrderPropagation propagation;      // Multi-captain broadcast
    private Header header;                     // UI header
    private Cta acceptCTA;                     ⭐ Accept button config
    private IncomingOrderDisplay incomingOrderDisplay;
    private ExclusivePingDisplay exclusivePingDisplay;
    private MultiStopJourney multiStopJourney;
    
    // Clustering
    private ClusterInformation clusterInformation;
    
    // Additional
    private TagDisplayProp bundleTag;
    private List<BundleItemInfo> bundleItemInfo;
    private AudioSegmentConfig audioSegmentConfig;
    private OrderFilter orderFilter;
}
```

---

## **2. RESOURCE IDs (R.java)**

### **2.1 Accept Button IDs**
**File:** `com.rapido.rider.R.java`

```java
// Button Resource IDs (R.id)
public static final int btnConsentAccept = 0x7f0a017e;                ⭐
public static final int ready_for_next_order_button = 0x7f0a0a2b;    ⭐

// Order View IDs
public static final int order_accept_time_tv = 0x7f0a094c;           ⭐ Timer display
public static final int order_card_view = 0x7f0a094d;                ⭐ Order card
public static final int order_count_title = 0x7f0a094e;
public static final int orderStatusLayout = 0x7f0a094a;
public static final int orderType = 0x7f0a094b;
```

### **2.2 Raw Resources (Audio/Animations)**
```java
// Auto-accept media files (R.raw)
public static final int auto_accept_order_loading = 0x7f130019;      // Loading animation
public static final int auto_accept_order_sound_loop = 0x7f13001a;   // Sound loop
```

### **2.3 String Resources (R.string)**
```java
// Auto-accept strings
public static final int autoaccept_order = 0x7f140266;
public static final int getting_autoaccept_order = 0x7f1405e3;
public static final int getting_autoaccept_order_notif = 0x7f1405e4;
public static final int getting_autoaccept_order_title = 0x7f1405e5;

// Accept button strings
public static final int accept_cta = 0x7f1401b6;
public static final int accept_ride = 0x7f1401b7;
public static final int accept_a_food_order = 0x7f1401b5;

// Notification strings
public static final int order_acceptance_notification_channel_id = 0x7f14098a;
public static final int order_acceptance_notification_channel_name = 0x7f14098b;
public static final int order_accepted = 0x7f14098c;
public static final int order_autoaccepted = 0x7f14098f;           ⭐

// UI strings
public static final int text_auto_accept_how_it_works_after_order_drop = 0x7f140e86;
public static final int text_auto_accept_how_it_works_when_on_order = 0x7f140e87;
public static final int hey_you_missed_an_order = 0x7f140633;
```

### **2.4 Drawable Resources**
```java
// Button backgrounds (R.drawable)
public static final int bg_yellow_border_button = 0x7f0802dc;
public static final int border_around_button = 0x7f08030a;
public static final int border_around_button_black = 0x7f08030b;
public static final int yellow_border_button_bg = 0x7f080bee;
```

---

## **3. AUTO-ACCEPT IMPLEMENTATION**

### **3.1 AutoAcceptOrderActivity**
**Location:** `com.rapido.rider.preorder.auto_accept.presentation.ui.AutoAcceptOrderActivity`

```java
public final class AutoAcceptOrderActivity extends BaseComposeActivity {
    
    public static final si2 Companion = new si2();
    public final Lazy ZgXc;  // State management
    public final Lazy cmmm;  // Synchronized lazy
    public final Lazy triO;  // Order ID holder
    
    public AutoAcceptOrderActivity() {
        // Gets order ID from intent
        this.triO = LazyKt.lazy(new Function0(this) {
            @Override
            public final Object invoke() {
                Intent intent2 = autoAcceptOrderActivity.getIntent();
                String orderId = intent2.getStringExtra(SharedPrefsConstants.ORDER_ID);
                return orderId != null ? orderId : "";
            }
        });
        
        // Gets ORB (On Ride Booking) flag
        this.ZgXc = LazyKt.lazy(cji.NONE, (Function0) new he0(this, new Function0(this) {
            @Override
            public final Object invoke() {
                Intent intent = autoAcceptOrderActivity.getIntent();
                boolean isOrb = intent.getBooleanExtra("is_orb", false);
                return new ifo(2, mv1.X(new Object[]{Boolean.valueOf(isOrb)}));
            }
        }, 5));
    }
}
```

### **3.2 PreOrderRepository Interface**
**Location:** `com.rapido.rider.preorder.domain.repository.PreOrderRepository`

```java
public interface PreOrderRepository {
    
    // Accept order asynchronously
    @Nullable
    Object acceptAsync(@NotNull String orderId, 
                      long acceptedAt, 
                      boolean useAcceptOrderResponse, 
                      @NotNull Continuation continuation);
    
    // Accept order synchronously  
    @Nullable
    Object acceptOrder(@NotNull String orderId, 
                      long acceptedAt, 
                      boolean useAcceptOrderResponse,
                      @NotNull Continuation continuation);
    
    // Reject order
    @Nullable
    Object rejectOrder(@NotNull String orderId, 
                      long rejectedAt,
                      @NotNull Continuation continuation);
}
```

### **3.3 Accept Button Delay Mechanism**
**File:** `com.rapido.proto.riderMessage.Check$BookingInfo`

```java
// Proto message field
public static final int TIMETOENABLEACCEPTBUTTON_FIELD_NUMBER = 23;
private int timeToEnableAcceptButton_;

public int getTimeToEnableAcceptButton() {
    return this.timeToEnableAcceptButton_;
}

private void setTimeToEnableAcceptButton(int i) {
    this.timeToEnableAcceptButton_ = i;
}
```

**Usage in SessionsSharedPrefs:**
```java
// File: com.rapido.rider.Utilities.bcmf
sessionsSharedPrefs.setMulticastEnabled(
    Boolean.valueOf(bookingInfo.hasPropagation())
);
sessionsSharedPrefs.setMulticastRiderCount(
    bookingInfo.getPropagation().getRiderCount()
);
sessionsSharedPrefs.setMulticastEnableAcceptDelay(
    bookingInfo.getTimeToEnableAcceptButton()    // ⭐ Accept delay
);
```

---

## **4. PORTER VS RAPIDO COMPARISON**

| Feature | Porter | Rapido | Winner |
|---------|--------|--------|--------|
| **Field Names** | Obfuscated (`f59546f`) | Clear (`estimatedAmount`) | ✅ Rapido |
| **Accept Delay** | ❌ Not found | ✅ `timeToEnableAcceptButton` | ✅ Rapido |
| **Order Priority** | ❌ No ranking | ✅ `orderRank`, `priority` | ✅ Rapido |
| **Batch Orders** | ❌ Not found | ✅ `isBatchedOrder` | ✅ Rapido |
| **ORB Support** | ❌ Not found | ✅ `isOnRideBooking` | ✅ Rapido |
| **Auto-Accept Activity** | ❌ Not found | ✅ AutoAcceptOrderActivity | ✅ Rapido |
| **UI Framework** | XML Views | Jetpack Compose | ⚠️ Compose harder |
| **Code Quality** | Heavily obfuscated | Mostly readable | ✅ Rapido |

### **Key Advantages - Rapido:**
1. ✅ **Accept delay field** - Know when button becomes clickable
2. ✅ **Priority ranking** - Can sort by importance
3. ✅ **Batch order support** - Handle multi-deliveries
4. ✅ **ORB detection** - Accept orders while on ride
5. ✅ **Clear data models** - Easy to parse

### **Challenges - Rapido:**
1. ⚠️ **Jetpack Compose UI** - Buttons may not have static IDs
2. ⚠️ **Accept delay** - Must wait before clicking
3. ⚠️ **Order ranking** - More complex sorting logic

---

## **5. AUTO-ACCEPT ALGORITHM FOR RAPIDO**

### **Complete Implementation Strategy:**

```java
// STEP 1: Monitor for incoming orders
public class RapidoAccessibilityService extends AccessibilityService {
    
    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        // Detect order notification or screen
        if (isOrderScreen(event)) {
            List<PreOrder> orders = extractOrders(event);
            processOrders(orders);
        }
    }
    
    // STEP 2: Extract & sort orders
    private void processOrders(List<PreOrder> orders) {
        // Get user preferences
        SharedPreferences prefs = getSharedPreferences("AutoAcceptSettings", MODE_PRIVATE);
        double maxDistance = prefs.getFloat("max_distance", 5.0);
        double minFare = prefs.getFloat("min_fare", 200.0);
        
        // Filter by distance & fare
        List<PreOrder> filtered = orders.stream()
            .filter(order -> order.getDistanceToPickup() <= maxDistance)
            .filter(order -> order.getAmount() >= minFare)
            .collect(Collectors.toList());
        
        // Sort by highest fare
        filtered.sort((o1, o2) -> {
            // Primary: Fare (descending)
            int fareCompare = Double.compare(o2.getAmount(), o1.getAmount());
            if (fareCompare != 0) return fareCompare;
            
            // Secondary: Distance to pickup (ascending)
            int distCompare = Double.compare(o1.getDistanceToPickup(), o2.getDistanceToPickup());
            if (distCompare != 0) return distCompare;
            
            // Tertiary: Priority (descending)
            return Integer.compare(o2.getPriority(), o1.getPriority());
        });
        
        // Get top order
        if (!filtered.isEmpty()) {
            PreOrder topOrder = filtered.get(0);
            acceptOrder(topOrder);
        }
    }
    
    // STEP 3: Accept order with delay
    private void acceptOrder(PreOrder order) {
        String orderId = order.getOrderId();
        int acceptDelay = order.getTimeToEnableAcceptButton();
        double fare = order.getAmount();
        double distance = order.getDistanceToPickup();
        
        Log.i("AutoAccept", "Accepting Order: " + orderId + 
              " | Fare: ₹" + fare + 
              " | Distance: " + distance + " km" +
              " | Delay: " + acceptDelay + " ms");
        
        // Wait for button to enable
        new Handler().postDelayed(() -> {
            clickAcceptButton(orderId);
        }, acceptDelay);
    }
    
    // STEP 4: Click accept button
    private void clickAcceptButton(String orderId) {
        AccessibilityNodeInfo rootNode = getRootInActiveWindow();
        if (rootNode == null) return;
        
        // Method 1: Find by resource ID
        List<AccessibilityNodeInfo> buttons = rootNode.findAccessibilityNodeInfosByViewId(
            "com.rapido.rider:id/btnConsentAccept"
        );
        
        if (buttons.isEmpty()) {
            // Method 2: Find by text
            buttons = rootNode.findAccessibilityNodeInfosByText("Accept");
        }
        
        if (buttons.isEmpty()) {
            // Method 3: Find order card, then find clickable child
            List<AccessibilityNodeInfo> cards = rootNode.findAccessibilityNodeInfosByViewId(
                "com.rapido.rider:id/order_card_view"
            );
            
            for (AccessibilityNodeInfo card : cards) {
                AccessibilityNodeInfo clickable = findClickableNode(card);
                if (clickable != null) {
                    clickable.performAction(AccessibilityNodeInfo.ACTION_CLICK);
                    return;
                }
            }
        } else {
            // Click first button found
            buttons.get(0).performAction(AccessibilityNodeInfo.ACTION_CLICK);
        }
    }
    
    // Helper: Find clickable node recursively
    private AccessibilityNodeInfo findClickableNode(AccessibilityNodeInfo node) {
        if (node == null) return null;
        
        if (node.isClickable()) return node;
        
        for (int i = 0; i < node.getChildCount(); i++) {
            AccessibilityNodeInfo child = node.getChild(i);
            AccessibilityNodeInfo found = findClickableNode(child);
            if (found != null) return found;
        }
        
        return null;
    }
}
```

---

## **6. DATA EXTRACTION EXAMPLE**

### **From OrderDetails (Completed Order):**
```java
OrderDetails order = getCurrentOrder();

// Financial
double estimatedFare = order.getEstimatedAmount();      // e.g., 250.0
double actualFare = order.getAmountToBePaid();          // e.g., 245.0

// Distance  
double pickupDist = order.getDistanceToPickup();        // e.g., 2.5 km
double rideDist = order.getPickUpToDropDistance();      // e.g., 8.3 km

// Location
String pickup = order.getPickUpAddressInfo().getAddress();
String drop = order.getDropAddressInfo().getAddress();
double pickupLat = order.getPickUpAddressInfo().getLatitude();
double pickupLng = order.getPickUpAddressInfo().getLongitude();

// Identification
String orderId = order.getOrderId();
String status = order.getStatus();
```

### **From PreOrder (Live Order):**
```java
PreOrder liveOrder = getIncomingOrder();

// Financial
double fare = liveOrder.getAmount();                    // e.g., 280.0
int tip = liveOrder.getOrderTipAmount();                // e.g., 20
double incentive = liveOrder.getFirstMileIncentive();   // e.g., 15.0

// Distance
double pickupDist = liveOrder.getDistanceToPickup();    // e.g., 1.8 km
double rideDist = liveOrder.getPickupDropDistance();    // e.g., 12.5 km

// Priority
int rank = liveOrder.getOrderRank();                    // e.g., 1 (highest)
int priority = liveOrder.getPriority();                 // e.g., 5

// Timing
int acceptTimer = liveOrder.getCaptainAcceptTimer();    // e.g., 30 seconds
int buttonDelay = liveOrder.getTimeToEnableAcceptButton(); // e.g., 3000 ms
double pickupETA = liveOrder.getPickupETA();            // e.g., 8.5 minutes

// Features
boolean isBatch = liveOrder.isBatchedOrder();           // true/false
boolean isORB = liveOrder.isOnRideBooking();            // true/false
boolean isPAP = liveOrder.isPAPEnabled();               // true/false

// Location
Location pickup = liveOrder.getPickLocation();
Location drop = liveOrder.getDropLocation();
```

---

## **7. SORTING & FILTERING LOGIC**

### **Multi-Factor Scoring System:**

```java
public class OrderScorer {
    
    public static double calculateScore(PreOrder order, UserPreferences prefs) {
        double score = 0.0;
        
        // Factor 1: Fare (40% weight)
        double fareScore = order.getAmount() / prefs.maxFare;
        score += fareScore * 0.40;
        
        // Factor 2: Distance efficiency (30% weight)
        double distanceEfficiency = 1.0 - (order.getDistanceToPickup() / prefs.maxDistance);
        score += distanceEfficiency * 0.30;
        
        // Factor 3: Fare per KM (20% weight)
        double farePerKm = order.getAmount() / order.getPickupDropDistance();
        double farePerKmScore = farePerKm / prefs.targetFarePerKm;
        score += farePerKmScore * 0.20;
        
        // Factor 4: Priority bonus (10% weight)
        if (order.isPAPEnabled()) score += 0.10;
        if (order.getOrderRank() == 1) score += 0.05;
        if (order.getFirstMileIncentive() > 0) score += 0.05;
        
        return score;
    }
    
    public static List<PreOrder> rankOrders(List<PreOrder> orders, UserPreferences prefs) {
        return orders.stream()
            .filter(order -> order.getAmount() >= prefs.minFare)
            .filter(order -> order.getDistanceToPickup() <= prefs.maxDistance)
            .sorted((o1, o2) -> Double.compare(
                calculateScore(o2, prefs), 
                calculateScore(o1, prefs)
            ))
            .collect(Collectors.toList());
    }
}
```

---

## **8. TESTING CHECKLIST**

### **Required Tests:**
- [ ] **Accept delay timing** - Verify button waits correct milliseconds
- [ ] **Order sorting** - Highest fare picked first
- [ ] **Distance filter** - Orders beyond limit rejected
- [ ] **Fare filter** - Orders below minimum rejected
- [ ] **Multiple orders** - Correct one selected from batch
- [ ] **ORB handling** - Orders accepted while on ride
- [ ] **Batch orders** - Multi-delivery handling
- [ ] **Priority orders** - PAP orders prioritized
- [ ] **Button ID detection** - Accept button found reliably
- [ ] **Compose UI handling** - Dynamic buttons clicked correctly

---

## **9. FILE LOCATIONS SUMMARY**

```
📁 e:\research\rapido_decompiled\sources\com\rapido\rider\
│
├── 📂 order\
│   └── domain\
│       └── models\
│           └── OrderDetails.java            ✅ Completed order data
│
├── 📂 preorder\
│   ├── domain\
│   │   ├── models\
│   │   │   └── PreOrder.java               ✅ Live order data
│   │   └── repository\
│   │       └── PreOrderRepository.java     ✅ Accept/reject methods
│   └── auto_accept\
│       └── presentation\
│           └── ui\
│               └── AutoAcceptOrderActivity.java  ✅ Auto-accept UI
│
├── 📂 proto\
│   └── riderMessage\
│       └── Check.java                       ✅ Accept delay proto
│
├── 📂 Utilities\
│   └── bcmf.java                           ✅ Accept delay usage
│
└── R.java                                   ✅ All resource IDs
```

---

## **10. RESEARCH STATUS**

| Task | Status | Notes |
|------|--------|-------|
| ✅ Decompile APK | Complete | 777 errors OK |
| ✅ Find OrderDetails | Complete | Documented |
| ✅ Find PreOrder | Complete | Documented |
| ✅ Find R.java IDs | Complete | All IDs extracted |
| ✅ Find Accept Button | Complete | Multiple IDs found |
| ✅ Find Accept Delay | Complete | `timeToEnableAcceptButton` |
| ✅ Find Repository | Complete | Accept methods found |
| ✅ Find Auto-Accept Activity | Complete | Documented |
| ⏳ Test on Device | Pending | Need real device |
| ⏳ Build Auto-Accept App | Pending | Next phase |

---

## **NEXT STEPS**

1. **Build accessibility service** with Rapido package targeting
2. **Implement order extraction** from Compose UI
3. **Add delay handling** for `timeToEnableAcceptButton`
4. **Create user preferences** for distance/fare filters
5. **Test with real orders** on device
6. **Handle edge cases** (batch, ORB, priority orders)

---

**RESEARCH COMPLETE** ✅  
**Porter + Rapido Documentation:** Ready for implementation phase
