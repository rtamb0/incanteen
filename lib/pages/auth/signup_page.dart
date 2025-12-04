import 'package:flutter/material.dart';
import 'package:incanteen/services/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:incanteen/constants/validation_constants.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String _role = 'customer';
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService().signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        _role,
      );

      if (!mounted) return;
      // Pop all routes and return to root - auth state listener will handle redirect
      Navigator.popUntil(context, (route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = switch (e.code) {
          'email-already-in-use' => 'This email is already registered.',
          'weak-password' => 'Password is too weak. Use at least 6 characters.',
          'invalid-email' => 'Invalid email format.',
          _ => e.message ?? 'Sign up failed.',
        };
      });
    } catch (e) {
      setState(() => _errorMessage = 'Unexpected error occurred.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Create your account',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Full name is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!ValidationConstants.emailRegex.hasMatch(value)) {
                    return 'Invalid email format';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < ValidationConstants.minPasswordLength) {
                    return 'Password must be at least ${ValidationConstants.minPasswordLength} characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),
              
              const Text(
                'I am a:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Customer'),
                      value: 'customer',
                      groupValue: _role,
                      onChanged: (value) => setState(() => _role = value!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Vendor'),
                      value: 'vendor',
                      groupValue: _role,
                      onChanged: (value) => setState(() => _role = value!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Sign Up', style: TextStyle(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Already have an account? Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

