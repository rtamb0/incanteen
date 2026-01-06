import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:incanteen/services/auth/auth_service.dart';

class VendorSetupPage extends StatefulWidget {
  const VendorSetupPage({super.key});

  @override
  State<VendorSetupPage> createState() => _VendorSetupPageState();
}

class _VendorSetupPageState extends State<VendorSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _vendorNameCtl = TextEditingController();
  final _vendorAddressCtl = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _vendorNameCtl.dispose();
    _vendorAddressCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Create vendor store info
      await FirebaseFirestore.instance.collection('vendors').doc(user.uid).set({
        'name': _vendorNameCtl.text.trim(),
        'location': _vendorAddressCtl.text.trim(),
        'description': '',
        'imageUrl': '',
        'isOpen': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Mark vendor as setup complete
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'vendorSetupComplete': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      if (mounted) {
        // Trigger role refresh and navigate
        AuthService.roleRefreshNotifier.value++;
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to setup vendor: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Vendor Setup'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 32),
                const Icon(Icons.store, size: 64, color: Colors.blue),
                const SizedBox(height: 24),
                const Text(
                  'Set Up Your Vendor Store',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Complete your vendor profile to start selling',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _vendorNameCtl,
                        decoration: InputDecoration(
                          labelText: 'Store Name',
                          hintText: 'e.g., John\'s Restaurant',
                          prefixIcon: const Icon(Icons.storefront),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Store name is required';
                          }
                          if (value.trim().length < 3) {
                            return 'Store name must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _vendorAddressCtl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Store Location / Address',
                          hintText: 'e.g., Jl. Merdeka No. 123, Jakarta Pusat',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Location is required';
                          }
                          if (value.trim().length < 5) {
                            return 'Please provide a detailed location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Complete Setup'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
