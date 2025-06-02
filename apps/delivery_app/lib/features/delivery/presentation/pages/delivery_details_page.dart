import 'package:flutter/material.dart';

class DeliveryDetailsPage extends StatelessWidget {
  final String deliveryId;

  const DeliveryDetailsPage({
    super.key,
    required this.deliveryId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery #$deliveryId'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.info_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Delivery Details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Delivery ID: $deliveryId'),
            const SizedBox(height: 8),
            const Text('Feature in development'),
          ],
        ),
      ),
    );
  }
} 