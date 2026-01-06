import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:incanteen/services/admin/admin_service.dart';

/// Service for managing vendor stores and menus as admin
/// Limited edit access compared to vendors themselves
class AdminVendorService {
  // Singleton pattern
  static final AdminVendorService _instance = AdminVendorService._internal();

  factory AdminVendorService() {
    return _instance;
  }

  AdminVendorService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all vendor users (users with vendor role)
  /// Note: Filtering done client-side to avoid index requirements
  Stream<QuerySnapshot> getAllVendors() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get vendor store information
  Future<DocumentSnapshot> getVendorInfo(String vendorId) async {
    return await _firestore.collection('vendors').doc(vendorId).get();
  }

  /// Get vendor menus
  Stream<QuerySnapshot> getVendorMenus(String vendorId) {
    return _firestore
        .collection('vendors')
        .doc(vendorId)
        .collection('menus')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Admin can only edit vendor name and location (not internal menus)
  Future<void> updateVendorInfo(
    String vendorId, {
    String? name,
    String? location,
  }) async {
    if (!await AdminService().isAdmin()) {
      throw Exception('Unauthorized: Admin access required');
    }

    final updates = <String, dynamic>{};
    if (name != null && name.isNotEmpty) {
      updates['name'] = name;
    }
    if (location != null && location.isNotEmpty) {
      updates['location'] = location;
    }

    if (updates.isEmpty) {
      throw Exception('No fields to update');
    }

    updates['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('vendors').doc(vendorId).update(updates);
  }

  /// Admin CAN edit menu item prices (for operational reasons)
  /// But CANNOT edit name/description (vendor's content)
  Future<void> updateMenuItemPrice(
    String vendorId,
    String menuId,
    double newPrice,
  ) async {
    if (!await AdminService().isAdmin()) {
      throw Exception('Unauthorized: Admin access required');
    }

    if (newPrice < 0) {
      throw Exception('Price cannot be negative');
    }

    await _firestore
        .collection('vendors')
        .doc(vendorId)
        .collection('menus')
        .doc(menuId)
        .update({'price': newPrice, 'updatedAt': FieldValue.serverTimestamp()});
  }

  /// Get vendor statistics
  Future<Map<String, dynamic>> getVendorStats(String vendorId) async {
    if (!await AdminService().isAdmin()) {
      throw Exception('Unauthorized: Admin access required');
    }

    try {
      // Get vendor info
      final vendorDoc = await _firestore
          .collection('vendors')
          .doc(vendorId)
          .get();

      // Get menu count
      final menusSnapshot = await _firestore
          .collection('vendors')
          .doc(vendorId)
          .collection('menus')
          .get();

      // Get orders count for this vendor
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('vendorId', isEqualTo: vendorId)
          .get();

      return {
        'vendorExists': vendorDoc.exists,
        'menuCount': menusSnapshot.docs.length,
        'totalOrders': ordersSnapshot.docs.length,
        'vendorData': vendorDoc.data(),
      };
    } catch (e) {
      debugPrint('Error getting vendor stats: $e');
      rethrow;
    }
  }
}
