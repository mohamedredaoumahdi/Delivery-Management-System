import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:domain/domain.dart';
import 'package:ui_kit/ui_kit.dart';

import '../bloc/shop_list_bloc.dart';
import '../widgets/shop_list_item.dart';

class ShopListPage extends StatefulWidget {
  final ShopCategory? initialCategory;
  final String? initialQuery;
  final bool showNearby;

  const ShopListPage({
    super.key,
    this.initialCategory,
    this.initialQuery,
    this.showNearby = false,
  });

  @override
  State<ShopListPage> createState() => _ShopListPageState();
}

class _ShopListPageState extends State<ShopListPage> with TickerProviderStateMixin {
  late TextEditingController _searchController;
  late ScrollController _scrollController;
  late TabController _categoryTabController;
  
  ShopCategory? _selectedCategory;
  String? _currentSearchQuery;
  
  // Category tabs
  final List<ShopCategory?> _categories = [
    null, // All categories
    ShopCategory.restaurant,
    ShopCategory.grocery,
    ShopCategory.pharmacy,
    ShopCategory.retail,
    ShopCategory.other,
  ];

  @override
  void initState() {
    super.initState();
    
    _searchController = TextEditingController(text: widget.initialQuery);
    _scrollController = ScrollController();
    _categoryTabController = TabController(
      length: _categories.length,
      vsync: this,
    );
    
    _selectedCategory = widget.initialCategory;
    _currentSearchQuery = widget.initialQuery;
    
    // Set initial tab
    if (widget.initialCategory != null) {
      final index = _categories.indexOf(widget.initialCategory);
      if (index != -1) {
        _categoryTabController.index = index;
      }
    }
    
    // Load initial data
    if (widget.showNearby) {
      context.read<ShopListBloc>().add(const ShopListLoadNearbyEvent(
        latitude: 37.7749, // Default location - should be replaced with actual user location
        longitude: -122.4194,
        limit: 50,
      ));
    } else if (_currentSearchQuery?.isNotEmpty ?? false) {
      context.read<ShopListBloc>().add(ShopListSearchEvent(
        query: _currentSearchQuery!,
        category: _selectedCategory,
      ));
    } else {
      context.read<ShopListBloc>().add(ShopListLoadEvent(
        category: _selectedCategory,
      ));
    }
    
    // Listen for tab changes
    _categoryTabController.addListener(_onCategoryTabChanged);
    
    // Listen for scroll to handle pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _categoryTabController.dispose();
    super.dispose();
  }

