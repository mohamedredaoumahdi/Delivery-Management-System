import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../data/models/shop_model.dart';
import '../../../users/data/user_service.dart';
import '../../../users/data/models/user_model.dart';

class ShopFormDialog extends StatefulWidget {
  final ShopModel? shop; // Optional, for editing
  final Function(Map<String, dynamic>) onSave;

  const ShopFormDialog({
    super.key,
    this.shop,
    required this.onSave,
  });

  @override
  State<ShopFormDialog> createState() => _ShopFormDialogState();
}

class _ShopFormDialogState extends State<ShopFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _minimumOrderAmountController;
  late TextEditingController _deliveryFeeController;
  late TextEditingController _estimatedDeliveryTimeController;

  String? _selectedCategory;
  String? _selectedOwnerId;
  bool _isActive = true;
  bool _hasDelivery = true;
  bool _hasPickup = true;
  bool _isFeatured = false;

  List<UserModel> _vendors = [];
  bool _loadingVendors = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shop?.name ?? '');
    _descriptionController = TextEditingController(text: widget.shop?.description ?? '');
    _addressController = TextEditingController(text: widget.shop?.address ?? '');
    _latitudeController = TextEditingController(text: widget.shop?.latitude.toString() ?? '0.0');
    _longitudeController = TextEditingController(text: widget.shop?.longitude.toString() ?? '0.0');
    _phoneController = TextEditingController(text: widget.shop?.phone ?? '');
    _emailController = TextEditingController(text: widget.shop?.email ?? '');
    _websiteController = TextEditingController(text: widget.shop?.website ?? '');
    _minimumOrderAmountController = TextEditingController(
      text: widget.shop?.minimumOrderAmount.toString() ?? '10.0',
    );
    _deliveryFeeController = TextEditingController(
      text: widget.shop?.deliveryFee.toString() ?? '0.0',
    );
    _estimatedDeliveryTimeController = TextEditingController(
      text: widget.shop?.estimatedDeliveryTime?.toString() ?? '30',
    );

    _selectedCategory = widget.shop?.category ?? 'RESTAURANT';
    _selectedOwnerId = widget.shop?.ownerId;
    _isActive = widget.shop?.isActive ?? true;
    _hasDelivery = widget.shop?.hasDelivery ?? true;
    _hasPickup = widget.shop?.hasPickup ?? true;
    _isFeatured = widget.shop?.isFeatured ?? false;

    _loadVendors();
  }

  Future<void> _loadVendors() async {
    try {
      final userService = GetIt.instance<UserService>();
      final users = await userService.getUsers();
      setState(() {
        _vendors = users.where((user) => user.role == 'VENDOR').toList();
        _loadingVendors = false;
      });
    } catch (e) {
      setState(() {
        _loadingVendors = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load vendors: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _minimumOrderAmountController.dispose();
    _deliveryFeeController.dispose();
    _estimatedDeliveryTimeController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final shopData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'latitude': double.tryParse(_latitudeController.text) ?? 0.0,
        'longitude': double.tryParse(_longitudeController.text) ?? 0.0,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'category': _selectedCategory,
        'ownerId': _selectedOwnerId,
        'isActive': _isActive,
        'hasDelivery': _hasDelivery,
        'hasPickup': _hasPickup,
        'isFeatured': _isFeatured,
        'minimumOrderAmount': double.tryParse(_minimumOrderAmountController.text) ?? 0.0,
        'deliveryFee': double.tryParse(_deliveryFeeController.text) ?? 0.0,
        'estimatedDeliveryTime': int.tryParse(_estimatedDeliveryTimeController.text) ?? 30,
        if (_websiteController.text.isNotEmpty) 'website': _websiteController.text.trim(),
      };

      widget.onSave(shopData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.shop == null ? 'Add New Shop' : 'Edit Shop'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Shop Name *',
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true ? 'Description is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address *',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Address is required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Latitude *',
                        prefixIcon: Icon(Icons.map),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Latitude is required';
                        if (double.tryParse(value) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Longitude *',
                        prefixIcon: Icon(Icons.map),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Longitude is required';
                        if (double.tryParse(value) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone *',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value?.isEmpty ?? true ? 'Phone is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email is required';
                  if (!value.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(value: 'RESTAURANT', child: Text('Restaurant')),
                  DropdownMenuItem(value: 'GROCERY', child: Text('Grocery')),
                  DropdownMenuItem(value: 'PHARMACY', child: Text('Pharmacy')),
                  DropdownMenuItem(value: 'RETAIL', child: Text('Retail')),
                  DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                ],
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) => value == null ? 'Category is required' : null,
              ),
              const SizedBox(height: 12),
              _loadingVendors
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    )
                  : DropdownButtonFormField<String>(
                      initialValue: _selectedOwnerId,
                      decoration: const InputDecoration(
                        labelText: 'Owner (Vendor) *',
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: _vendors.isEmpty
                          ? [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('No vendors available'),
                              ),
                            ]
                          : _vendors.map((vendor) {
                              return DropdownMenuItem(
                                value: vendor.id,
                                child: Text('${vendor.name} (${vendor.email})'),
                              );
                            }).toList(),
                      onChanged: (value) => setState(() => _selectedOwnerId = value),
                      validator: (value) => value == null ? 'Owner is required' : null,
                    ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'Website (optional)',
                  prefixIcon: Icon(Icons.language),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minimumOrderAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Min Order Amount',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _deliveryFeeController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Fee',
                        prefixIcon: Icon(Icons.local_shipping),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _estimatedDeliveryTimeController,
                decoration: const InputDecoration(
                  labelText: 'Estimated Delivery Time (minutes)',
                  prefixIcon: Icon(Icons.access_time),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      title: const Text('Is Active'),
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      title: const Text('Has Delivery'),
                      value: _hasDelivery,
                      onChanged: (value) => setState(() => _hasDelivery = value),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      title: const Text('Has Pickup'),
                      value: _hasPickup,
                      onChanged: (value) => setState(() => _hasPickup = value),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      title: const Text('Is Featured'),
                      value: _isFeatured,
                      onChanged: (value) => setState(() => _isFeatured = value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(widget.shop == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }
}


