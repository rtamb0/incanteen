import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  /// Notifier used by UI to request a retry of the role lookup in AuthWrapper.
  /// Other parts of the app should increment the value (e.g. `roleRefreshNotifier.value++`)
  /// when they know the user's Firestore profile has been created/updated and AuthWrapper
  /// should re-run its role-read future.
  static final ValueNotifier<int> roleRefreshNotifier = ValueNotifier<int>(0);

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Update FCM token if needed (only if user is logged in).
  /// This method intentionally avoids creating a user document if it doesn't exist yet
  /// (to prevent partial docs containing only FCM fields).
  Future<void> updateFcmTokenIfNeeded(String uid) async {
    try {
      String? token = await _messaging.getToken();
      if (token == null) return;

      final docRef = _firestore.collection('users').doc(uid);
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        // Document exists — safe to merge the token fields.
        await docRef.set({
          'fcmToken': token,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        if (kDebugMode) {
          debugPrint(
            'AuthService.updateFcmTokenIfNeeded: user doc for $uid does not exist; skipping FCM token write.',
          );
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AuthService.updateFcmTokenIfNeeded failed: $e\n$st');
      }
      // Swallow non-fatal errors - FCM token update failures should not crash the app
    }
  }

  /// Configure auth state change listener to update FCM tokens.
  void configureOnAuthChanged() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        updateFcmTokenIfNeeded(user.uid);
      }
    });
  }

  /// Get user role from Firestore.
  /// When [throwOnError] is true FirebaseExceptions are rethrown to let callers handle them.
  Future<String?> getUserRole(String uid, {bool throwOnError = false}) async {
    if (kDebugMode) debugPrint('AuthService.getUserRole start — uid: $uid');
    try {
      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();

      if (kDebugMode) {
        debugPrint(
          'AuthService.getUserRole fetched doc — uid: $uid, exists: ${doc.exists}',
        );
      }

      if (doc.exists) {
        final role = doc.data()?['role'] as String?;
        if (kDebugMode) {
          debugPrint('AuthService.getUserRole role for $uid: $role');
        }
        return role;
      }

      if (kDebugMode) {
        debugPrint('AuthService.getUserRole: no user document for uid: $uid');
      }
      return null;
    } on FirebaseException catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          'AuthService.getUserRole FirebaseException for uid: $uid — code: ${e.code}, message: ${e.message}\n$st',
        );
      }
      if (throwOnError) rethrow;
      return null;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          'AuthService.getUserRole unknown error for uid: $uid — $e\n$st',
        );
      }
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
      rethrow;
    }
  }

  /// signUp creates the Auth user and the Firestore profile document in one operation
  /// (client-side). This method now attempts to include the device's FCM token in the
  /// initial user document to reduce race issues where the auth listener writes only
  /// a partial doc containing FCM fields.
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

    // Try to fetch FCM token so initial doc includes it (best-effort).
    String? fcmToken;
    try {
      fcmToken = await _messaging.getToken();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService.signUp: failed to fetch FCM token: $e');
      }
      fcmToken = null;
    }

    // Prepare user document
    final Map<String, dynamic> userDoc = {
      'displayName': displayName,
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (fcmToken != null) 'fcmUpdatedAt': FieldValue.serverTimestamp(),
    };

    if (extraMetadata != null) {
      userDoc.addAll(extraMetadata);
    }

    try {
      // Write user doc to Firestore
      await _firestore.collection('users').doc(uid).set(userDoc);
      if (kDebugMode) {
        debugPrint('AuthService.signUp: user doc created for $uid');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService.signUp: Failed to write user doc for $uid: $e');
      }
      // Attempt to delete the newly-created auth user to avoid an orphan
      try {
        final current = _auth.currentUser;
        if (current != null && current.uid == uid) {
          await current.delete();
          if (kDebugMode) {
            debugPrint(
              'AuthService.signUp: Deleted orphan auth user $uid after Firestore failure.',
            );
          }
        } else {
          if (kDebugMode) {
            debugPrint(
              'AuthService.signUp: Could not delete orphan auth user $uid: current user is different or null.',
            );
          }
        }
      } catch (deleteErr) {
        if (kDebugMode) {
          debugPrint(
            'AuthService.signUp: Failed to delete orphan auth user $uid after Firestore error: $deleteErr',
          );
        }
      }

      // Surface a helpful error to the caller (preserve original exception message)
      throw Exception(
        'Signup failed while saving profile data. Please try again. (details: $e)',
      );
    }

    // Update FCM token asynchronously without blocking signup result (in case token changed)
    updateFcmTokenIfNeeded(uid);

    return cred.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
