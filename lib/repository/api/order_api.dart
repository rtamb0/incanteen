import 'package:cloud_firestore/cloud_firestore.dart';

class OrderApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Place an order
  Future<void> placeOrder(
    String userId,
    String vendorId,
    List<Map<String, dynamic>> items,
  ) async {
    await _firestore.collection('orders').add({
      'userId': userId,
      'vendorId': vendorId,
      'items': items, // array of menu items {id, name, price, quantity}
      'status': 'pending',
      'notified': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status,
      'notified': false, // reset notification for new status
    });
  }

  // Stream orders for vendor
  Stream<QuerySnapshot> getVendorOrders(String vendorId) {
    return _firestore
        .collection('orders')
        .where('vendorId', isEqualTo: vendorId)
        .snapshots();
  }

  // Stream orders for user
  Stream<QuerySnapshot> getUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }
}
