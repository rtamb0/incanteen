import 'package:flutter/material.dart';
import 'package:incanteen/constants/style/style_constants.dart';
import 'package:incanteen/routes/routes_constants.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: StyleConstants.scaffoldBackgroundColor,
        toolbarHeight: size.height * 0.1,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "InCanteen",
          style: TextStyle(
            fontSize: 40,
            color: StyleConstants.colorTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Welcome 👋", style: TextStyle(fontSize: 24)),

            const SizedBox(height: 40),

            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, RoutesConstants.loginRoute),
                child: const Text("Login"),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: 200,
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, RoutesConstants.signupRoute),
                child: const Text("Sign Up"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
