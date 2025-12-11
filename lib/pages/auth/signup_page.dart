import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  // Use super.key to satisfy the use_super_parameters lint/info.
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();

  // Role selection
  String _role = 'customer';
  bool _loading = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      // submit logic...
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _nameCtl,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) => (v != null && v.trim().isNotEmpty)
                      ? null
                      : 'Enter your name',
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      (v != null && v.contains('@')) ? null : 'Enter email',
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) =>
                      (v != null && v.length >= 6) ? null : 'Min 6 chars',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Register as:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                // Use initialValue instead of deprecated 'value' property.
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'customer',
                      child: Text('Customer'),
                    ),
                    DropdownMenuItem(value: 'vendor', child: Text('Vendor')),
                  ],
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() => _role = val);
                  },
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Choose a role' : null,
                ),

                const SizedBox(height: 16),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Create account'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
