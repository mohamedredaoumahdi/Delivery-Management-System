import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:domain/domain.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user_app/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:flutter/rendering.dart';

import '../bloc/shop_details_bloc.dart';
import '../bloc/product_list_bloc.dart';
import '../widgets/product_grid_item.dart';
import '../widgets/shop_info_card.dart';

class ShopDetailsPage extends StatefulWidget {
  final String shopId;

  const ShopDetailsPage({
    super.key,
    required this.shopId,
  });

  @override
  State<ShopDetailsPage> createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends State<ShopDetailsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  late TextEditingController _searchController;
  
  bool _isSearching = false;
  List<String> _categories = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    
    // Load shop details and products
    context.read<ShopDetailsBloc>().add(ShopDetailsLoadEvent(widget.shopId));
    context.read<ProductListBloc>().add(ProductListLoadEvent(shopId: widget.shopId));
    
    // Listen for scroll to handle pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // Load more products when user is near the bottom
      final state = context.read<ProductListBloc>().state;
      if (state is ProductListLoaded && state.hasMore) {
        context.read<ProductListBloc>().add(ProductListLoadMoreEvent());
      }
    }
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    
    if (query.isNotEmpty) {
      context.read<ProductListBloc>().add(ProductListSearchEvent(
        shopId: widget.shopId,
        query: query,
        category: _selectedCategory,
      ));
    } else {
      context.read<ProductListBloc>().add(ProductListLoadEvent(
        shopId: widget.shopId,
        category: _selectedCategory,
      ));
    }
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<ProductListBloc>().add(ProductListLoadEvent(
      shopId: widget.shopId,
      category: _selectedCategory,
    ));
    setState(() {
      _isSearching = false;
    });
  }

  void _filterByCategory(String? category) {
    print('🏷️ Filtering by category: $category');
    
    setState(() {
      _selectedCategory = category;
    });
    
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      context.read<ProductListBloc>().add(ProductListSearchEvent(
        shopId: widget.shopId,
        query: query,
        category: category,
      ));
    } else {
      context.read<ProductListBloc>().add(ProductListLoadEvent(
        shopId: widget.shopId,
        category: category,
      ));
    }
  }

  void _addToCart(Product product) {
    context.read<CartBloc>().add(CartAddItemEvent(
      product: product,
      shopId: widget.shopId,
      shopName: '', // Will be filled by the shop state
      quantity: 1,
    ));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => context.go('/cart'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocConsumer<ShopDetailsBloc, ShopDetailsState>(
        listener: (context, state) {
          if (state is ShopDetailsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, shopState) {
          if (shopState is ShopDetailsLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (shopState is ShopDetailsError) {
            return _buildErrorState(context, shopState.message);
          }

          if (shopState is ShopDetailsLoaded) {
            final shop = shopState.shop;
            
            return NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  // App bar with shop cover image
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Cover image
                          shop.coverImageUrl != null
                              ? Image.network(
                                  shop.coverImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: theme.colorScheme.primary,
                                        child: const Icon(
                                          Icons.store,
                                          size: 64,
                                          color: Colors.white,
                                        ),
                                      ),
                                )
                              : Container(
                                  color: theme.colorScheme.primary,
                                  child: const Icon(
                                    Icons.store,
                                    size: 64,
                                    color: Colors.white,
                                  ),
                                ),
                          
                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () {
                          // Implement share functionality
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () {
                          // Implement favorite functionality
                        },
                      ),
                    ],
                  ),
                ];
              },
              body: Column(
                children: [
                  // Shop info section
                  ShopInfoCard(shop: shop),
                  
                  // Tab bar for Products and Info
                  Material(
                    color: theme.colorScheme.surface,
                    child: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Products'),
                        Tab(text: 'Info'),
                      ],
                      labelStyle: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: theme.textTheme.titleSmall,
                      indicatorWeight: 3,
                    ),
                  ),
                  
                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Products tab
                        _buildProductsTab(context, shop),
                        
                        // Info tab
                        _buildInfoTab(context, shop),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // Default loading state
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  Widget _buildProductsTab(BuildContext context, Shop shop) {
    return Column(
      children: [
        // Search and filter section
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              // Search bar
              AppInputField(
                controller: _searchController,
                hintText: 'Search products...',
                prefixIcon: Icons.search,
                suffixIcon: _searchController.text.isNotEmpty 
                    ? Icons.clear 
                    : null,
                onSuffixIconPressed: _searchController.text.isNotEmpty 
                    ? _clearSearch 
                    : null,
                onSubmitted: (_) => _performSearch(),
                onChanged: (value) {
                  setState(() {
                    _isSearching = value.isNotEmpty;
                  });
                  if (value.isEmpty) {
                    _clearSearch();
                  }
                },
              ),
              
              // Category filter chips
              BlocListener<ProductListBloc, ProductListState>(
                listener: (context, state) {
                  if (state is ProductListLoaded && _categories != state.categories) {
                    setState(() {
                      _categories = state.categories;
                    });
                  }
                },
                child: _categories.isNotEmpty
                    ? Column(
                        children: [
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: const Text('All'),
                                    selected: _selectedCategory == null,
                                    onSelected: (_) {
                                      print('🏷️ "All" category selected');
                                      _filterByCategory(null);
                                    },
                                  ),
                                ),
                                ..._categories.map((category) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(category),
                                    selected: _selectedCategory == category,
                                    onSelected: (_) {
                                      print('🏷️ Category "$category" selected');
                                      _filterByCategory(category);
                                    },
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        
        // Products grid
        Expanded(
          child: BlocConsumer<ProductListBloc, ProductListState>(
            listener: (context, state) {
              if (state is ProductListError) {
                print('❌ ProductListBloc Error: ${state.message}');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is ProductListLoading && state.oldProducts == null) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state is ProductListLoaded || 
                  state is ProductListLoadingMore ||
                  (state is ProductListLoading && state.oldProducts != null)) {
                
                List<Product> products = [];
                bool hasMore = false;

                if (state is ProductListLoaded) {
                  products = state.products;
                  hasMore = state.hasMore;
                  print('✅ Displaying ${products.length} products');
                } else if (state is ProductListLoadingMore) {
                  products = state.products;
                  hasMore = true;
                } else if (state is ProductListLoading && state.oldProducts != null) {
                  products = state.oldProducts!;
                }

                if (products.isEmpty) {
                  return _buildEmptyProductsState(context);
                }

                return _buildProductsGrid(context, products, hasMore, shop);
              }

              if (state is ProductListError) {
                return _buildProductsErrorState(context, state.message);
              }

              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductsGrid(BuildContext context, List<Product> products, bool hasMore, Shop shop) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ProductListBloc>().add(ProductListRefreshEvent(
          shopId: widget.shopId,
          category: _selectedCategory,
        ));
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: products.length + (hasMore ? 2 : 0), // Add 2 loading placeholders
        itemBuilder: (context, index) {
          if (index >= products.length) {
            // Loading placeholder for pagination
            return const Card(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final product = products[index];
          return ProductGridItem(
            product: product,
            onTap: () {
              context.push('/shops/${widget.shopId}/products/${product.id}');
            },
            onAddToCart: () => _addToCart(product),
          );
        },
      ),
    );
  }

  Widget _buildInfoTab(BuildContext context, Shop shop) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (shop.description.isNotEmpty) ...[
            Text(
              'About',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              shop.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
          ],
          
          // Contact Information
          Text(
            'Contact Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          AppCard(
            child: Column(
              children: [
                _buildInfoRow(
                  context,
                  Icons.location_on_outlined,
                  'Address',
                  shop.address,
                  onTap: () => _openMaps(shop.latitude, shop.longitude),
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  context,
                  Icons.phone_outlined,
                  'Phone',
                  shop.phone,
                  onTap: () => _makePhoneCall(shop.phone),
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  context,
                  Icons.email_outlined,
                  'Email',
                  shop.email,
                  onTap: () => _sendEmail(shop.email),
                ),
                if (shop.website != null) ...[
                  const Divider(height: 24),
                  _buildInfoRow(
                    context,
                    Icons.language_outlined,
                    'Website',
                    shop.website!,
                    onTap: () => _openWebsite(shop.website!),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Delivery Information
          Text(
            'Delivery Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          AppCard(
            child: Column(
              children: [
                _buildInfoRow(
                  context,
                  Icons.access_time,
                  'Delivery Time',
                  '${shop.estimatedDeliveryTime} minutes',
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  context,
                  Icons.delivery_dining,
                  'Delivery Fee',
                  '\$${shop.deliveryFee.toStringAsFixed(2)}',
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  context,
                  Icons.attach_money,
                  'Minimum Order',
                  '\$${shop.minimumOrderAmount.toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Operating Hours
          Text(
            'Operating Hours',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Parse and display opening hours
                // This is a simplified version - you might want to parse the JSON properly
                Text(
                  'Monday - Friday: 9:00 AM - 10:00 PM',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Saturday - Sunday: 10:00 AM - 11:00 PM',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: shop.isOpen ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    shop.isOpen ? 'Currently Open' : 'Currently Closed',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: shop.isOpen ? Colors.green.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      child: Row(
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
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onTap != null ? theme.colorScheme.primary : null,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyProductsState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 80,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
              const SizedBox(height: 24),
              Text(
                _isSearching ? 'No products found' : 'No products available',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _isSearching 
                    ? 'Try adjusting your search terms or browse different categories.'
                    : 'This shop doesn\'t have any products available at the moment.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              if (_isSearching) ...[
                const SizedBox(height: 32),
                AppButton(
                  text: 'Clear Search',
                  onPressed: _clearSearch,
                  variant: AppButtonVariant.outline,
                  icon: Icons.clear,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsErrorState(BuildContext context, String message) {
    final theme = Theme.of(context);
    
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Failed to load products',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Try Again',
                onPressed: () {
                  context.read<ProductListBloc>().add(ProductListLoadEvent(
                    shopId: widget.shopId,
                    category: _selectedCategory,
                  ));
                },
                variant: AppButtonVariant.primary,
                icon: Icons.refresh,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Failed to load shop',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                AppButton(
                  text: 'Try Again',
                  onPressed: () {
                    context.read<ShopDetailsBloc>().add(ShopDetailsLoadEvent(widget.shopId));
                  },
                  variant: AppButtonVariant.primary,
                  icon: Icons.refresh,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods for actions
  void _openMaps(double latitude, double longitude) async {
    try {
      final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      print('🗺️ Attempting to open maps: $url');
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        print('✅ Maps opened successfully');
      } else {
        print('❌ Cannot launch maps URL: $url');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot open maps')),
          );
        }
      }
    } catch (e) {
      print('❌ Error opening maps: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening maps: $e')),
        );
      }
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    try {
      final url = 'tel:$phoneNumber';
      print('📞 Attempting to make phone call: $url');
      
      // First try to launch the phone app
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        print('✅ Phone call initiated successfully');
      } else {
        print('❌ Cannot launch phone URL: $url');
        // Show fallback dialog with phone number
        _showContactDialog(
          context,
          'Phone Number',
          phoneNumber,
          'The phone app is not available. You can manually dial this number:',
          Icons.phone,
        );
      }
    } catch (e) {
      print('❌ Error making phone call: $e');
      // Show fallback dialog with phone number
      _showContactDialog(
        context,
        'Phone Number',
        phoneNumber,
        'Unable to open phone app. You can manually dial this number:',
        Icons.phone,
      );
    }
  }

  void _sendEmail(String email) async {
    try {
      final url = 'mailto:$email';
      print('📧 Attempting to send email: $url');
      
      // First try to launch the email app
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        print('✅ Email app opened successfully');
      } else {
        print('❌ Cannot launch email URL: $url');
        // Show fallback dialog with email address
        _showContactDialog(
          context,
          'Email Address',
          email,
          'The email app is not available. You can manually copy this email address:',
          Icons.email,
        );
      }
    } catch (e) {
      print('❌ Error opening email: $e');
      // Show fallback dialog with email address
      _showContactDialog(
        context,
        'Email Address',
        email,
        'Unable to open email app. You can manually copy this email address:',
        Icons.email,
      );
    }
  }

  void _showContactDialog(
    BuildContext context,
    String title,
    String contact,
    String message,
    IconData icon,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(icon, size: 32),
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        contact,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () async {
                        // Copy to clipboard functionality
                        await Clipboard.setData(ClipboardData(text: contact));
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$title copied to clipboard')),
                        );
                      },
                      tooltip: 'Copy to clipboard',
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _openWebsite(String website) async {
    try {
      final url = website.startsWith('http') ? website : 'https://$website';
      print('🌐 Attempting to open website: $url');
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        print('✅ Website opened successfully');
      } else {
        print('❌ Cannot launch website URL: $url');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot open website')),
          );
        }
      }
    } catch (e) {
      print('❌ Error opening website: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening website: $e')),
        );
      }
    }
  }
} 