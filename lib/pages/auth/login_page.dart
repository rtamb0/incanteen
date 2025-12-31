import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:incanteen/services/auth/auth_service.dart';
import 'package:incanteen/routes/routes_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:incanteen/constants/validation_constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtl = TextEditingController();
  final TextEditingController _passwordCtl = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  bool _autoValidate = false;

  StreamSubscription<User?>? _authSub;

  @override
  void dispose() {
    _authSub?.cancel();
    _emailCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  /// Waits for the auth state to include [expectedUid], then retries fetching the user's
  /// role until it succeeds (or until timeout). When role fetch completes (either with a
  /// role or a null result), the method will pop to root so AuthWrapper can perform routing.
  void _waitForAuthAndRoleThenPop({String? expectedUid}) {
    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        if (kDebugMode) debugPrint('Login.wait: observed authState null');
        return;
      }
      if (kDebugMode) {
        debugPrint(
          'Login.wait: observed authState uid=${user.uid} (expectedUid=$expectedUid)',
        );
      }

      if (expectedUid != null && user.uid != expectedUid) {
        if (kDebugMode) {
          debugPrint(
            'Login.wait: uid mismatch; ignoring until expected user signs in',
          );
        }
        return;
      }

      _authSub?.pause();

      final uid = user.uid;
      const retryDelay = Duration(milliseconds: 500);
      final deadline = DateTime.now().add(const Duration(seconds: 15));
      int attempt = 0;

      while (mounted && DateTime.now().isBefore(deadline)) {
        attempt++;
        if (kDebugMode) {
          debugPrint(
            'Login.wait: attempt #$attempt to fetch role for uid=$uid',
          );
        }
        try {
          final role = await AuthService().getUserRole(uid, throwOnError: true);
          if (kDebugMode) {
            debugPrint(
              'Login.wait: getUserRole returned (attempt #$attempt) -> role=$role for uid=$uid',
            );
          }

          // Notify AuthWrapper to refresh its FutureBuilder so it re-reads the role.
          AuthService.roleRefreshNotifier.value++;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.popUntil(context, (route) => route.isFirst);
          });
          break;
        } on FirebaseException catch (e, st) {
          if (kDebugMode) {
            debugPrint(
              'Login.wait: FirebaseException on attempt #$attempt for uid=$uid -> code=${e.code}, message=${e.message}\n$st',
            );
          }
          await Future.delayed(retryDelay);
          continue;
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint(
              'Login.wait: non-Firebase exception on attempt #$attempt for uid=$uid -> $e\n$st',
            );
          }
          await Future.delayed(retryDelay);
          continue;
        }
      }

      if (mounted && DateTime.now().isAfter(deadline)) {
        if (kDebugMode) {
          debugPrint(
            'Login.wait: deadline reached while waiting for role resolution for uid=$uid — popping to root anyway',
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.popUntil(context, (route) => route.isFirst);
        });
      }

      _authSub?.cancel();
      _authSub = null;
    });

    // Safety timeout
    Future.delayed(const Duration(seconds: 30)).then((_) {
      if (_authSub != null) {
        if (kDebugMode) {
          debugPrint('Login.wait: safety timeout cancel subscription');
        }
        _authSub?.cancel();
        _authSub = null;
      }
    });
  }

  Future<void> _login() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      setState(() {
        _autoValidate = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService().signIn(
        _emailCtl.text.trim(),
        _passwordCtl.text.trim(),
      );

      if (!mounted) return;

      // Wait for auth + role resolution before popping.
      _waitForAuthAndRoleThenPop(expectedUid: user?.uid);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = switch (e.code) {
          'invalid-credential' => "Incorrect email or password.",
          _ => e.message ?? "Login failed.",
        };
      });
    } catch (e) {
      setState(() => _errorMessage = "Unexpected error occurred.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back),
                      const SizedBox(width: 8),
                      const Text("Back"),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _autoValidate
                          ? AutovalidateMode.always
                          : AutovalidateMode.disabled,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Log in to your account",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _emailCtl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "Email",
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Email is required";
                              }
                              if (!ValidationConstants.emailRegex.hasMatch(
                                value,
                              )) {
                                return "Invalid email format";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordCtl,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon: const Icon(Icons.lock),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) =>
                                value != null &&
                                    value.length <
                                        ValidationConstants.minPasswordLength
                                ? "Minimum ${ValidationConstants.minPasswordLength} characters"
                                : null,
                          ),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "Login",
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              RoutesConstants.forgotPasswordRoute,
                            ),
                            child: const Text("Forgot password?"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
