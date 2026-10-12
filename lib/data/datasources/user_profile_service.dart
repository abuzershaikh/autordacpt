import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/utils/logger.dart';
import 'device_info_service.dart';
import 'telemetry_service.dart';

class UserPlanInfo {
  final String planId;
  final String planName;
  final num amount;
  final String status;
  final DateTime? purchasedAt;
  final DateTime? expiresAt;
  final String? paymentId;

  const UserPlanInfo({
    required this.planId,
    required this.planName,
    required this.amount,
    required this.status,
    this.purchasedAt,
    this.expiresAt,
    this.paymentId,
  });

  bool get isActive {
    if (status != 'active') return false;
    if (planId == 'lifetime') return true;
    if (expiresAt == null) return false;
    return expiresAt!.isAfter(DateTime.now());
  }

  factory UserPlanInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const UserPlanInfo(
        planId: 'none',
        planName: 'No Active Plan',
        amount: 0,
        status: 'inactive',
      );
    }

    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return UserPlanInfo(
      planId: map['planId'] ?? 'none',
      planName: map['planName'] ?? 'No Active Plan',
      amount: map['amount'] ?? 0,
      status: map['status'] ?? 'inactive',
      purchasedAt: parseDate(map['purchasedAt']),
      expiresAt: parseDate(map['expiresAt']),
      paymentId: map['paymentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'planName': planName,
      'amount': amount,
      'status': status,
      'purchasedAt': purchasedAt != null ? Timestamp.fromDate(purchasedAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'paymentId': paymentId,
    };
  }
}

class UserProfileData {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String phoneNumber;
  final String deviceBrand;
  final String deviceModel;
  final String androidVersion;
  final UserPlanInfo activePlan;
  final DateTime? updatedAt;

  const UserProfileData({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.phoneNumber,
    required this.deviceBrand,
    required this.deviceModel,
    required this.androidVersion,
    required this.activePlan,
    this.updatedAt,
  });

  factory UserProfileData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfileData(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      phoneNumber: data['phoneNumber'] ?? '',
      deviceBrand: data['deviceBrand'] ?? 'Unknown',
      deviceModel: data['deviceModel'] ?? 'Unknown',
      androidVersion: data['androidVersion'] ?? 'Unknown',
      activePlan: UserPlanInfo.fromMap(data['activePlan'] as Map<String, dynamic>?),
      updatedAt: data['updatedAt'] is Timestamp ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }
}

class UserProfileService {
  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference? get _usersCollection {
    final fs = _firestore;
    return fs?.collection('users');
  }

