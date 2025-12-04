import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Update FCM token if needed (only if user is logged in)
  /// Catches and swallows non-fatal errors to avoid crashes
  Future<void> updateFcmTokenIfNeeded(String uid) async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(uid).set({
          'fcmToken': token,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Swallow non-fatal errors - FCM token update failures should not crash the app
      print('Failed to update FCM token: $e');
    }
  }

  /// Configure auth state change listener to update FCM tokens
  void configureOnAuthChanged() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        updateFcmTokenIfNeeded(user.uid);
      }
    });
  }

  /// Get user role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      print('Failed to get user role: $e');
      return null;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Rethrow FirebaseAuthException so caller can read .code/.message
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Update FCM token asynchronously without blocking
      updateFcmTokenIfNeeded(cred.user!.uid);
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
    String displayName,
    String role, {
    Map<String, dynamic>? extraMetadata,
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name on Firebase Auth user
      await cred.user!.updateDisplayName(displayName);

      final userDoc = {
        'displayName': displayName,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Merge extra metadata if provided
      if (extraMetadata != null) {
        userDoc.addAll(extraMetadata);
      }

      await _firestore.collection('users').doc(cred.user!.uid).set(userDoc);
      
      // Update FCM token asynchronously without blocking
      updateFcmTokenIfNeeded(cred.user!.uid);
      
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
