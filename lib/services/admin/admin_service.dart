import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class AdminService {
  // Singleton pattern
  static final AdminService _instance = AdminService._internal();

  factory AdminService() {
    return _instance;
  }

  AdminService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Get all users with a specific role
  Stream<QuerySnapshot> getUsersByRole(String role) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .snapshots();
  }

  /// Get all users (for admin dashboard)
  Stream<QuerySnapshot> getAllUsers() {
    return _firestore.collection('users').snapshots();
  }

  /// Check if a vendor document exists for a given user ID
  Future<bool> vendorDocumentExists(String uid) async {
    try {
      final doc = await _firestore.collection('vendors').doc(uid).get();
      return doc.exists;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AdminService.vendorDocumentExists error: $e');
      }
      return false;
    }
  }

  /// Update user email via Cloud Function (requires admin privileges)
  Future<void> updateUserEmail(String uid, String email) async {
    try {
      final callable = _functions.httpsCallable('adminSetUserEmail');
      final result = await callable.call({
        'uid': uid,
        'email': email,
      });

      if (kDebugMode) {
        debugPrint('AdminService.updateUserEmail result: ${result.data}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AdminService.updateUserEmail error: $e');
      }
      rethrow;
    }
  }

  /// Update user display name via Cloud Function (requires admin privileges)
  Future<void> updateUserDisplayName(String uid, String displayName) async {
    try {
      final callable = _functions.httpsCallable('adminSetUserDisplayName');
      final result = await callable.call({
        'uid': uid,
        'displayName': displayName,
      });

      if (kDebugMode) {
        debugPrint(
          'AdminService.updateUserDisplayName result: ${result.data}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AdminService.updateUserDisplayName error: $e');
      }
      rethrow;
    }
  }

  /// Set admin claim for a user (requires admin privileges or allowlist)
  Future<void> setAdminClaim(String uid, bool isAdmin) async {
    try {
      final callable = _functions.httpsCallable('adminSetAdminClaim');
      final result = await callable.call({
        'uid': uid,
        'isAdmin': isAdmin,
      });

      if (kDebugMode) {
        debugPrint('AdminService.setAdminClaim result: ${result.data}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AdminService.setAdminClaim error: $e');
      }
      rethrow;
    }
  }
}
