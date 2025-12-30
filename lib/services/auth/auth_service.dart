import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

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
      debugPrint('Failed to update FCM token: $e');
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
  Future<String?> getUserRole(String uid, {bool throwOnError = false}) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } on FirebaseException catch (e) {
      debugPrint('Failed to get user role (Firebase): $e');
      if (throwOnError) rethrow;
      return null;
    } catch (e) {
      debugPrint('Failed to get user role: $e');
      if (throwOnError) rethrow;
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

  /// signUp now attempts to clean up the auth user if Firestore (or other) writes fail.
  Future<User?> signUp(
    String email,
    String password,
    String displayName,
    String role, {
    Map<String, dynamic>? extraMetadata,
  }) async {
    UserCredential cred;
    try {
      // Create auth user
      cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name on Firebase Auth user
      await cred.user!.updateDisplayName(displayName);
    } on FirebaseAuthException {
      // Let the caller handle auth-specific errors (email-already-in-use, weak-password, etc.)
      rethrow;
    } catch (e) {
      // Unexpected error during auth creation
      rethrow;
    }

    final uid = cred.user!.uid;

    // Prepare user document
    final Map<String, dynamic> userDoc = {
      'displayName': displayName,
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (extraMetadata != null) {
      userDoc.addAll(extraMetadata);
    }

    try {
      // Write user doc to Firestore
      await _firestore.collection('users').doc(uid).set(userDoc);
    } catch (e) {
      debugPrint('Failed to write user doc for $uid: $e');

      // Attempt to delete the newly-created auth user to avoid an orphan
      try {
        final current = _auth.currentUser;
        if (current != null && current.uid == uid) {
          await current.delete();
          debugPrint('Deleted orphan auth user $uid after Firestore failure.');
        } else {
          debugPrint(
            'Could not delete orphan auth user $uid: current user is different or null.',
          );
        }
      } catch (deleteErr) {
        // Deletion may fail in rare cases (tokens expired / requires reauth). Log it.
        debugPrint(
          'Failed to delete orphan auth user $uid after Firestore error: $deleteErr',
        );
      }

      // Surface a helpful error to the caller (preserve original exception message)
      throw Exception(
        'Signup failed while saving profile data. Please try again. (details: $e)',
      );
    }

    // Update FCM token asynchronously without blocking signup result
    updateFcmTokenIfNeeded(uid);

    return cred.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
