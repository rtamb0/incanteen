import 'package:cloud_firestore/cloud_firestore.dart';

class VendorApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a vendor (optional, can also use Auth role)
  Future<void> addVendor(String vendorId, String name, String location) async {
    await _firestore.collection('vendors').doc(vendorId).set({
      'name': name,
      'location': location,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Add menu item for a vendor
  Future<void> addMenuItem(
    String vendorId,
    String name,
    double price,
    String description,
  ) async {
    await _firestore
        .collection('vendors')
        .doc(vendorId)
        .collection('menus')
        .add({
          'name': name,
          'price': price,
          'description': description,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  // Get vendor menus
  Stream<QuerySnapshot> getVendorMenus(String vendorId) {
    return _firestore
        .collection('vendors')
        .doc(vendorId)
        .collection('menus')
        .snapshots();
  }

  // Update menu item
  Future<void> updateMenuItem(
    String vendorId,
    String menuId,
    Map<String, dynamic> data,
  ) async {
    await _firestore
        .collection('vendors')
        .doc(vendorId)
        .collection('menus')
        .doc(menuId)
        .update(data);
  }

  // Delete menu item
  Future<void> deleteMenuItem(String vendorId, String menuId) async {
    await _firestore
        .collection('vendors')
        .doc(vendorId)
        .collection('menus')
        .doc(menuId)
        .delete();
  }
}
