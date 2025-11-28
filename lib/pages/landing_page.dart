import 'package:flutter/material.dart';
import 'package:incanteen/constants/style/style_constants.dart';

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
        child: Row(
          children: [
            Text("Hello Starter App!"),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, "/testAuth");
              },
              child: const Text("Go to Test Auth"),
            ),
          ],
        ),
      ),
    );
  }
}