  void _onCategoryTabChanged() {
    if (!_categoryTabController.indexIsChanging) {
      final newCategory = _categories[_categoryTabController.index];
      if (newCategory != _selectedCategory) {
        setState(() {
          _selectedCategory = newCategory;
        });
        _performSearch();
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when user is near the bottom
      final state = context.read<ShopListBloc>().state;
      if (state is ShopListLoaded && state.hasMore) {
        context.read<ShopListBloc>().add(const ShopListLoadMoreEvent());
      }
    }
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    
    if (query.isNotEmpty) {
      _currentSearchQuery = query;
      context.read<ShopListBloc>().add(ShopListSearchEvent(
        query: query,
        category: _selectedCategory,
      ));
    } else {
      _currentSearchQuery = null;
      context.read<ShopListBloc>().add(ShopListLoadEvent(
        category: _selectedCategory,
      ));
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _currentSearchQuery = null;
    context.read<ShopListBloc>().add(ShopListLoadEvent(
      category: _selectedCategory,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.showNearby ? 'Nearby Shops' : 'All Shops'),
        elevation: 0,
        bottom: widget.showNearby 
            ? null 
            : TabBar(
                controller: _categoryTabController,
                isScrollable: true,
                tabs: [
                  const Tab(text: 'All'),
                  Tab(text: _getCategoryName(ShopCategory.restaurant)),
                  Tab(text: _getCategoryName(ShopCategory.grocery)),
                  Tab(text: _getCategoryName(ShopCategory.pharmacy)),
                  Tab(text: _getCategoryName(ShopCategory.retail)),
                  Tab(text: _getCategoryName(ShopCategory.other)),
                ],
                labelStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: theme.textTheme.titleSmall,
                indicatorWeight: 3,
              ),
      ),
      body: Column(
        children: [
          // Search bar
          if (!widget.showNearby)
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.surface,
              child: AppInputField(
                controller: _searchController,
                hintText: 'Search shops...',
                prefixIcon: Icons.search,
                suffixIcon: _searchController.text.isNotEmpty 
                    ? Icons.clear 
                    : null,
                onSuffixIconPressed: _searchController.text.isNotEmpty 
                    ? _clearSearch 
                    : null,
                onSubmitted: (_) => _performSearch(),
                onChanged: (value) {
                  // Debounce search
                  if (value.isEmpty) {
                    _clearSearch();
                  }
                },
              ),
            ),
          
          // Shop list
          Expanded(
            child: BlocConsumer<ShopListBloc, ShopListState>(
              listener: (context, state) {
                if (state is ShopListError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: theme.colorScheme.error,
                      action: SnackBarAction(
                        label: 'Retry',
                        textColor: Colors.white,
                        onPressed: () {
                          if (widget.showNearby) {
                            context.read<ShopListBloc>().add(
                              const ShopListLoadNearbyEvent(
                                latitude: 37.7749,
                                longitude: -122.4194,
                                limit: 50,
                              ),
                            );
                          } else {
                            _performSearch();
                          }
                        },
                      ),
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ShopListLoading && state.oldShops == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is ShopListNearbyLoaded) {
                  return _buildShopList(context, state.shops, hasMore: false);
                }

                if (state is ShopListLoaded || 
                    state is ShopListLoadingMore ||
                    (state is ShopListLoading && state.oldShops != null)) {
                  
                  List<Shop> shops = [];
                  bool hasMore = false;
                  bool isLoadingMore = false;

                  if (state is ShopListLoaded) {
                    shops = state.shops;
                    hasMore = state.hasMore;
                  } else if (state is ShopListLoadingMore) {
                    shops = state.shops;
                    hasMore = true;
                    isLoadingMore = true;
                  } else if (state is ShopListLoading && state.oldShops != null) {
                    shops = state.oldShops!;
                  }

                  if (shops.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return _buildShopList(
                    context, 
                    shops, 
                    hasMore: hasMore,
                    isLoadingMore: isLoadingMore,
                  );
                }

                if (state is ShopListError) {
                  return _buildErrorState(context, state.message);
                }

                // Default loading state
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopList(
    BuildContext context, 
    List<Shop> shops, {
    required bool hasMore,
    bool isLoadingMore = false,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        if (widget.showNearby) {
          context.read<ShopListBloc>().add(const ShopListLoadNearbyEvent(
            latitude: 37.7749,
            longitude: -122.4194,
            limit: 50,
          ));
        } else {
          context.read<ShopListBloc>().add(const ShopListRefreshEvent());
        }
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: shops.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= shops.length) {
            // Loading indicator for pagination
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final shop = shops[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShopListItem(
              shop: shop,
              onTap: () {
                context.push('/shops/${shop.id}');
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.showNearby ? Icons.location_off : Icons.search_off,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              widget.showNearby 
                  ? 'No nearby shops found'
                  : _currentSearchQuery != null
                      ? 'No shops found'
                      : 'No shops available',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              widget.showNearby 
                  ? 'Try expanding your search radius or check back later.'
                  : _currentSearchQuery != null
                      ? 'Try adjusting your search terms or browse different categories.'
                      : 'New shops will appear here when they become available.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            if (_currentSearchQuery != null)
              AppButton(
                text: 'Clear Search',
                onPressed: _clearSearch,
                variant: AppButtonVariant.outline,
                icon: Icons.clear,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final theme = Theme.of(context);
    
    return Center(
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
              'Failed to load shops',
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
                if (widget.showNearby) {
                  context.read<ShopListBloc>().add(const ShopListLoadNearbyEvent(
                    latitude: 37.7749,
                    longitude: -122.4194,
                    limit: 50,
                  ));
                } else {
                  _performSearch();
                }
              },
              variant: AppButtonVariant.primary,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(ShopCategory category) {
    switch (category) {
      case ShopCategory.restaurant:
        return 'Restaurants';
      case ShopCategory.grocery:
        return 'Grocery';
      case ShopCategory.pharmacy:
        return 'Pharmacy';
      case ShopCategory.retail:
        return 'Retail';
      case ShopCategory.other:
        return 'Other';
    }
  }
}