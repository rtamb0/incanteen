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
import 'pages/landing_page.dart';

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
    // Alternatively: setState(() {}); // if you're not using a notifier
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

/// Wrapper widget that handles initial routing based on auth state
/// Converted to Stateful so we can implement a clean retry mechanism (no reassemble).
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Increment to force FutureBuilder to refetch the future when retrying.
  int _retryKey = 0;

  void _retry() => setState(() => _retryKey++);

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
                // If creation and lastSignIn are equal or within a small tolerance, treat as new
                final diffSeconds = c.difference(l).inSeconds.abs();
                if (diffSeconds <= 5) return true;
                // Also treat as new if account was created very recently (clock skew tolerant)
                final sinceCreation = DateTime.now().difference(c).inSeconds;
                if (sinceCreation >= 0 && sinceCreation <= 60) return true;
                return false;
              }

              final newUser = isLikelyNewUser();

              // If Firestore returned an error when fetching role
              if (roleSnapshot.hasError) {
                debugPrint(
                  'Failed to load user role for ${user.uid}: ${roleSnapshot.error}',
                );

                if (newUser) {
                  // For freshly created users: don't auto-sign-out. Show landing/profile flow and a retry.
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
                            onPressed: () {
                              // Let the user explicitly sign out if they want
                              AuthService().signOut().catchError(
                                (e) => debugPrint(e.toString()),
                              );
                            },
                            child: const Text('Sign out'),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  // For existing users: treat permission/role errors as fatal and sign them out
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    AuthService().signOut().catchError((error) {
                      debugPrint('Error signing out (role read error): $error');
                    });
                  });
                  return const LandingPage();
                }
              }

              // No error — examine the role value
              final role = roleSnapshot.data;

              if (role == 'vendor') {
                return const VendorDashboard();
              } else if (role == 'customer') {
                return const CustomerHome();
              } else {
                // Role is missing (null/empty) — could be new user or a problem for an existing user
                if (newUser) {
                  // New user: don't sign out; let them continue to LandingPage/profile completion
                  return const LandingPage();
                } else {
                  // Existing user without role: sign out automatically
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    AuthService().signOut().catchError((error) {
                      debugPrint(
                        'Error signing out user with missing role: $error',
                      );
                    });
                  });
                  return const LandingPage();
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
