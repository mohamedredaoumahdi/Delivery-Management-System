part of 'shop_list_bloc.dart';

abstract class ShopListState extends Equatable {
  const ShopListState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state
class ShopListInitial extends ShopListState {
  const ShopListInitial();
}

/// Loading state
class ShopListLoading extends ShopListState {
  final List<Shop>? oldShops;

  const ShopListLoading({this.oldShops});

  @override
  List<Object?> get props => [oldShops];
}

/// Loading more state (pagination)
class ShopListLoadingMore extends ShopListState {
  final List<Shop> shops;
  final int currentPage;
  final ShopCategory? category;
  final String? searchQuery;

  const ShopListLoadingMore({
    required this.shops,
    required this.currentPage,
    this.category,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [shops, currentPage, category, searchQuery];
}

/// Loaded state
class ShopListLoaded extends ShopListState {
  final List<Shop> shops;
  final bool hasMore;
  final int currentPage;
  final ShopCategory? category;
  final String? searchQuery;

  const ShopListLoaded({
    required this.shops,
    required this.hasMore,
    required this.currentPage,
    this.category,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [shops, hasMore, currentPage, category, searchQuery];
}

/// Error state
class ShopListError extends ShopListState {
  final String message;

  const ShopListError(this.message);

  @override
  List<Object> get props => [message];
}

// Featured shops states

/// Loading featured shops
class ShopListLoadingFeatured extends ShopListState {
  const ShopListLoadingFeatured();
}

/// Featured shops loaded
class ShopListFeaturedLoaded extends ShopListState {
  final List<Shop> shops;

  const ShopListFeaturedLoaded({required this.shops});

  @override
  List<Object> get props => [shops];
}

/// Error loading featured shops
class ShopListFeaturedError extends ShopListState {
  final String message;

  const ShopListFeaturedError(this.message);

  @override
  List<Object> get props => [message];
}

// Nearby shops states

/// Loading nearby shops
class ShopListLoadingNearby extends ShopListState {
  const ShopListLoadingNearby();
}

/// Nearby shops loaded
class ShopListNearbyLoaded extends ShopListState {
  final List<Shop> shops;

  const ShopListNearbyLoaded({required this.shops});

  @override
  List<Object> get props => [shops];
}

/// Error loading nearby shops
class ShopListNearbyError extends ShopListState {
  final String message;

  const ShopListNearbyError(this.message);

  @override
  List<Object> get props => [message];
}