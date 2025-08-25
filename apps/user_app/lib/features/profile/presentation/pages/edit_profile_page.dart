import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:user_app/features/auth/presentation/bloc/auth_bloc.dart';


class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with current user data
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      _nameController = TextEditingController(text: user.name);
      _phoneController = TextEditingController(text: user.phone ?? '');
    } else {
      _nameController = TextEditingController();
      _phoneController = TextEditingController();
    }
    
    // Listen for changes to track unsaved changes
    _nameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  void _onImageSelected() {
    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _pickImage() async {
    // Show image source selection dialog
    final ImageSource? source = await _showImageSourceDialog();
    if (source == null) return;

    // Check and request permissions
    if (source == ImageSource.camera) {
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        _showPermissionDeniedDialog('Camera');
        return;
      }
    } else {
      final photosStatus = await Permission.photos.request();
      if (!photosStatus.isGranted) {
        _showPermissionDeniedDialog('Photos');
        return;
      }
    }

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        _onImageSelected();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _hasUnsavedChanges = true;
    });
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    // TODO: Handle image upload to server and get URL
    String? profilePictureUrl;
    if (_selectedImage != null) {
      // In a real app, you would upload the image to your server/cloud storage
      // and get back the URL. For now, we'll use a placeholder.
      profilePictureUrl = 'uploaded_image_url';
    }

    context.read<AuthBloc>().add(AuthUpdateProfileEvent(
      name: name,
      phone: phone.isNotEmpty ? phone : null,
      profilePicture: profilePictureUrl,
    ));
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
          title: const Text('Edit Profile'),
          elevation: 0,
          actions: [
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return TextButton(
                  onPressed: state is AuthLoading ? null : _saveProfile,
                  child: state is AuthLoading
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
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              // Profile updated successfully
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Profile updated successfully'),
                  backgroundColor: theme.colorScheme.primary,
                ),
              );
              setState(() {
                _hasUnsavedChanges = false;
              });
              context.pop();
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is! AuthAuthenticated) {
              return const Center(
                child: Text('Please log in to edit your profile'),
              );
            }

            final user = state.user;
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile picture section
                    _buildProfilePictureSection(context, user),
                    const SizedBox(height: 32),
                    
                    // Form fields
                    _buildFormFields(context),
                    const SizedBox(height: 32),
                    
                    // Additional information
                    _buildAdditionalInfo(context, user),
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

  Widget _buildProfilePictureSection(BuildContext context, user) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        children: [
          // Profile picture
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 3,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipOval(
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : user.profilePicture != null
                        ? ClipOval(
                            child: Image.network(
                              user.profilePicture!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildDefaultAvatar(context, user),
                            ),
                          )
                        : _buildDefaultAvatar(context, user),
              ),
              
              // Edit button
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _pickImage,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Remove picture button (if image is selected or user has profile picture)
          if (_selectedImage != null || user.profilePicture != null)
            TextButton.icon(
              onPressed: _removeImage,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove Picture'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(BuildContext context, user) {
    final theme = Theme.of(context);
    final initials = _getInitials(user.name);

    return Center(
      child: Text(
        initials,
        style: theme.textTheme.headlineLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFormFields(BuildContext context) {
    return Column(
      children: [
        // Name field
        AppInputField(
          controller: _nameController,
          labelText: 'Full Name',
          hintText: 'Enter your full name',
          prefixIcon: Icons.person_outline,
          required: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your name';
            }
            if (value.trim().length < 2) {
              return 'Name must be at least 2 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        
        // Phone field
        AppInputField(
          controller: _phoneController,
          labelText: 'Phone Number',
          hintText: 'Enter your phone number (optional)',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              // Basic phone number validation
              final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
              if (!phoneRegex.hasMatch(value.trim())) {
                return 'Please enter a valid phone number';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo(BuildContext context, user) {

    return AppCard(
      title: 'Account Information',
      child: Column(
        children: [
          _buildInfoRow(
            context,
            'Email',
            user.email,
            Icons.email_outlined,
            isVerified: user.isEmailVerified,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            context,
            'User Role',
            _getUserRoleName(user.role),
            Icons.badge_outlined,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            context,
            'Member Since',
            _formatDate(user.createdAt),
            Icons.calendar_today_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isVerified = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.verified,
                      size: 16,
                      color: Colors.green,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionDeniedDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionType Permission Required'),
        content: Text(
          'This app needs $permissionType permission to update your profile picture. '
          'Please grant permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  String _getUserRoleName(role) {
    switch (role.toString().split('.').last) {
      case 'customer':
        return 'Customer';
      case 'vendor':
        return 'Vendor';
      case 'delivery':
        return 'Delivery Person';
      case 'admin':
        return 'Administrator';
      default:
        return 'User';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}