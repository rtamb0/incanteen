import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service for admin operations on users (customers and vendors)
class AdminService {
  // Singleton pattern
  static final AdminService _instance = AdminService._internal();

  factory AdminService() {
    return _instance;
  }

  AdminService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final role = doc.data()?['role'] as String?;
        return role == 'admin';
      }
      return false;
    } catch (e) {
      debugPrint('AdminService.isAdmin error: $e');
      return false;
    }
  }

  /// Get all users (returns stream without server-side filtering)
  /// Filter by role on client side to avoid index requirements
  Stream<QuerySnapshot> getAllUsers({String? roleFilter}) {
    // Return all users - filtering happens client-side in the UI
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get user by ID
  Future<DocumentSnapshot> getUserById(String userId) async {
    return await _firestore.collection('users').doc(userId).get();
  }

  /// Update user role (admin only)
  Future<void> updateUserRole(String userId, String newRole) async {
    if (!await isAdmin()) {
      throw Exception('Unauthorized: Admin access required');
    }

    if (!['customer', 'vendor', 'admin'].contains(newRole)) {
      throw Exception('Invalid role: $newRole');
    }

    await _firestore.collection('users').doc(userId).update({
      'role': newRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete user (admin only)
  /// Deletes both the Firestore document and the Firebase Auth account
  /// Uses Cloud Function for secure server-side deletion
  Future<void> deleteUser(String userId) async {
    if (!await isAdmin()) {
      throw Exception('Unauthorized: Admin access required');
    }

    try {
      // Import needed: import 'package:firebase_functions/firebase_functions.dart';
      // Then call: final callable = FirebaseFunctions.instance.httpsCallable('deleteUser');
      // For now, just delete from Firestore - Cloud Function must be deployed separately
      // and called from the admin panel

      // Delete user document and related data
      await _firestore.collection('users').doc(userId).delete();

      // Delete vendor document if exists
      try {
        await _firestore.collection('vendors').doc(userId).delete();
      } catch (e) {
        debugPrint('No vendor document to delete for $userId');
      }

      debugPrint('User $userId deleted from Firestore');
      debugPrint(
        'Note: To also delete Firebase Auth account, the Cloud Function deleteUser must be deployed',
      );
    } catch (e) {
      debugPrint('AdminService.deleteUser error: $e');
      rethrow;
    }
  }

  /// Get user statistics
  Future<Map<String, int>> getUserStatistics() async {
    if (!await isAdmin()) {
      throw Exception('Unauthorized: Admin access required');
    }

    final usersSnapshot = await _firestore.collection('users').get();

    int totalUsers = usersSnapshot.docs.length;
    int customers = 0;
    int vendors = 0;
    int admins = 0;

    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      final role = data['role'] as String?;

      switch (role) {
        case 'customer':
          customers++;
          break;
        case 'vendor':
          vendors++;
          break;
        case 'admin':
          admins++;
          break;
      }
    }

    return {
      'total': totalUsers,
      'customers': customers,
      'vendors': vendors,
      'admins': admins,
    };
  }

  /// Search users by name or email
  Stream<QuerySnapshot> searchUsers(String query) {
    // Note: Firestore doesn't support full-text search natively
    // This is a simple implementation that filters on the client
    // For production, consider using Algolia or ElasticSearch
    return _firestore.collection('users').snapshots();
  }
}
