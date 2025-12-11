import 'package:flutter/material.dart';

class UndefinitedPage extends StatelessWidget {
  // Use the super parameter for key and provide a named 'name' parameter
  // so callers like `UndefinitedPage(name: settings.name)` compile.
  final String? name;
  const UndefinitedPage({super.key, this.name = ""});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Undefinited View")),
      body: Center(child: Text("Route for $name is not defined")),
    );
  }
}
