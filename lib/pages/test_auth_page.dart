import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestAuthPage extends StatefulWidget {
  const TestAuthPage({Key? key}) : super(key: key);

  @override
  _TestAuthPageState createState() => _TestAuthPageState();
}

class _TestAuthPageState extends State<TestAuthPage> {
  final AuthService _auth = AuthService();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _name = TextEditingController();

  final TextEditingController _businessName = TextEditingController();
  final TextEditingController _businessAddress = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  String _role = 'customer';
  String _result = '';
  bool _isLoading = false;

  bool _validateForm({required bool isSignUp}) {
    if (_email.text.trim().isEmpty ||
        !RegExp(
          r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
        ).hasMatch(_email.text.trim())) {
      setState(() => _result = "❌ Invalid email format");
      return false;
    }

    if (_password.text.length < 6) {
      setState(() => _result = "❌ Password must be at least 6 characters");
      return false;
    }

    if (isSignUp && _name.text.trim().isEmpty) {
      setState(() => _result = "❌ Name cannot be empty");
      return false;
    }

    // Vendor-only validation
    if (isSignUp && _role == "vendor") {
      if (_businessName.text.trim().isEmpty) {
        setState(() => _result = "❌ Business name required for vendor account");
        return false;
      }

      if (_businessAddress.text.trim().isEmpty) {
        setState(() => _result = "❌ Business address required");
        return false;
      }

      if (_phone.text.trim().isEmpty ||
          !RegExp(r"^[0-9+ ]{8,}$").hasMatch(_phone.text.trim())) {
        setState(() => _result = "❌ Invalid phone number");
        return false;
      }
    }

    return true;
  }

  Future<void> _signUp() async {
    if (!_validateForm(isSignUp: true)) return;

    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      final user = await _auth.signUp(
        _email.text.trim(),
        _password.text.trim(),
        _name.text.trim(),
        _role,
        businessName: _businessName.text.trim(),
        businessAddress: _businessAddress.text.trim(),
        phone: _phone.text.trim(),
      );

      setState(() {
        _result = user != null ? "✅ Sign Up Success" : "❌ Sign Up Failed";
      });
    } on FirebaseAuthException catch (e) {
      // Friendly messages for common codes
      String msg;
      if (e.code == 'email-already-in-use') {
        msg =
            '❌ That email is already registered. Try signing in or use a different email.';
      } else if (e.code == 'weak-password') {
        msg = '❌ Password is too weak. Choose at least 6 characters.';
      } else if (e.code == 'invalid-email') {
        msg = '❌ Invalid email address.';
      } else {
        msg = '❌ ${e.message ?? 'Sign up failed.'}';
      }
      setState(() => _result = msg);
    } catch (e) {
      setState(() => _result = '❌ Unexpected error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signIn() async {
    if (!_validateForm(isSignUp: false)) return;

    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      final user = await _auth.signIn(
        _email.text.trim(),
        _password.text.trim(),
      );
      setState(() {
        _result = user != null ? "✅ Sign In Success" : "❌ Sign In Failed";
      });
    } on FirebaseAuthException catch (e) {
      String msg;
      if (e.code == 'user-not-found') {
        msg = '❌ No account found with that email.';
      } else if (e.code == 'wrong-password') {
        msg = '❌ Incorrect password.';
      } else {
        msg = '❌ ${e.message ?? 'Sign in failed.'}';
      }
      setState(() => _result = msg);
    } catch (e) {
      setState(() => _result = '❌ Unexpected error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    setState(() => _result = "🚪 Signed Out");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Auth")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            DropdownButton<String>(
              value: _role,
              items: const [
                DropdownMenuItem(value: "customer", child: Text("Customer")),
                DropdownMenuItem(value: "vendor", child: Text("Vendor")),
              ],
              onChanged: (val) => setState(() => _role = val!),
            ),
            if (_role == "vendor") ...[
              const SizedBox(height: 10),
              TextField(
                controller: _businessName,
                decoration: const InputDecoration(labelText: "Business Name"),
              ),
              TextField(
                controller: _businessAddress,
                decoration: const InputDecoration(
                  labelText: "Business Address",
                ),
              ),
              TextField(
                controller: _phone,
                decoration: const InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.phone,
              ),
            ],
            const SizedBox(height: 10),

            Column(
              children: [
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  child: const Text("Sign Up"),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  child: const Text("Sign In"),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signOut,
                  child: const Text("Sign Out"),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Text(
              _result,
              style: TextStyle(
                fontSize: 16,
                color: _result.contains("❌")
                    ? Colors.red
                    : _result.contains("✅")
                    ? Colors.green
                    : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
