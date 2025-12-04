import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/auth/auth_service.dart';
import 'routes/router.dart';
import 'routes/routes_constants.dart';
import 'themes/themes.dart';
import 'pages/vendor_dashboard.dart';
import 'pages/customer_home.dart';
import 'pages/landing_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  NotificationService.setupFcmListener();
  runApp(const IncanteenApp());
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
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InCanteen',
      theme: lightTheme,
      onGenerateRoute: generateRoute,
      
      // Indonesian only
      locale: const Locale('id'),
      supportedLocales: const [Locale('id')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // Use builder to handle auth state and role-based routing
      builder: (context, child) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // Still loading auth state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const MaterialApp(
                debugShowCheckedModeBanner: false,
                home: Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            
            return child ?? const SizedBox.shrink();
          },
        );
      },
      
      // Use initial route with custom logic
      home: AuthWrapper(),
    );
  }
}

/// Wrapper widget that handles initial routing based on auth state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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
          return FutureBuilder<String?>(
            future: AuthService().getUserRole(snapshot.data!.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              
              final role = roleSnapshot.data;
              
              // Redirect based on role
              if (role == 'vendor') {
                return const VendorDashboard();
              } else if (role == 'customer') {
                return const CustomerHome();
              } else {
                // Role not found or invalid - sign out and go to landing
                AuthService().signOut();
                return const LandingPage();
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
