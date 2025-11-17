import 'package:flutter/material.dart';
import 'package:incanteen/routes/routes_constants.dart';

class NoInternetPage extends StatelessWidget {
  const NoInternetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Cek koneksi internet Anda dan coba lagi!",
              style: const TextStyle(fontSize: 20, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Icon(Icons.error, color: Colors.red, size: 40),
            const SizedBox(height: 20),
            ElevatedButton(
              child: Text("Coba Lagi"),
              onPressed: () {
                Navigator.of(
                  context,
                ).popAndPushNamed(RoutesConstants.splashScreenRoute);
              },
            ),
          ],
        ),
      ),
    );
  }
}
