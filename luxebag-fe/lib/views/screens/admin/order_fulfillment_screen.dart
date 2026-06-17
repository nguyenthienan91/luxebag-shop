import 'package:flutter/material.dart';

class OrderFulfillmentScreen extends StatelessWidget {
  const OrderFulfillmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Order Fulfillment', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Text('Order Fulfillment Content Here'),
      ),
    );
  }
}
