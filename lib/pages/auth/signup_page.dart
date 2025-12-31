import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:incanteen/services/auth/auth_service.dart';
import 'package:incanteen/routes/routes_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:incanteen/constants/validation_constants.dart';

class SignupPage extends StatefulWidget {
  // Use super.key to satisfy the use_super_parameters lint/info.
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtl = TextEditingController();
  final _lastNameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _confirmPassCtl = TextEditingController();
  final _phoneCtl = TextEditingController();

  // Vendor-specific controllers
  final _vendorNameCtl = TextEditingController();
  final _vendorAddressCtl = TextEditingController();

  // Role selection
  String _role = 'customer';
  bool _isLoading = false;
  String? _errorMessage;

  bool _autoValidate = false;

  StreamSubscription<User?>? _authSub;

  @override
  void dispose() {
    _authSub?.cancel();
    _firstNameCtl.dispose();
    _lastNameCtl.dispose();
    _emailCtl.dispose();
    _passCtl.dispose();
    _confirmPassCtl.dispose();
    _phoneCtl.dispose();
    _vendorNameCtl.dispose();
    _vendorAddressCtl.dispose();
    super.dispose();
  }

  /// Waits for the auth state to include [expectedUid], then retries fetching the user's
  /// role until it succeeds (or until timeout). When role fetch completes (either with a
  /// role or a null result), the method will pop to root so AuthWrapper can perform routing.
  void _waitForAuthAndRoleThenPop({String? expectedUid}) {
    // Cancel any previous subscription
    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        if (kDebugMode) debugPrint('Signup.wait: observed authState null');
        return;
      }
      if (kDebugMode) {
        debugPrint(
          'Signup.wait: observed authState uid=${user.uid} (expectedUid=$expectedUid)',
        );
      }

      if (expectedUid != null && user.uid != expectedUid) {
        if (kDebugMode) {
          debugPrint(
            'Signup.wait: uid mismatch; ignoring until expected user signs in',
          );
        }
        return;
      }

      // We've observed the expected auth user. Now attempt to resolve role.
      _authSub?.pause();

      final uid = user.uid;
      const retryDelay = Duration(milliseconds: 500);
      final deadline = DateTime.now().add(const Duration(seconds: 15));
      int attempt = 0;

