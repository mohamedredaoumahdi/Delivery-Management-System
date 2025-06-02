import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/menu_bloc.dart';

class MenuManagementPage extends StatefulWidget {
  const MenuManagementPage({super.key});

  @override
  State<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends State<MenuManagementPage> {
  String _selectedCategory = 'All';
  String _selectedFilter = 'All'; // All, Available, Unavailable
  String _selectedSort = 'Name A-Z'; // Name A-Z, Name Z-A, Price Low-High, Price High-Low, Recently Added
  String _searchQuery = '';
  final List<String> _categories = ['All', 'Main Course', 'Salads', 'Beverages', 'Desserts'];
  final List<String> _filters = ['All', 'Available', 'Unavailable'];
  final List<String> _sortOptions = ['Name A-Z', 'Name Z-A', 'Price Low-High', 'Price High-Low', 'Recently Added'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load menu items when page initializes
    context.read<MenuBloc>().add(LoadMenuItems());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddMenuItemDialog();
            },
            tooltip: 'Add Menu Item',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          // Category Filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.grey[100],
                    selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search menu items...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          
          // Menu Items List
          Expanded(
            child: BlocConsumer<MenuBloc, MenuState>(
              listener: (context, state) {
                if (state is MenuOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else if (state is MenuError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is MenuLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (state is MenuOperationLoading) {
                  return Stack(
                    children: [
                      // Show current items in background
                      _buildMenuList(state.currentItems),
                      // Show loading overlay
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${state.operation.replaceFirst(state.operation[0], state.operation[0].toUpperCase())}...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                if (state is MenuError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading menu items',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            context.read<MenuBloc>().add(LoadMenuItems());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is MenuLoaded || state is MenuOperationSuccess) {
                  final menuItems = state is MenuLoaded 
                      ? state.menuItems
                      : (state as MenuOperationSuccess).menuItems;
                      
                  return _buildMenuList(menuItems);
                }

                return const Center(
                  child: Text('No menu items available'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(Map<String, dynamic> menuItem) {
    // Improved availability detection - check multiple possible field names
    final isAvailable = _getItemAvailability(menuItem);
    final price = (menuItem['price'] as num).toDouble();
    final allergens = List<String>.from(menuItem['allergens'] ?? []);
    final dietaryTags = List<String>.from(menuItem['dietaryTags'] ?? menuItem['tags'] ?? []);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _showMenuItemDetails(menuItem);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Menu Item Image Placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.restaurant,
                  size: 40,
                  color: Colors.grey[400],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Menu Item Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            menuItem['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Switch(
                          value: isAvailable,
                          onChanged: (value) {
                            _toggleAvailability(menuItem['id'], value);
                          },
                          activeThumbColor: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      menuItem['description'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Text(
                          '\$${price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isAvailable ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isAvailable ? 'Available' : 'Unavailable',
                            style: TextStyle(
                              color: isAvailable ? Colors.green : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (allergens.isNotEmpty || dietaryTags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          ...dietaryTags.map((tag) => _buildTag(tag, Colors.green)),
                          ...allergens.map((allergen) => _buildTag(allergen, Colors.orange)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Action Buttons
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {
                      _editMenuItem(menuItem);
                    },
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      _deleteMenuItem(menuItem);
                    },
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to determine item availability from various possible field names
  bool _getItemAvailability(Map<String, dynamic> menuItem) {
    // Check in order of preference: isActive, inStock, isAvailable
    // These are the field names the backend might return
    if (menuItem['isActive'] != null) {
      return menuItem['isActive'] as bool;
    }
    if (menuItem['inStock'] != null) {
      return menuItem['inStock'] as bool;
    }
    if (menuItem['isAvailable'] != null) {
      return menuItem['isAvailable'] as bool;
    }
    
    // Default to true if no field is found
    return true;
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showMenuItemDetails(Map<String, dynamic> menuItem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Menu item details content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image placeholder
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.restaurant,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Text(
                          menuItem['name'],
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          '\$${(menuItem['price'] as double).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Text(
                          'Description:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          menuItem['description'],
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Text(
                          'Category: ${menuItem['category']}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          'Preparation Time: ${menuItem['preparationTime']} minutes',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        
                        if (menuItem['calories'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Calories: ${menuItem['calories']}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        
                        if ((menuItem['allergens'] as List).isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Allergens:',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (menuItem['allergens'] as List)
                                .map((allergen) => _buildTag(allergen.toString(), Colors.orange))
                                .toList(),
                          ),
                        ],
                        
                        if ((menuItem['dietaryTags'] as List).isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Dietary Information:',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (menuItem['dietaryTags'] as List)
                                .map((tag) => _buildTag(tag.toString(), Colors.green))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddMenuItemDialog() {
    _showMenuItemForm(isEditing: false);
  }

  void _showMenuItemForm({bool isEditing = false, Map<String, dynamic>? menuItem}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: isEditing ? menuItem!['name'] : '');
    final descriptionController = TextEditingController(text: isEditing ? menuItem!['description'] : '');
    final priceController = TextEditingController(text: isEditing ? (menuItem!['price'] as num).toString() : '');
    final preparationTimeController = TextEditingController(text: isEditing ? menuItem!['preparationTime']?.toString() ?? '15' : '15');
    
    String selectedCategory = isEditing ? menuItem!['categoryName'] ?? 'Main Course' : 'Main Course';
    bool isAvailable = isEditing ? _getItemAvailability(menuItem!) : true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Menu Item' : 'Add Menu Item'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name Field
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Item Name *',
                      hintText: 'e.g., Margherita Pizza',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an item name';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description Field
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Describe your delicious item...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      if (value.trim().length < 10) {
                        return 'Description must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Price Field
                  TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Price (\$) *',
                      hintText: '12.99',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a price';
                      }
                      final price = double.tryParse(value.trim());
                      if (price == null || price < 0) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Main Course', 'Salads', 'Beverages', 'Desserts', 'Appetizers', 'Sides']
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Preparation Time Field
                  TextFormField(
                    controller: preparationTimeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Preparation Time (minutes)',
                      hintText: '15',
                      border: OutlineInputBorder(),
                      suffixText: 'min',
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final time = int.tryParse(value.trim());
                        if (time == null || time < 0) {
                          return 'Please enter a valid preparation time';
                        }
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Availability Switch
                  SwitchListTile(
                    title: const Text('Available'),
                    subtitle: Text(isAvailable ? 'Item is available for orders' : 'Item is currently unavailable'),
                    value: isAvailable,
                    onChanged: (value) {
                      setState(() {
                        isAvailable = value;
                      });
                    },
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
              onPressed: () => _saveMenuItem(
                context,
                formKey,
                nameController,
                descriptionController,
                priceController,
                preparationTimeController,
                selectedCategory,
                isAvailable,
                isEditing,
                menuItem?['id'],
              ),
              child: Text(isEditing ? 'Update' : 'Add Item'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveMenuItem(
    BuildContext context,
    GlobalKey<FormState> formKey,
    TextEditingController nameController,
    TextEditingController descriptionController,
    TextEditingController priceController,
    TextEditingController preparationTimeController,
    String selectedCategory,
    bool isAvailable,
    bool isEditing,
    String? itemId,
  ) {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final data = {
      'name': nameController.text.trim(),
      'description': descriptionController.text.trim(),
      'price': double.parse(priceController.text.trim()),
      'categoryName': selectedCategory,
      'inStock': isAvailable,
    };

    // Add preparation time if provided
    if (preparationTimeController.text.isNotEmpty) {
      data['preparationTime'] = int.parse(preparationTimeController.text.trim());
    }

    Navigator.pop(context);

    if (isEditing && itemId != null) {
      context.read<MenuBloc>().add(UpdateMenuItem(itemId, data));
    } else {
      context.read<MenuBloc>().add(CreateMenuItem(data));
    }
  }

  void _toggleAvailability(String itemId, bool isAvailable) {
    // Call the bloc to toggle availability
    context.read<MenuBloc>().add(ToggleMenuItemAvailability(itemId, isAvailable));
  }

  // Helper method to get menu item by ID for the edit action
  Map<String, dynamic> _getMenuItemById(String itemId) {
    return context.read<MenuBloc>().state is MenuLoaded 
        ? (context.read<MenuBloc>().state as MenuLoaded).menuItems.firstWhere(
            (item) => item['id'] == itemId,
            orElse: () => <String, dynamic>{},
          )
        : <String, dynamic>{};
  }

  void _editMenuItem(Map<String, dynamic> menuItem) {
    _showMenuItemForm(isEditing: true, menuItem: menuItem);
  }

  void _deleteMenuItem(Map<String, dynamic> menuItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this item?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.restaurant, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          menuItem['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${(menuItem['price'] as double).toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<MenuBloc>().add(DeleteMenuItem(menuItem['id']));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList(List<Map<String, dynamic>> menuItems) {
    // Apply filtering and searching
    List<Map<String, dynamic>> filteredItems = menuItems.where((item) {
      // Category filter
      bool categoryMatch = _selectedCategory == 'All' ||
          (item['categoryName'] ?? item['category']) == _selectedCategory;

      // Availability filter
      bool availabilityMatch = true;
      if (_selectedFilter != 'All') {
        final isAvailable = _getItemAvailability(item);
        availabilityMatch = (_selectedFilter == 'Available' && isAvailable) ||
                           (_selectedFilter == 'Unavailable' && !isAvailable);
      }

      // Search filter
      bool searchMatch = _searchQuery.isEmpty ||
          item['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['description'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

      return categoryMatch && availabilityMatch && searchMatch;
    }).toList();

    // Apply sorting
    filteredItems.sort((a, b) {
      switch (_selectedSort) {
        case 'Name A-Z':
          return a['name'].toString().compareTo(b['name'].toString());
        case 'Name Z-A':
          return b['name'].toString().compareTo(a['name'].toString());
        case 'Price Low-High':
          return (a['price'] as num).compareTo(b['price'] as num);
        case 'Price High-Low':
          return (b['price'] as num).compareTo(a['price'] as num);
        case 'Recently Added':
          final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA);
        default:
          return 0;
      }
    });

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.restaurant_menu,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'No items found'
                  : 'No menu items found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search or filters'
                  : _selectedFilter == 'All' && _selectedCategory == 'All'
                      ? 'Add your first menu item to get started'
                      : 'No items match your current filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isNotEmpty || _selectedFilter != 'All' || _selectedCategory != 'All')
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedFilter = 'All';
                    _selectedCategory = 'All';
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  _showAddMenuItemDialog();
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Menu Item'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<MenuBloc>().add(LoadMenuItems());
      },
      child: Column(
        children: [
          // Results summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${filteredItems.length} item${filteredItems.length != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_selectedFilter != 'All' || _searchQuery.isNotEmpty || _selectedCategory != 'All') ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'filtered',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  'Sort: $_selectedSort',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          
          // Menu items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final menuItem = filteredItems[index];
                return _buildMenuItemCard(menuItem);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Menu Options',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage your restaurant menu',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              children: [
                // Quick Actions Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                
                ListTile(
                  leading: const Icon(Icons.refresh, color: Colors.blue),
                  title: const Text('Reload Menu'),
                  subtitle: const Text('Refresh all menu items'),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<MenuBloc>().add(LoadMenuItems());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Reloading menu...'),
                        backgroundColor: Colors.blue,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.add_circle, color: Colors.green),
                  title: const Text('Add New Item'),
                  subtitle: const Text('Create a new menu item'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddMenuItemDialog();
                  },
                ),
                
                const Divider(),
                
                // Filter Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Filter Options',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                
                ..._filters.map((filter) => RadioListTile<String>(
                  title: Text(filter),
                  subtitle: Text(_getFilterDescription(filter)),
                  value: filter,
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                    Navigator.pop(context);
                  },
                )),
                
                const Divider(),
                
                // Sort Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Sort Options',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                
                ..._sortOptions.map((sort) => RadioListTile<String>(
                  title: Text(sort),
                  value: sort,
                  groupValue: _selectedSort,
                  onChanged: (value) {
                    setState(() {
                      _selectedSort = value!;
                    });
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
          ),
          
          // Footer with current filter/sort info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Settings',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.filter_list, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('Filter: $_selectedFilter', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.sort, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('Sort: $_selectedSort', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getFilterDescription(String filter) {
    switch (filter) {
      case 'All':
        return 'Show all menu items';
      case 'Available':
        return 'Show only available items';
      case 'Unavailable':
        return 'Show only unavailable items';
      default:
        return '';
    }
  }
} 