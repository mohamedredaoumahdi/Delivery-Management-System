import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:user_app/features/shop/presentation/bloc/shop_list_bloc.dart';
import 'package:user_app/features/shop/presentation/widgets/shop_list_item.dart';

class HomeSearchBar extends StatefulWidget {
  const HomeSearchBar({super.key});

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isSearching = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _currentQuery = '';
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _currentQuery = query.trim();
      _isSearching = true;
    });

    // Trigger search in ShopListBloc
    context.read<ShopListBloc>().add(ShopListSearchEvent(
      query: query.trim(),
    ));
  }

  void _clearSearch() {
    _searchController.clear();
    _focusNode.unfocus();
    setState(() {
      _currentQuery = '';
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Search Input
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha:0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha:0.03),
              blurRadius: 8,
                offset: const Offset(0, 1),
                spreadRadius: 0,
            ),
          ],
          border: Border.all(
              color: _focusNode.hasFocus 
                ? theme.colorScheme.primary.withValues(alpha:0.3)
                : theme.colorScheme.outline.withValues(alpha:0.1),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha:0.15),
                      theme.colorScheme.primary.withValues(alpha:0.08),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.search,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search for shops and products',
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha:0.6),
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    fillColor: Colors.transparent,
                    filled: true,
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: theme.colorScheme.primary,
                  selectionControls: MaterialTextSelectionControls(),
                  textInputAction: TextInputAction.search,
                  onChanged: (value) {
                    setState(() {}); // Update UI to show/hide close icon
                    if (value.trim().length >= 2) {
                      _performSearch(value);
                    } else if (value.trim().isEmpty) {
                      _clearSearch();
                    }
                  },
                  onSubmitted: _performSearch,
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: _clearSearch,
                  child: Icon(
                    Icons.close,
                    color: theme.colorScheme.onSurface.withValues(alpha:0.4),
                    size: 20,
                  ),
                )
              else
                Icon(
                  Icons.tune,
                  color: theme.colorScheme.onSurface.withValues(alpha:0.4),
                  size: 20,
                ),
            ],
          ),
        ),
        
        // Search Results
        if (_isSearching && _currentQuery.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16),
            constraints: const BoxConstraints(maxHeight: 400),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha:0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BlocBuilder<ShopListBloc, ShopListState>(
                builder: (context, state) {
                  if (state is ShopListLoading) {
                    return Container(
                      height: 120,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    );
                  }

                  if (state is ShopListError) {
                    return Container(
                      height: 120,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Search failed',
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please try again',
                            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha:0.6),
            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is ShopListLoaded && state.searchQuery != null) {
                    if (state.shops.isEmpty) {
                      return Container(
                        height: 120,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              color: theme.colorScheme.onSurface.withValues(alpha:0.5),
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No results found',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
            Text(
                              'Try a different search term',
                              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha:0.6),
              ),
            ),
          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.shops.length > 5 ? 5 : state.shops.length, // Show max 5 results
                      itemBuilder: (context, index) {
                        final shop = state.shops[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ShopListItem(
                            shop: shop,
                            onTap: () {
                              _clearSearch();
                              context.push('/shops/${shop.id}');
                            },
                          ),
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
      ],
    );
  }
}