import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:domain/domain.dart';
import 'package:ui_kit/ui_kit.dart';

import '../bloc/address_bloc.dart';
import '../bloc/address_event.dart';
import '../bloc/address_state.dart';

class AddEditAddressPage extends StatefulWidget {
  final String? addressId;
  final Address? address;

  const AddEditAddressPage({
    super.key,
    this.addressId,
    this.address,
  });

  @override
  State<AddEditAddressPage> createState() => _AddEditAddressPageState();
}

class _AddEditAddressPageState extends State<AddEditAddressPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelController;
  late TextEditingController _fullAddressController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _instructionsController;
  
  bool _isDefault = false;
  bool _hasUnsavedChanges = false;
  
  String? _selectedLabelType;
  final List<String> _labelTypes = [
    'Home',
    'Work',
    'School',
    'Gym',
    'Hospital',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _labelController = TextEditingController();
    _fullAddressController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
    _instructionsController = TextEditingController();
    
    // If editing, populate fields
    if (widget.address != null) {
      final address = widget.address!;
      _labelController.text = address.label;
      _fullAddressController.text = address.fullAddress;
      _latitudeController.text = address.latitude.toString();
      _longitudeController.text = address.longitude.toString();
      _instructionsController.text = address.instructions ?? '';
      _isDefault = address.isDefault;
      
      // Set selected label type if it matches predefined types
      if (_labelTypes.contains(address.label)) {
        _selectedLabelType = address.label;
      } else {
        _selectedLabelType = 'Other';
      }
    } else {
      // Default coordinates (San Francisco)
      _latitudeController.text = '37.7749';
      _longitudeController.text = '-122.4194';
      _selectedLabelType = 'Home';
      _labelController.text = 'Home';
    }
    
    // Listen for changes
    _labelController.addListener(_onFieldChanged);
    _fullAddressController.addListener(_onFieldChanged);
    _latitudeController.addListener(_onFieldChanged);
    _longitudeController.addListener(_onFieldChanged);
    _instructionsController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _fullAddressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  void _onLabelTypeChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedLabelType = value;
        if (value != 'Other') {
          _labelController.text = value;
        } else {
          _labelController.clear();
        }
        _hasUnsavedChanges = true;
      });
    }
  }

  void _saveAddress() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final label = _labelController.text.trim();
    final fullAddress = _fullAddressController.text.trim();
    final latitude = double.tryParse(_latitudeController.text.trim()) ?? 0.0;
    final longitude = double.tryParse(_longitudeController.text.trim()) ?? 0.0;
    final instructions = _instructionsController.text.trim();

    if (widget.address != null) {
      // Update existing address
      context.read<AddressBloc>().add(AddressUpdateEvent(
        id: widget.address!.id,
        label: label,
        fullAddress: fullAddress,
        latitude: latitude,
        longitude: longitude,
        instructions: instructions.isEmpty ? null : instructions,
        isDefault: _isDefault,
      ));
    } else {
      // Create new address
      context.read<AddressBloc>().add(AddressCreateEvent(
        label: label,
        fullAddress: fullAddress,
        latitude: latitude,
        longitude: longitude,
        instructions: instructions.isEmpty ? null : instructions,
        isDefault: _isDefault,
      ));
    }
  }

  void _useCurrentLocation() {
    // TODO: Implement location services
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location services integration coming soon!'),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.address != null;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Address' : 'Add Address'),
          elevation: 0,
          actions: [
            BlocBuilder<AddressBloc, AddressState>(
              builder: (context, state) {
                return TextButton(
                  onPressed: state is AddressLoading ? null : _saveAddress,
                  child: state is AddressLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<AddressBloc, AddressState>(
          listener: (context, state) {
            if (state is AddressCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Address added successfully'),
                  backgroundColor: theme.colorScheme.primary,
                ),
              );
              setState(() {
                _hasUnsavedChanges = false;
              });
              context.pop();
            } else if (state is AddressUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Address updated successfully'),
                  backgroundColor: theme.colorScheme.primary,
                ),
              );
              setState(() {
                _hasUnsavedChanges = false;
              });
              context.pop();
            } else if (state is AddressError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Address Type Section
                    _buildSectionTitle('Address Type'),
                    const SizedBox(height: 16),
                    _buildAddressTypeSelector(),
                    const SizedBox(height: 24),
                    
                    // Address Details Section
                    _buildSectionTitle('Address Details'),
                    const SizedBox(height: 16),
                    _buildAddressFields(),
                    const SizedBox(height: 24),
                    
                    // Location Section
                    _buildSectionTitle('Location Coordinates'),
                    const SizedBox(height: 16),
                    _buildLocationFields(),
                    const SizedBox(height: 24),
                    
                    // Additional Info Section
                    _buildSectionTitle('Additional Information'),
                    const SizedBox(height: 16),
                    _buildAdditionalFields(),
                    const SizedBox(height: 32),
                    
                    // Save Button
                    AppButton(
                      text: isEditing ? 'Update Address' : 'Add Address',
                      onPressed: state is AddressLoading ? null : _saveAddress,
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.large,
                      fullWidth: true,
                      isLoading: state is AddressLoading,
                      icon: isEditing ? Icons.update : Icons.add_location,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildAddressTypeSelector() {
    return AppCard(
      contentPadding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick select buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _labelTypes.map((type) {
              final isSelected = _selectedLabelType == type;
              return FilterChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (_) => _onLabelTypeChanged(type),
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              );
            }).toList(),
          ),
          
          if (_selectedLabelType == 'Other') ...[
            const SizedBox(height: 16),
            AppInputField(
              controller: _labelController,
              labelText: 'Custom Label',
              hintText: 'Enter custom address label',
              prefixIcon: Icons.label_outline,
              required: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an address label';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressFields() {
    return Column(
      children: [
        AppInputField(
          controller: _fullAddressController,
          labelText: 'Full Address',
          hintText: 'Enter complete delivery address',
          prefixIcon: Icons.location_on_outlined,
          maxLines: 3,
          required: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter the full address';
            }
            if (value.trim().length < 10) {
              return 'Please enter a more detailed address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationFields() {
    return AppCard(
      contentPadding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppInputField(
                  controller: _latitudeController,
                  labelText: 'Latitude',
                  hintText: '37.7749',
                  prefixIcon: Icons.place,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  required: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    final latitude = double.tryParse(value.trim());
                    if (latitude == null || latitude < -90 || latitude > 90) {
                      return 'Invalid latitude';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppInputField(
                  controller: _longitudeController,
                  labelText: 'Longitude',
                  hintText: '-122.4194',
                  prefixIcon: Icons.place,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  required: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    final longitude = double.tryParse(value.trim());
                    if (longitude == null || longitude < -180 || longitude > 180) {
                      return 'Invalid longitude';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'Use Current Location',
            onPressed: _useCurrentLocation,
            variant: AppButtonVariant.outline,
            icon: Icons.my_location,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalFields() {
    return Column(
      children: [
        AppInputField(
          controller: _instructionsController,
          labelText: 'Delivery Instructions (Optional)',
          hintText: 'e.g., Ring doorbell, Leave at gate, etc.',
          prefixIcon: Icons.info_outline,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        
        // Default address toggle
        AppCard(
          contentPadding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.star_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set as Default Address',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This address will be pre-selected for deliveries',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value;
                    _hasUnsavedChanges = true;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
} 