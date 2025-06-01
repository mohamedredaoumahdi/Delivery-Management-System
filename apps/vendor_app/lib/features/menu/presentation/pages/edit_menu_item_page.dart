import 'package:flutter/material.dart';

class EditMenuItemPage extends StatelessWidget {
  final String itemId;
  
  const EditMenuItemPage({
    super.key,
    required this.itemId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Menu Item'),
      ),
      body: Center(
        child: Text('Edit Menu Item $itemId - Coming Soon'),
      ),
    );
  }
} 