import 'package:flutter/material.dart';
import 'package:incanteen/repository/api/order_api.dart';
import 'package:incanteen/routes/routes_constants.dart';

class PlaceOrderPage extends StatefulWidget {
  final String userId;
  final String vendorId;

  const PlaceOrderPage({
    super.key,
    required this.userId,
    required this.vendorId,
  });

  @override
  State<PlaceOrderPage> createState() => _PlaceOrderPageState();
}

class _PlaceOrderPageState extends State<PlaceOrderPage> {
  final OrderApi _orderApi = OrderApi();
  bool _loading = false;

  // Example order items
  final List<Map<String, dynamic>> _items = [
    {'id': '1', 'name': 'Nasi Goreng', 'price': 15000, 'quantity': 2},
    {'id': '2', 'name': 'Mie Ayam', 'price': 12000, 'quantity': 1},
  ];

  void _placeOrder() async {
    setState(() => _loading = true);
    await _orderApi.placeOrder(widget.userId, widget.vendorId, _items);
    setState(() => _loading = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Order placed!')));

    // Navigate back to landing page
    Navigator.pushReplacementNamed(context, RoutesConstants.landingRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Place Order')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // You can list items dynamically here
            ..._items.map(
              (item) => ListTile(
                title: Text(item['name']),
                subtitle: Text('Price: ${item['price']} x ${item['quantity']}'),
              ),
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _placeOrder,
                    child: const Text('Place Order'),
                  ),
          ],
        ),
      ),
    );
  }
}