      while (mounted && DateTime.now().isBefore(deadline)) {
        attempt++;
        if (kDebugMode) {
          debugPrint(
            'Signup.wait: attempt #$attempt to fetch role for uid=$uid',
          );
        }
        try {
          final role = await AuthService().getUserRole(uid, throwOnError: true);
          if (kDebugMode) {
            debugPrint(
              'Signup.wait: getUserRole returned (attempt #$attempt) -> role=$role for uid=$uid',
            );
          }

          // Notify AuthWrapper to refresh its FutureBuilder so it re-reads the role.
          AuthService.roleRefreshNotifier.value++;

          // Role fetch completed (role may be null for new users). Proceed to pop.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.popUntil(context, (route) => route.isFirst);
          });
          break;
        } on FirebaseException catch (e, st) {
          if (kDebugMode) {
            debugPrint(
              'Signup.wait: FirebaseException on attempt #$attempt for uid=$uid -> code=${e.code}, message=${e.message}\n$st',
            );
          }
          // Retry on transient failures.
          await Future.delayed(retryDelay);
          continue;
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint(
              'Signup.wait: non-Firebase exception on attempt #$attempt for uid=$uid -> $e\n$st',
            );
          }
          await Future.delayed(retryDelay);
          continue;
        }
      }

      if (mounted && DateTime.now().isAfter(deadline)) {
        if (kDebugMode) {
          debugPrint(
            'Signup.wait: deadline reached while waiting for role resolution for uid=$uid — popping to root anyway',
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

    // Safety: cancel subscription after a longer timeout to avoid leaks.
    Future.delayed(const Duration(seconds: 30)).then((_) {
      if (_authSub != null) {
        if (kDebugMode) {
          debugPrint('Signup.wait: safety timeout cancel subscription');
        }
        _authSub?.cancel();
        _authSub = null;
      }
    });
  }

  Future<void> _submit() async {
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
      // Collect vendor-specific data if needed
      final vendorData = _role == 'vendor'
          ? {
              'vendorName': _vendorNameCtl.text.trim(),
              'vendorAddress': _vendorAddressCtl.text.trim(),
            }
          : null;

      final user = await AuthService().signUp(
        _emailCtl.text.trim(),
        _passCtl.text.trim(),
        '${_firstNameCtl.text.trim()} ${_lastNameCtl.text.trim()}',
        _role,
        extraMetadata: vendorData,
      );

      if (!mounted) return;

      // Instead of immediately popping, wait for auth state + role resolution, then pop.
      _waitForAuthAndRoleThenPop(expectedUid: user?.uid);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = switch (e.code) {
          'email-already-in-use' => "Email is already registered.",
          _ => e.message ?? "Sign up failed.",
        };
      });
    } catch (e) {
      setState(() => _errorMessage = "Unexpected error occurred.");
    } finally {
      // Prevent calling setState after unmount
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Back button aligned to top-left
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
              // Vertically centered form
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
                        children: [
                          const Text(
                            "Create your account",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _firstNameCtl,
                            decoration: InputDecoration(
                              labelText: "First name",
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (v) => (v != null && v.trim().isNotEmpty)
                                ? null
                                : 'Enter your first name',
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _lastNameCtl,
                            decoration: InputDecoration(
                              labelText: "Last name",
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (v) => (v != null && v.trim().isNotEmpty)
                                ? null
                                : 'Enter your last name',
                          ),
                          const SizedBox(height: 14),
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
                            controller: _phoneCtl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: "Phone",
                              prefixIcon: const Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Phone number is required";
                              }
                              if (value.length <
                                  ValidationConstants.minPhoneNumberLength) {
                                return "Minimum ${ValidationConstants.minPhoneNumberLength} digits";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          PasswordField(passCtl: _passCtl),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmPassCtl,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: "Confirm Password",
                              prefixIcon: const Icon(Icons.lock),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Confirm password is required";
                              }
                              if (value != _passCtl.text) {
                                return "Passwords do not match";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Register as:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _role,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'customer',
                                child: Text('Customer'),
                              ),
                              DropdownMenuItem(
                                value: 'vendor',
                                child: Text('Vendor'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() => _role = val);
                            },
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Choose a role'
                                : null,
                          ),

                          // AnimatedSwitcher shows/hides vendor-only fields when role changes.
                          const SizedBox(height: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeIn,
                            switchOutCurve: Curves.easeOut,
                            child: _role == 'vendor'
                                ? Column(
                                    key: const ValueKey('vendorFields'),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      TextFormField(
                                        controller: _vendorNameCtl,
                                        decoration: InputDecoration(
                                          labelText: "Vendor name",
                                          prefixIcon: const Icon(
                                            Icons.storefront,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        validator: (v) {
                                          if (_role != 'vendor') return null;
                                          if (v == null || v.trim().isEmpty) {
                                            return 'Enter vendor name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _vendorAddressCtl,
                                        decoration: InputDecoration(
                                          labelText: "Vendor address",
                                          prefixIcon: const Icon(
                                            Icons.location_on,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        validator: (v) {
                                          if (_role != 'vendor') return null;
                                          if (v == null || v.trim().isEmpty) {
                                            return 'Enter vendor address';
                                          }
                                          return null;
                                        },
                                        // optional field: no validator
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  )
                                : const SizedBox.shrink(
                                    key: ValueKey('noVendorFields'),
                                  ),
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
                              onPressed: _isLoading ? null : _submit,
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
                                      "Create account",
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              RoutesConstants.loginRoute,
                            ),
                            child: const Text(
                              "Already have an account? Log in",
                            ),
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

class PasswordField extends StatefulWidget {
  const PasswordField({super.key, required TextEditingController passCtl})
    : _passCtl = passCtl;

  final TextEditingController _passCtl;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget._passCtl,
      obscureText: _obscureText,
      decoration: InputDecoration(
        labelText: "Password",
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Password is required";
        }
        if (value.length < ValidationConstants.minPasswordLength) {
          return "Minimum ${ValidationConstants.minPasswordLength} characters";
        }
        return null;
      },
    );
  }
}
