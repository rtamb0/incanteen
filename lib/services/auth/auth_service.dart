import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> updateFcmToken(User user) async {
    String? token = await _messaging.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Rethrow FirebaseAuthException so caller can read .code/.message
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await updateFcmToken(cred.user!);
      return cred.user;
    } on FirebaseAuthException {
      rethrow; // propagate to caller
    } catch (e) {
      // optional: wrap non-Firebase exceptions
      rethrow;
    }
  }

  Future<User?> signUp(
    String email,
    String password,
    String name,
    String role, {
    String? businessName,
    String? businessAddress,
    String? phone,
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc = {
        'name': name,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (role == 'vendor') {
        userDoc.addAll({
          'businessName': businessName ?? '',
          'businessAddress': businessAddress ?? '',
          'phone': phone ?? '',
        });
      }

      await _firestore.collection('users').doc(cred.user!.uid).set(userDoc);
      await updateFcmToken(cred.user!);
      return cred.user;
    } on FirebaseAuthException {
      rethrow; // important: let UI inspect .code/.message
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
