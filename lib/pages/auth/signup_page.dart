// import 'package:flutter/material.dart';
// import 'package:incanteen/services/auth/auth_service.dart';
// import 'package:incanteen/routes/routes_constants.dart';

// class SignupPage extends StatefulWidget {
//   const SignupPage({Key? key}) : super(key: key);

//   @override
//   _SignupPageState createState() => _SignupPageState();
// }

// class _SignupPageState extends State<SignupPage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   String _role = 'customer'; // or 'vendor'

//   bool _loading = false;

//   void _signUp() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _loading = true);

//     final user = await AuthService().signUp(
//       _emailController.text,
//       _passwordController.text,
//       _nameController.text,
//       _role,
//     );

//     setState(() => _loading = false);

//     if (user != null) {
//       Navigator.pushReplacementNamed(context, RoutesConstants.landingRoute);
//     } else {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Sign up failed.')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Sign Up')),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     TextFormField(
//                       controller: _nameController,
//                       decoration: const InputDecoration(labelText: 'Name'),
//                       validator: (value) =>
//                           value!.isEmpty ? 'Enter your name' : null,
//                     ),
//                     TextFormField(
//                       controller: _emailController,
//                       decoration: const InputDecoration(labelText: 'Email'),
//                       validator: (value) =>
//                           value!.contains('@') ? null : 'Enter valid email',
//                     ),
//                     TextFormField(
//                       controller: _passwordController,
//                       decoration: const InputDecoration(labelText: 'Password'),
//                       obscureText: true,
//                       validator: (value) =>
//                           value!.length < 6 ? 'Minimum 6 characters' : null,
//                     ),
//                     const SizedBox(height: 16),
//                     DropdownButtonFormField<String>(
//                       value: _role,
//                       items: const [
//                         DropdownMenuItem(
//                           value: 'customer',
//                           child: Text('Customer'),
//                         ),
//                         DropdownMenuItem(
//                           value: 'vendor',
//                           child: Text('Vendor'),
//                         ),
//                       ],
//                       onChanged: (val) => setState(() => _role = val!),
//                       decoration: const InputDecoration(labelText: 'Role'),
//                     ),
//                     const SizedBox(height: 24),
//                     ElevatedButton(
//                       onPressed: _signUp,
//                       child: const Text('Sign Up'),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
// }
