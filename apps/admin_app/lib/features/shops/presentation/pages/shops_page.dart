import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/widgets/admin_layout.dart';
import '../../data/models/shop_model.dart';
import '../../data/shop_service.dart';
import '../bloc/shop_bloc.dart';
import '../bloc/shop_event.dart';
import '../bloc/shop_state.dart';
import '../widgets/shop_form_dialog.dart';

class ShopsPage extends StatefulWidget {
  const ShopsPage({super.key});

  @override
  State<ShopsPage> createState() => _ShopsPageState();
}

class _ShopsPageState extends State<ShopsPage> {
  String? _selectedCategory;
  bool? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters(BuildContext context) {
    if (mounted) {
      final bloc = context.read<ShopBloc>();
      final category = _selectedCategory;
      final status = _selectedStatus;
      final searchQuery = _searchController.text.isEmpty ? null : _searchController.text.trim();
      
      bloc.add(FilterShops(
        category: category,
        searchQuery: searchQuery,
        isActive: status,
      ));
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'RESTAURANT':
        return 'Restaurant';
      case 'GROCERY':
        return 'Grocery';
      case 'PHARMACY':
        return 'Pharmacy';
      case 'RETAIL':
        return 'Retail';
      case 'OTHER':
        return 'Other';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 800;
    final horizontalPadding = isMobile ? 16.0 : 24.0;
    
    return BlocProvider(
      create: (context) => GetIt.instance<ShopBloc>()..add(const LoadShops()),
      child: Builder(
        builder: (blocContext) => BlocListener<ShopBloc, ShopState>(
          listener: (context, state) {
            if (state is ShopCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Shop "${state.shop.name}" created successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is ShopError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: AdminLayout(
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
                                  Icons.store_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'All Shops',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontSize: isMobile ? 22 : 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  BlocBuilder<ShopBloc, ShopState>(
                                    builder: (context, state) {
                                      if (state is ShopsLoaded) {
                                        return Text(
                                          '${state.filteredShops.length} of ${state.shops.length} shops',
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
                              // Active Filters Indicator
                              if (_selectedCategory != null || _selectedStatus != null || _searchController.text.isNotEmpty)
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
                              // Filter Button
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
                                  tooltip: 'Filter Shops',
                                ),
                              ),
                              // Add Shop Button
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
                                    Icons.add_rounded,
                                    size: isMobile ? 20 : 22,
                                  ),
                                  onPressed: () => _showAddShopDialog(blocContext),
                                  tooltip: 'Add New Shop',
                                ),
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
                                  hintText: 'Search by name, address, or email...',
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
                    
                    // Shops List
                    BlocBuilder<ShopBloc, ShopState>(
                      builder: (context, state) {
                        if (state is ShopLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        
                        if (state is ShopError) {
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
                                      'Error loading shops',
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
                                        context.read<ShopBloc>().add(const LoadShops());
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
                        
                        if (state is ShopsLoaded) {
                          final shops = state.filteredShops;
                          
                          if (shops.isEmpty) {
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
                                          Icons.store_outlined,
                                          size: isMobile ? 48 : 64,
                                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                                        ),
                                        SizedBox(height: isMobile ? 12 : 16),
                                        Text(
                                          'No shops found',
                                          style: TextStyle(
                                            color: isDark ? Colors.grey[300] : Colors.grey[600],
                                            fontSize: isMobile ? 14 : 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _selectedCategory != null || _selectedStatus != null || _searchController.text.isNotEmpty
                                              ? 'Try adjusting your filters'
                                              : 'Shops will appear here once loaded',
                                          style: TextStyle(
                                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                                            fontSize: isMobile ? 11 : 12,
                                          ),
                                        ),
                                        if (_selectedCategory != null || _selectedStatus != null || _searchController.text.isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _selectedCategory = null;
                                                _selectedStatus = null;
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
                              if (_selectedCategory != null || _selectedStatus != null || _searchController.text.isNotEmpty)
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
                                            if (_selectedCategory != null)
                                              _FilterChip(
                                                label: _getCategoryDisplayName(_selectedCategory!),
                                                onRemove: () {
                                                  setState(() {
                                                    _selectedCategory = null;
                                                  });
                                                  _applyFilters(blocContext);
                                                },
                                              ),
                                            if (_selectedStatus != null)
                                              _FilterChip(
                                                label: _selectedStatus! ? 'Active' : 'Inactive',
                                                onRemove: () {
                                                  setState(() {
                                                    _selectedStatus = null;
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
                              // Shops List
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
                                              Expanded(flex: 2, child: Text('Shop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                              Expanded(flex: 2, child: Text('Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                              Expanded(child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                              Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                              Expanded(child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                            ],
                                          ),
                                        ),
                                      if (!isMobile) const SizedBox(height: 8),
                                      // Table Body
                                      ...shops.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final shop = entry.value;
                                        return _ShopRow(
                                          shop: shop,
                                          isMobile: isMobile,
                                          isLast: index == shops.length - 1,
                                          onEdit: () {
                                            _showEditShopDialog(blocContext, shop);
                                          },
                                          onDelete: () {
                                            _showDeleteDialog(blocContext, shop);
                                          },
                                          onToggleStatus: () {
                                            blocContext.read<ShopBloc>().add(UpdateShop(
                                              shop.id,
                                              {'isActive': !shop.isActive},
                                            ));
                                          },
                                          onApprove: () {
                                            _showApproveDialog(blocContext, shop);
                                          },
                                          onReject: () {
                                            _showRejectDialog(blocContext, shop);
                                          },
                                          onSuspend: () {
                                            _showSuspendDialog(blocContext, shop);
                                          },
                                          onViewPerformance: () {
                                            context.go('/shops/${shop.id}/performance');
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
      ),
    );
  }

  void _showAddShopDialog(BuildContext blocContext) {
    showDialog(
      context: blocContext,
      builder: (context) => ShopFormDialog(
        onSave: (shopData) {
          blocContext.read<ShopBloc>().add(CreateShop(shopData));
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditShopDialog(BuildContext blocContext, ShopModel shop) {
    showDialog(
      context: blocContext,
      builder: (context) => ShopFormDialog(
        shop: shop,
        onSave: (shopData) {
          blocContext.read<ShopBloc>().add(UpdateShop(shop.id, shopData));
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showFilterDialog(BuildContext blocContext) {
    String? tempCategory = _selectedCategory;
    bool? tempStatus = _selectedStatus;
    
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
                const Text('Filter Shops'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: tempCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.category_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Categories')),
                    DropdownMenuItem(value: 'RESTAURANT', child: Text('Restaurant')),
                    DropdownMenuItem(value: 'GROCERY', child: Text('Grocery')),
                    DropdownMenuItem(value: 'PHARMACY', child: Text('Pharmacy')),
                    DropdownMenuItem(value: 'RETAIL', child: Text('Retail')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      tempCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<bool?>(
                  initialValue: tempStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.toggle_on_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Statuses')),
                    DropdownMenuItem(value: true, child: Text('Active')),
                    DropdownMenuItem(value: false, child: Text('Inactive')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      tempStatus = value;
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
                    _selectedCategory = null;
                    _selectedStatus = null;
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
                    _selectedCategory = tempCategory;
                    _selectedStatus = tempStatus;
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

  void _showApproveDialog(BuildContext blocContext, ShopModel shop) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: blocContext,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('Approve Vendor'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to approve "${shop.name}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Add a note about the approval',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final shopService = GetIt.instance<ShopService>();
                await shopService.approveVendor(shop.id, reason: reasonController.text.isEmpty ? null : reasonController.text);
                if (blocContext.mounted) {
                  Navigator.pop(dialogContext);
                  blocContext.read<ShopBloc>().add(const RefreshShops());
                  ScaffoldMessenger.of(blocContext).showSnackBar(
                    const SnackBar(content: Text('Vendor approved successfully'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext blocContext, ShopModel shop) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: blocContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cancel, color: Colors.red),
              SizedBox(width: 12),
              Text('Reject Vendor'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Are you sure you want to reject "${shop.name}"?'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Rejection Reason *',
                    hintText: 'Please provide a reason for rejection',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Reason is required' : null,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final shopService = GetIt.instance<ShopService>();
                  await shopService.rejectVendor(shop.id, reasonController.text);
                  if (blocContext.mounted) {
                    Navigator.pop(dialogContext);
                    blocContext.read<ShopBloc>().add(const RefreshShops());
                    ScaffoldMessenger.of(blocContext).showSnackBar(
                      const SnackBar(content: Text('Vendor rejected successfully'), backgroundColor: Colors.orange),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuspendDialog(BuildContext blocContext, ShopModel shop) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: blocContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.block, color: Colors.orange),
              SizedBox(width: 12),
              Text('Suspend Vendor'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Are you sure you want to suspend "${shop.name}"?'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Suspension Reason *',
                    hintText: 'Please provide a reason for suspension',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Reason is required' : null,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final shopService = GetIt.instance<ShopService>();
                  await shopService.suspendVendor(shop.id, reasonController.text);
                  if (blocContext.mounted) {
                    Navigator.pop(dialogContext);
                    blocContext.read<ShopBloc>().add(const RefreshShops());
                    ScaffoldMessenger.of(blocContext).showSnackBar(
                      const SnackBar(content: Text('Vendor suspended successfully'), backgroundColor: Colors.orange),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Suspend'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ShopModel shop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shop'),
        content: Text('Are you sure you want to delete ${shop.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ShopBloc>().add(DeleteShop(shop.id));
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

class _ShopRow extends StatelessWidget {
  final ShopModel shop;
  final bool isMobile;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onSuspend;
  final VoidCallback onViewPerformance;

  const _ShopRow({
    required this.shop,
    required this.isMobile,
    this.isLast = false,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    required this.onApprove,
    required this.onReject,
    required this.onSuspend,
    required this.onViewPerformance,
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
            color: _getCategoryColor(shop.category).withOpacity(0.2),
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
                      color: _getCategoryColor(shop.category).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getCategoryIcon(shop.category),
                      color: _getCategoryColor(shop.category),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shop.address,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(isActive: shop.isActive),
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
                      value: shop.email,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.phone,
                      label: 'Phone',
                      value: shop.phone,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.category,
                      label: 'Category',
                      value: _getCategoryDisplayName(shop.category),
                      isHighlight: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (!shop.isActive) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (shop.isActive)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onSuspend,
                      icon: const Icon(Icons.block, size: 16),
                      label: const Text('Suspend'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onViewPerformance,
                      icon: const Icon(Icons.analytics, size: 16),
                      label: const Text('Performance'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onToggleStatus,
                  icon: Icon(
                    shop.isActive ? Icons.block : Icons.check_circle,
                    size: 16,
                  ),
                  label: Text(shop.isActive ? 'Deactivate' : 'Activate'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
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
          // Shop Name & Address
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(shop.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(shop.category),
                    color: _getCategoryColor(shop.category),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shop.address,
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
          // Contact
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.email_outlined, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        shop.email,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        shop.phone,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Category
          Expanded(
            child: _CategoryChip(category: shop.category),
          ),
          // Status
          Expanded(
            child: _StatusChip(isActive: shop.isActive),
          ),
          // Actions
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!shop.isActive)
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    onPressed: onApprove,
                    tooltip: 'Approve',
                    color: Colors.green,
                  ),
                if (!shop.isActive)
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    onPressed: onReject,
                    tooltip: 'Reject',
                    color: Colors.red,
                  ),
                if (shop.isActive)
                  IconButton(
                    icon: const Icon(Icons.block_outlined, size: 18),
                    onPressed: onSuspend,
                    tooltip: 'Suspend',
                    color: Colors.orange,
                  ),
                IconButton(
                  icon: Icon(
                    shop.isActive ? Icons.block_outlined : Icons.check_circle_outline,
                    size: 18,
                  ),
                  onPressed: onToggleStatus,
                  tooltip: shop.isActive ? 'Deactivate' : 'Activate',
                  color: shop.isActive ? Colors.orange : Colors.green,
                ),
                IconButton(
                  icon: const Icon(Icons.analytics_outlined, size: 18),
                  onPressed: onViewPerformance,
                  tooltip: 'View Performance',
                  color: Colors.blue,
                ),
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'RESTAURANT':
        return Colors.deepOrange;
      case 'GROCERY':
        return Colors.green;
      case 'PHARMACY':
        return Colors.blue;
      case 'RETAIL':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'RESTAURANT':
        return Icons.restaurant_rounded;
      case 'GROCERY':
        return Icons.shopping_cart_rounded;
      case 'PHARMACY':
        return Icons.local_pharmacy_rounded;
      case 'RETAIL':
        return Icons.store_rounded;
      default:
        return Icons.store_rounded;
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'RESTAURANT':
        return 'Restaurant';
      case 'GROCERY':
        return 'Grocery';
      case 'PHARMACY':
        return 'Pharmacy';
      case 'RETAIL':
        return 'Retail';
      case 'OTHER':
        return 'Other';
      default:
        return category;
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (category) {
      case 'RESTAURANT':
        color = Colors.deepOrange;
        break;
      case 'GROCERY':
        color = Colors.green;
        break;
      case 'PHARMACY':
        color = Colors.blue;
        break;
      case 'RETAIL':
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
        category,
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
