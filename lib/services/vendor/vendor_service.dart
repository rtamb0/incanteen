import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VendorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current vendor's store info
  Future<Map<String, dynamic>?> getVendorStoreInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final doc = await _firestore.collection('vendors').doc(user.uid).get();
    if (!doc.exists) return null;

    return doc.data();
  }

  /// Stream vendor store info for real-time updates
  Stream<DocumentSnapshot> getVendorStoreStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    return _firestore.collection('vendors').doc(user.uid).snapshots();
  }

  /// Update vendor store information
  Future<void> updateVendorStore({
    String? name,
    String? location,
    String? description,
    String? imageUrl,
    bool? isOpen,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) {
      updates['name'] = name;
      updates['storeName'] = name;
    }
    if (location != null) {
      updates['location'] = location;
      updates['storeLocation'] = location;
    }
    if (description != null) {
      updates['description'] = description;
      updates['storeDescription'] = description;
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      updates['imageUrl'] = imageUrl;
      updates['storeImageUrl'] = imageUrl;
    }
    if (isOpen != null) {
      updates['isOpen'] = isOpen;
      updates['isActive'] = isOpen;
    }

    await _firestore.collection('vendors').doc(user.uid).update(updates);
  }

  /// Toggle store open/closed status
  Future<void> toggleStoreStatus(bool isOpen) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    await _firestore.collection('vendors').doc(user.uid).update({
      'isOpen': isOpen,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
