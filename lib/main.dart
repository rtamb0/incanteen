// Top-level imports and main() retained from your file
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/auth/auth_service.dart';
import 'routes/router.dart';
import 'providers/theme_notifier.dart';
import 'pages/vendor_dashboard.dart';
import 'pages/customer_home.dart';
import 'pages/admin/admin_dashboard.dart';
import 'pages/landing_page.dart';
import 'pages/auth/finalising_account_page.dart';
import 'pages/auth/vendor_setup_page.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  NotificationService.setupFcmListener();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const IncanteenApp(),
    ),
  );
}

class IncanteenApp extends StatefulWidget {
  const IncanteenApp({super.key});

  @override
  State<IncanteenApp> createState() => _IncanteenAppState();
}

class _IncanteenAppState extends State<IncanteenApp> {
  @override
  void initState() {
    super.initState();
    // Configure auth state listener to update FCM tokens
    AuthService().configureOnAuthChanged();
  }

  @override
  void reassemble() {
    super.reassemble();
    // Force the theme notifier to rebuild ThemeData from current StyleConstants
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    themeNotifier.setAppTheme();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InCanteen',
      theme: themeNotifier.themeData,
      onGenerateRoute: generateRoute,

      // Indonesian only
      locale: const Locale('id'),
      supportedLocales: const [Locale('id')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Use home with AuthWrapper for auth state and role-based routing
      home: const AuthWrapper(),
    );
  }
}

/// Wrapper widget that handles initial routing based on auth state.
/// Listens to AuthService.roleRefreshNotifier to know when to re-run the role lookup.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Increment to force FutureBuilder to refetch the future when retrying.
  int _retryKey = 0;

  void _retry() => setState(() => _retryKey++);

  // Listener callback for the global role refresh notifier
  void _onRoleRefresh() {
    // Force a re-evaluation of the FutureBuilder by bumping the key.
    setState(() {
      _retryKey++;
    });
  }

  @override
  void initState() {
    super.initState();
    // Listen to requests to refresh role lookup.
    AuthService.roleRefreshNotifier.addListener(_onRoleRefresh);
  }

  @override
  void dispose() {
    AuthService.roleRefreshNotifier.removeListener(_onRoleRefresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is logged in - check role and redirect
        if (snapshot.hasData && snapshot.data != null) {
          final uid = snapshot.data!.uid;

          return FutureBuilder<String?>(
            // Use a ValueKey driven by _retryKey to force a rebuild/fresh future when retry is pressed.
            key: ValueKey(_retryKey),
            future: AuthService().getUserRole(uid, throwOnError: true),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.done) {
                debugPrint(
                  'AuthWrapper role fetch — uid=$uid, role=${roleSnapshot.data}, hasError=${roleSnapshot.hasError}',
                );
              }

              if (kDebugMode) {
                debugPrint(
                  'AuthWrapper build — uid=$uid, retryKey=$_retryKey, connection=${roleSnapshot.connectionState}',
                );
              }

              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Helper: determine if this user is likely a newly created account
              final user = snapshot.data!;
              bool isLikelyNewUser() {
                final c = user.metadata.creationTime;
                final l = user.metadata.lastSignInTime;
                if (c == null || l == null) return false;
                final diffSeconds = c.difference(l).inSeconds.abs();
                if (diffSeconds <= 5) return true;
                final sinceCreation = DateTime.now().difference(c).inSeconds;
                if (sinceCreation >= 0 && sinceCreation <= 60) return true;
                return false;
              }

              final newUser = isLikelyNewUser();

              if (roleSnapshot.hasError) {
                if (kDebugMode) {
                  debugPrint(
                    'AuthWrapper: Failed to load user role for ${user.uid}: ${roleSnapshot.error}',
                  );
                }

                if (newUser) {
                  // For freshly created users: show a simple retry UI.
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Finishing account setup...'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _retry,
                            child: const Text('Retry'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () async {
                              final confirmed =
                                  await AuthService().confirmSignOut(context);
                              if (!confirmed) return;
                              AuthService().signOut().catchError((e) {
                                if (kDebugMode) {
                                  debugPrint('Sign out failed: $e');
                                }
                              });
                            },
                            child: const Text('Sign out'),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  // For existing users: treat permission/role errors as fatal and sign them out.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    AuthService().signOut().catchError((error) {
                      if (kDebugMode) {
                        debugPrint(
                          'Error signing out (role read error): $error',
                        );
                      }
                    });
                  });

                  return const Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text(
                            'Account configuration error. Signing you out...',
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }

              // No error — examine the role value
              final role = roleSnapshot.data;

              if (role == 'admin' || role == 'superadmin') {
                return const AdminDashboard();
              } else if (role == 'vendor') {
                // Check if vendor has completed setup
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get(),
                  builder: (context, userDocSnapshot) {
                    if (userDocSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (userDocSnapshot.hasData &&
                        userDocSnapshot.data != null) {
                      final userData = userDocSnapshot.data!.data() as Map?;
                      final vendorSetupComplete =
                          userData?['vendorSetupComplete'] as bool? ?? false;

                      if (!vendorSetupComplete) {
                        return const VendorSetupPage();
                      }
                    }

                    return const VendorDashboard();
                  },
                );
              } else if (role == 'customer') {
                return const CustomerHome();
              } else {
                // Role is missing (null/empty)
                if (newUser) {
                  // New user: show dedicated finalising page while setup completes.
                  return const FinalisingAccountPage();
                } else {
                  // Existing user without role: sign out automatically and show interim UI.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    AuthService().signOut().catchError((error) {
                      if (kDebugMode) {
                        debugPrint(
                          'Error signing out user with missing role: $error',
                        );
                      }
                    });
                  });

                  return const Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Account incomplete. Signing you out...'),
                        ],
                      ),
                    ),
                  );
                }
              }
            },
          );
        }

        // User is not logged in - show landing page
        return const LandingPage();
      },
    );
  }
}
