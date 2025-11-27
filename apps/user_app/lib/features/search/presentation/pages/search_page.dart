import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:domain/domain.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:user_app/features/shop/presentation/bloc/shop_list_bloc.dart';
import 'package:user_app/features/shop/presentation/widgets/shop_list_item.dart';

class SearchPage extends StatefulWidget {
  final String? initialQuery;

  const SearchPage({
    super.key,
    this.initialQuery,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _searchFocusNode = FocusNode();
    _currentQuery = widget.initialQuery ?? '';
    
    // Auto-focus the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
    
    // If there's an initial query, search immediately
    if (widget.initialQuery?.isNotEmpty == true) {
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _currentQuery = query.trim();
    });
    
    // Trigger search in ShopListBloc
    context.read<ShopListBloc>().add(ShopListSearchEvent(
      query: query.trim(),
    ));
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentQuery = '';
    });
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Column(
        children: [
          // Search input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search for shops, restaurants, products...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _currentQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha:0.3),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: _performSearch,
                    onChanged: (value) {
                      // Perform search as user types (with debouncing in real app)
                      if (value.trim().length >= 2) {
                        _performSearch(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                AppButton(
                  text: 'Search',
                  onPressed: () => _performSearch(_searchController.text),
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.small,
                ),
              ],
            ),
          ),
          
          // Search results
          Expanded(
            child: BlocBuilder<ShopListBloc, ShopListState>(
              builder: (context, state) {
                if (state is ShopListLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (state is ShopListLoaded && state.searchQuery != null) {
                  if (state.shops.isEmpty) {
                    return _buildEmptyResults();
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.shops.length,
                    itemBuilder: (context, index) {
                      final shop = state.shops[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ShopListItem(
                          shop: shop,
                          onTap: () {
                            context.go('/shops/${shop.id}');
                          },
                        ),
                      );
                    },
                  );
                }
                
                if (state is ShopListError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Search Error',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha:0.7),
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          text: 'Try Again',
                          onPressed: () => _performSearch(_currentQuery),
                          variant: AppButtonVariant.outline,
                        ),
                      ],
                    ),
                  );
                }
                
                // Default state - show search suggestions or recent searches
                return _buildSearchSuggestions();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha:0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Results Found',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'We couldn\'t find any shops or products matching "$_currentQuery"',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha:0.7),
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'Browse All Shops',
            onPressed: () {
              context.go('/shops');
            },
            variant: AppButtonVariant.outline,
            icon: Icons.store,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Searches',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestionChip('Pizza'),
              _buildSuggestionChip('Burger'),
              _buildSuggestionChip('Sushi'),
              _buildSuggestionChip('Coffee'),
              _buildSuggestionChip('Grocery'),
              _buildSuggestionChip('Pharmacy'),
              _buildSuggestionChip('Fast Food'),
              _buildSuggestionChip('Italian'),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Browse by Category',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildCategoryItem('Restaurants', Icons.restaurant, ShopCategory.restaurant),
          _buildCategoryItem('Grocery Stores', Icons.local_grocery_store, ShopCategory.grocery),
          _buildCategoryItem('Pharmacies', Icons.local_pharmacy, ShopCategory.pharmacy),
          _buildCategoryItem('Retail Shops', Icons.shopping_bag, ShopCategory.retail),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    return ActionChip(
      label: Text(suggestion),
      onPressed: () {
        _searchController.text = suggestion;
        _performSearch(suggestion);
      },
    );
  }

  Widget _buildCategoryItem(String title, IconData icon, ShopCategory category) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        context.go('/shops?category=${category.name}');
      },
    );
  }
} 