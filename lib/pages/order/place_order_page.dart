import 'package:flutter/material.dart';

class PlaceOrderPage extends StatefulWidget {
  // Provide named parameters vendorId and userId to match how the router constructs it:
  // PlaceOrderPage(vendorId: args['vendorId'], userId: args['userId'])
  final String vendorId;
  final String userId;

  const PlaceOrderPage({
    super.key,
    required this.vendorId,
    required this.userId,
  });

  @override
  State<PlaceOrderPage> createState() => _PlaceOrderPageState();
}

class _PlaceOrderPageState extends State<PlaceOrderPage> {
  bool _submitting = false;

  Future<void> _placeOrder() async {
    setState(() => _submitting = true);

    try {
      // Example asynchronous operation
      final success = await Future<bool>.delayed(
        const Duration(seconds: 1),
        () => true,
      );

      // Ensure mounted before using context after async gap
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Order placed')));
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Place order for vendor ${widget.vendorId}')),
      body: Center(
        child: _submitting
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _placeOrder,
                child: const Text('Place Order'),
              ),
      ),
    );
  }
}