  /// Listen to user profile real-time
  Stream<UserProfileData?> streamUserProfile(String uid) {
    final col = _usersCollection;
    if (col == null) {
      return Stream.value(null);
    }
    return col.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return UserProfileData.fromFirestore(snapshot);
    });
  }

  /// Get single user profile (with local fallback)
  Future<UserProfileData?> getUserProfile(String uid) async {
    try {
      final col = _usersCollection;
      if (col != null) {
        final doc = await col.doc(uid).get();
        if (doc.exists) {
          return UserProfileData.fromFirestore(doc);
        }
      }
    } catch (e) {
      Logger.error('Firestore not available, checking local storage', error: e);
    }

    // Local SharedPreferences fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('user_phone_$uid') ?? prefs.getString('user_phone') ?? '';
      final brand = prefs.getString('user_device_brand') ?? 'Samsung';
      final model = prefs.getString('user_device_model') ?? 'SM-M145F';
      final androidVer = prefs.getString('user_device_android') ?? '15';
      final planId = prefs.getString('user_plan_id') ?? 'none';
      final planName = prefs.getString('user_plan_name') ?? 'No Active Plan';
      final planStatus = prefs.getString('user_plan_status') ?? 'inactive';

      if (phone.isNotEmpty || brand.isNotEmpty) {
        return UserProfileData(
          uid: uid,
          email: '',
          displayName: 'Driver Partner',
          phoneNumber: phone,
          deviceBrand: brand,
          deviceModel: model,
          androidVersion: androidVer,
          activePlan: UserPlanInfo(
            planId: planId,
            planName: planName,
            amount: 0,
            status: planStatus,
          ),
        );
      }
    } catch (_) {}

    return null;
  }

  /// Save or update user profile with phone number and device info
  Future<bool> saveUserProfile({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
    required String phoneNumber,
    required DeviceDetails deviceDetails,
  }) async {
    // 1. Always save locally to SharedPreferences first
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_phone_$uid', phoneNumber.trim());
      await prefs.setString('user_phone', phoneNumber.trim());
      await prefs.setString('user_device_brand', deviceDetails.brand);
      await prefs.setString('user_device_model', deviceDetails.model);
      await prefs.setString('user_device_android', deviceDetails.androidVersion);
      await prefs.setString('user_display_name', displayName);
    } catch (e) {
      Logger.error('Failed to save to local preferences: $e');
    }

    // 2. Sync to Cloud Firestore if connected
    try {
      final col = _usersCollection;
      if (col != null) {
        final userDocRef = col.doc(uid);
        final existing = await userDocRef.get();

        final Map<String, dynamic> updateData = {
          'uid': uid,
          'email': email,
          'displayName': displayName,
          'photoUrl': photoUrl,
          'phoneNumber': phoneNumber.trim(),
          'deviceBrand': deviceDetails.brand,
          'deviceModel': deviceDetails.model,
          'deviceManufacturer': deviceDetails.manufacturer,
          'androidVersion': deviceDetails.androidVersion,
          'sdkInt': deviceDetails.sdkInt,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (!existing.exists) {
          updateData['createdAt'] = FieldValue.serverTimestamp();
          updateData['activePlan'] = const UserPlanInfo(
            planId: 'free',
            planName: 'Free Trial',
            amount: 0,
            status: 'inactive',
          ).toMap();
        }

        await userDocRef.set(updateData, SetOptions(merge: true));
        Logger.success('User profile synced to Cloud Firestore for uid: $uid');
      }
      // 3. Trigger telemetry heartbeat to VPS so MySQL gets the phone number & device info
      try {
        TelemetryService().sendHeartbeat();
      } catch (_) {}

      return true;
    } catch (e) {
      Logger.error('Cloud Firestore sync pending (saved locally): $e');
      try {
        TelemetryService().sendHeartbeat();
      } catch (_) {}
      return true; // Still true since saved locally!
    }
  }

  /// Ensure a Firestore document exists immediately upon Google sign-in
  Future<void> ensureUserDocumentExists(User user) async {
    try {
      final col = _usersCollection;
      if (col != null) {
        final docRef = col.doc(user.uid);
        final doc = await docRef.get();
        if (!doc.exists) {
          final deviceInfo = DeviceInfoService();
          final device = await deviceInfo.getDeviceDetails();
          await docRef.set({
            'uid': user.uid,
            'email': user.email ?? '',
            'displayName': (user.displayName != null && user.displayName!.trim().isNotEmpty)
                ? user.displayName!.trim()
                : 'Driver Partner',
            'photoUrl': user.photoURL,
            'phoneNumber': user.phoneNumber ?? '',
            'deviceBrand': device.brand,
            'deviceModel': device.model,
            'androidVersion': device.androidVersion,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'activePlan': const UserPlanInfo(
              planId: 'free',
              planName: 'Free Trial',
              amount: 0,
              status: 'inactive',
            ).toMap(),
          }, SetOptions(merge: true));
          Logger.success('✓ Created initial Firestore document for ${user.uid}');
        }
      }
    } catch (e) {
      Logger.error('Failed to ensure initial Firestore document: $e');
    }
  }

  /// Activate or update a subscription plan after payment
  Future<bool> activateSubscriptionPlan({
    required String uid,
    required String planId,
    required String planName,
    required num amount,
    required String paymentId,
    required int validityDays, // -1 for lifetime
  }) async {
    final now = DateTime.now();
    final DateTime? expiresAt = validityDays > 0 ? now.add(Duration(days: validityDays)) : null;

    // 1. Save plan locally
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_plan_id', planId);
      await prefs.setString('user_plan_name', planName);
      await prefs.setString('user_plan_status', 'active');
      if (expiresAt != null) {
        await prefs.setString('user_plan_expires', expiresAt.toIso8601String());
      }
    } catch (_) {}

    // 2. Save plan to Firestore if available
    try {
      final col = _usersCollection;
      if (col != null) {
        final planInfo = UserPlanInfo(
          planId: planId,
          planName: planName,
          amount: amount,
          status: 'active',
          purchasedAt: now,
          expiresAt: expiresAt,
          paymentId: paymentId,
        );

        final userDocRef = col.doc(uid);

        await userDocRef.update({
          'activePlan': planInfo.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await userDocRef.collection('payments').doc(paymentId).set({
          'paymentId': paymentId,
          'planId': planId,
          'planName': planName,
          'amount': amount,
          'currency': 'INR',
          'purchasedAt': FieldValue.serverTimestamp(),
          'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
          'status': 'success',
        });

        Logger.success('Plan $planName activated for user: $uid in Firestore');
      }
      return true;
    } catch (e) {
      Logger.error('Failed to activate plan in Firestore, active locally: $e');
      return true;
    }
  }
}
