import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserService {
  // Singleton (ikut gaya AuthService kamu)
  static final UserService _instance = UserService._internal();

  factory UserService() {
    return _instance;
  }

  UserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Ambil data user (mahasiswa) yang sedang login
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('User belum login');
        }
        return null;
      }

      final doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        if (kDebugMode) {
          print('Data user tidak ditemukan di Firestore');
        }
        return null;
      }

      return doc.data();
    } catch (e) {
      if (kDebugMode) {
        print('Error getCurrentUser: $e');
      }
      return null;
    }
  }

  /// Simpan data user saat register pertama kali
  Future<void> createUserIfNotExists({
    required String uid,
    required String email,
    String? name,
    String role = 'mahasiswa',
  }) async {
    try {
      final ref = _firestore.collection('users').doc(uid);
      final doc = await ref.get();

      if (!doc.exists) {
        await ref.set({
          'email': email,
          'name': name ?? '',
          'role': role,
          'createdAt': Timestamp.now(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error createUserIfNotExists: $e');
      }
    }
  }
}
