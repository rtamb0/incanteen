import 'package:flutter/material.dart';
import 'package:incanteen/services/auth/auth_service.dart';
import 'package:flutter/foundation.dart';

class FinalisingAccountPage extends StatefulWidget {
  const FinalisingAccountPage({super.key});

  @override
  State<FinalisingAccountPage> createState() => _FinalisingAccountPageState();
}

class _FinalisingAccountPageState extends State<FinalisingAccountPage> {
  int _attempts = 0;

  void _retry() {
    setState(() => _attempts++);
    // Signal AuthWrapper to retry role lookup.
    AuthService.roleRefreshNotifier.value++;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Retrying account finalization...')),
    );
  }

  void _cancelAndSignOut() {
    AuthService().signOut().catchError((e) {
      if (kDebugMode) debugPrint('FinalisingAccountPage.signOut failed: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Minimal scaffold with a blocking dark background
      backgroundColor: Colors.black54,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              const Text(
                'Finishing account setup...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Attempts: $_attempts',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(onPressed: _retry, child: const Text('Retry')),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _cancelAndSignOut,
                    child: const Text(
                      'Cancel / Sign out',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
