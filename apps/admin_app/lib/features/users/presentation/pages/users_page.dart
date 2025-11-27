import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../common/widgets/admin_layout.dart';
import '../../data/models/user_model.dart';
import '../bloc/user_bloc.dart';
import '../bloc/user_event.dart';
import '../bloc/user_state.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  String? _selectedRole;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters(BuildContext context) {
    if (mounted) {
      final bloc = context.read<UserBloc>();
      final role = _selectedRole;
      final searchQuery = _searchController.text.isEmpty ? null : _searchController.text.trim();
      
      bloc.add(FilterUsers(
        role: role,
        searchQuery: searchQuery,
      ));
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'CUSTOMER':
        return 'Customer';
      case 'VENDOR':
        return 'Vendor';
      case 'DELIVERY':
        return 'Delivery';
      case 'ADMIN':
        return 'Admin';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 800;
    final horizontalPadding = isMobile ? 16.0 : 24.0;
    
    return BlocProvider(
      create: (context) => GetIt.instance<UserBloc>()..add(const LoadUsers()),
      child: BlocConsumer<UserBloc, UserState>(
        listenWhen: (previous, current) =>
            current is UserCreated ||
            current is UserUpdated ||
            current is UserDeleted ||
            current is UserError,
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state is UserCreated) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('User created successfully'),
              ),
            );
          } else if (state is UserUpdated) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('${state.user.name} updated successfully'),
              ),
            );
          } else if (state is UserDeleted) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('User deleted successfully'),
              ),
            );
          } else if (state is UserError) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (blocContext, state) => AdminLayout(
          showAppBar: false,
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 0.0, horizontalPadding, 24.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Enhanced Header
                    Padding(
                      padding: EdgeInsets.only(top: isMobile ? 16.0 : 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.people_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'All Users',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontSize: isMobile ? 22 : 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  BlocBuilder<UserBloc, UserState>(
                                    builder: (context, state) {
                                      if (state is UsersLoaded) {
                                        return Text(
                                          '${state.filteredUsers.length} of ${state.users.length} users',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.grey[400]
                                                    : Colors.grey[600],
                                                fontSize: isMobile ? 12 : 14,
                                              ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              if (_selectedRole != null || _searchController.text.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 10 : 14,
                                    vertical: isMobile ? 6 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.filter_alt,
                                        size: isMobile ? 14 : 16,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Filtered',
                                        style: TextStyle(
                                          fontSize: isMobile ? 11 : 12,
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.black.withOpacity(0.3)
                                          : Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.tune_rounded,
                                    size: isMobile ? 20 : 22,
                                  ),
                                  onPressed: () => _showFilterDialog(blocContext),
                                  tooltip: 'Filter Users',
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: () => _showUserFormDialog(blocContext),
                                icon: const Icon(Icons.person_add_alt_1_rounded),
                                label: Text(isMobile ? 'Add' : 'Add User'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    
                    // Enhanced Search Bar
                    Builder(
                      builder: (context) {
                        final theme = Theme.of(context);
                        final isDark = theme.brightness == Brightness.dark;
                        return StatefulBuilder(
                          builder: (context, setState) {
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark 
                                        ? Colors.black.withOpacity(0.3)
                                        : Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search by name, email, or phone...',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {});
                                            _applyFilters(blocContext);
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                  _applyFilters(blocContext);
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    
                    // Users List
                    BlocBuilder<UserBloc, UserState>(
                      builder: (context, state) {
                        if (state is UserLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        
                        if (state is UserError) {
                          final theme = Theme.of(context);
                          final isDark = theme.brightness == Brightness.dark;
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Error loading users',
                                      style: TextStyle(color: Colors.red[700], fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      state.message,
                                      style: TextStyle(
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        context.read<UserBloc>().add(const LoadUsers());
                                      },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        
                        if (state is UsersLoaded) {
                          final users = state.filteredUsers;
                          
                          if (users.isEmpty) {
                            final theme = Theme.of(context);
                            final isDark = theme.brightness == Brightness.dark;
                            return Card(
                              child: Padding(
                                padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                                child: Container(
                                  constraints: BoxConstraints(
                                    minHeight: MediaQuery.of(context).size.height * 0.4,
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.people_outline,
                                          size: isMobile ? 48 : 64,
                                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                                        ),
                                        SizedBox(height: isMobile ? 12 : 16),
                                        Text(
                                          'No users found',
                                          style: TextStyle(
                                            color: isDark ? Colors.grey[300] : Colors.grey[600],
                                            fontSize: isMobile ? 14 : 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _selectedRole != null || _searchController.text.isNotEmpty
                                              ? 'Try adjusting your filters'
                                              : 'Users will appear here once loaded',
                                          style: TextStyle(
                                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                                            fontSize: isMobile ? 11 : 12,
                                          ),
                                        ),
                                        if (_selectedRole != null || _searchController.text.isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _selectedRole = null;
                                                _searchController.clear();
                                              });
                                              _applyFilters(blocContext);
                                            },
                                            icon: const Icon(Icons.clear_all, size: 16),
                                            label: const Text('Clear Filters'),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          
                          return Column(
                            children: [
                              // Active Filters Display
                              if (_selectedRole != null || _searchController.text.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.filter_alt,
                                        size: 20,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            if (_selectedRole != null)
                                              _FilterChip(
                                                label: _getRoleDisplayName(_selectedRole!),
                                                onRemove: () {
                                                  setState(() {
                                                    _selectedRole = null;
                                                  });
                                                  _applyFilters(blocContext);
                                                },
                                              ),
                                            if (_searchController.text.isNotEmpty)
                                              _FilterChip(
                                                label: 'Search: "${_searchController.text}"',
                                                onRemove: () {
                                                  _searchController.clear();
                                                  setState(() {});
                                                  _applyFilters(blocContext);
                                                },
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // Users List
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                                  child: Column(
                                    children: [
                                      // Table Header
                                      if (!isMobile)
                                        Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white.withOpacity(0.05)
                                                : Colors.grey[50],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Row(
                                            children: [
                                              Expanded(flex: 2, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                              Expanded(flex: 2, child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                              Expanded(child: Text('Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                              Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                              Expanded(child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                            ],
                                          ),
                                        ),
                                      if (!isMobile) const SizedBox(height: 8),
                                      // Table Body
                                      ...users.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final user = entry.value;
                                        return _UserRow(
                                          user: user,
                                          isMobile: isMobile,
                                          isLast: index == users.length - 1,
                                          onEdit: () => _showUserFormDialog(blocContext, user: user),
                                          onDelete: () {
                                            _showDeleteDialog(blocContext, user);
                                          },
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext blocContext) {
    String? tempRole = _selectedRole;
    
    showDialog(
      context: blocContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: Theme.of(dialogContext).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const Text('Filter Users'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: tempRole,
                  decoration: InputDecoration(
                    labelText: 'User Role',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Roles')),
                    DropdownMenuItem(value: 'CUSTOMER', child: Text('Customer')),
                    DropdownMenuItem(value: 'VENDOR', child: Text('Vendor')),
                    DropdownMenuItem(value: 'DELIVERY', child: Text('Delivery')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      tempRole = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  setState(() {
                    _selectedRole = null;
                  });
                  _applyFilters(blocContext);
                },
                child: const Text('Clear All'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  setState(() {
                    _selectedRole = tempRole;
                  });
                  _applyFilters(blocContext);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUserFormDialog(BuildContext context, {UserModel? user}) {
    final isEditMode = user != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final passwordController = TextEditingController();
    String selectedRole = user?.role ?? 'CUSTOMER';
    bool isActive = user?.isActive ?? true;
    bool isEmailVerified = user?.isEmailVerified ?? false;
    bool isPhoneVerified = user?.isPhoneVerified ?? false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    isEditMode ? Icons.edit_rounded : Icons.person_add_alt_1_rounded,
                    color: Theme.of(dialogContext).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(isEditMode ? 'Edit User' : 'Add New User'),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(dialogContext).size.width > 600 ? 520 : double.maxFinite,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Name is required';
                            }
                            if (value.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailController,
                          enabled: !isEditMode,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'CUSTOMER', child: Text('Customer')),
                            DropdownMenuItem(value: 'VENDOR', child: Text('Vendor')),
                            DropdownMenuItem(value: 'DELIVERY', child: Text('Delivery')),
                            DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedRole = value;
                              });
                            }
                          },
                        ),
                        if (!isEditMode) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Temporary Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (value) {
                              if (!isEditMode && (value == null || value.trim().length < 8)) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          value: isActive,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) {
                            setDialogState(() {
                              isActive = value;
                            });
                          },
                          title: const Text('Active'),
                          subtitle: const Text('Users must be active to log in'),
                        ),
                        SwitchListTile.adaptive(
                          value: isEmailVerified,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) {
                            setDialogState(() {
                              isEmailVerified = value;
                            });
                          },
                          title: const Text('Email Verified'),
                        ),
                        SwitchListTile.adaptive(
                          value: isPhoneVerified,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) {
                            setDialogState(() {
                              isPhoneVerified = value;
                            });
                          },
                          title: const Text('Phone Verified'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          setDialogState(() {
                            isSubmitting = true;
                          });
                          final payload = <String, dynamic>{
                            'name': nameController.text.trim(),
                            'email': emailController.text.trim(),
                            'phone': phoneController.text.trim().isEmpty
                                ? null
                                : phoneController.text.trim(),
                            'role': selectedRole,
                            'isActive': isActive,
                            'isEmailVerified': isEmailVerified,
                            'isPhoneVerified': isPhoneVerified,
                          };
                          if (isEditMode) {
                            context.read<UserBloc>().add(UpdateUser(user.id, payload));
                          } else {
                            payload['password'] = passwordController.text.trim();
                            context.read<UserBloc>().add(CreateUser(payload));
                          }
                          Navigator.pop(dialogContext);
                        },
                  child: isSubmitting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(dialogContext).colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Text(isEditMode ? 'Save Changes' : 'Create User'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      passwordController.dispose();
    });
  }

  void _showDeleteDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<UserBloc>().add(DeleteUser(user.id));
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final UserModel user;
  final bool isMobile;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserRow({
    required this.user,
    required this.isMobile,
    this.isLast = false,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (isMobile) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getRoleColor(user.role).withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user.role).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getRoleIcon(user.role),
                      color: _getRoleColor(user.role),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(isActive: user.isActive),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.email,
                      label: 'Email',
                      value: user.email,
                    ),
                    if (user.phone != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.phone,
                        label: 'Phone',
                        value: user.phone!,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.badge,
                      label: 'Role',
                      value: _getRoleDisplayName(user.role),
                      isHighlight: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isLast ? null : Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Name & Phone
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getRoleIcon(user.role),
                    color: _getRoleColor(user.role),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.phone != null)
                        Text(
                          user.phone!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Email
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(Icons.email_outlined, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[300] : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Role
          Expanded(
            child: _RoleChip(role: user.role),
          ),
          // Status
          Expanded(
            child: _StatusChip(isActive: user.isActive),
          ),
          // Actions
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                  color: Theme.of(context).colorScheme.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outlined, size: 18),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'CUSTOMER':
        return Colors.blue;
      case 'VENDOR':
        return Colors.green;
      case 'DELIVERY':
        return Colors.orange;
      case 'ADMIN':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'CUSTOMER':
        return Icons.person_rounded;
      case 'VENDOR':
        return Icons.store_rounded;
      case 'DELIVERY':
        return Icons.delivery_dining_rounded;
      case 'ADMIN':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'CUSTOMER':
        return 'Customer';
      case 'VENDOR':
        return 'Vendor';
      case 'DELIVERY':
        return 'Delivery';
      case 'ADMIN':
        return 'Admin';
      default:
        return role;
    }
  }
}

class _RoleChip extends StatelessWidget {
  final String role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (role) {
      case 'CUSTOMER':
        color = Colors.blue;
        break;
      case 'VENDOR':
        color = Colors.green;
        break;
      case 'DELIVERY':
        color = Colors.orange;
        break;
      case 'ADMIN':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? Colors.green : Colors.red,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// Info Row Widget for Mobile View
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isHighlight;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isHighlight 
              ? Colors.blue[700]
              : (isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight 
                  ? Colors.blue[700]
                  : (isDark ? Colors.grey[200] : Colors.grey[800]),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
