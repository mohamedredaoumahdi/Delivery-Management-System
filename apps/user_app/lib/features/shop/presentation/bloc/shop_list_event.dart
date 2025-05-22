part of 'shop_list_bloc.dart';

abstract class ShopListEvent extends Equatable {
  const ShopListEvent();

  @override
  List<Object?> get props => [];
}

/// Load shops with optional category filter
class ShopListLoadEvent extends ShopListEvent {
  final ShopCategory? category;

  const ShopListLoadEvent({this.category});

  @override
  List<Object?> get props => [category];
}

/// Search shops with optional category filter
class ShopListSearchEvent extends ShopListEvent {
  final String query;
  final ShopCategory? category;

  const ShopListSearchEvent({
    required this.query,
    this.category,
  });

  @override
  List<Object?> get props => [query, category];
}

/// Filter shops by category
class ShopListFilterByCategoryEvent extends ShopListEvent {
  final ShopCategory? category;

  const ShopListFilterByCategoryEvent({this.category});

  @override
  List<Object?> get props => [category];
}

/// Load more shops (pagination)
class ShopListLoadMoreEvent extends ShopListEvent {
  const ShopListLoadMoreEvent();
}

/// Refresh shop list
class ShopListRefreshEvent extends ShopListEvent {
  const ShopListRefreshEvent();
}

/// Load featured shops
class ShopListLoadFeaturedEvent extends ShopListEvent {
  final int limit;

  const ShopListLoadFeaturedEvent({this.limit = 5});

  @override
  List<Object> get props => [limit];
}

/// Load nearby shops
class ShopListLoadNearbyEvent extends ShopListEvent {
  final double latitude;
  final double longitude;
  final double radius;
  final int limit;

  const ShopListLoadNearbyEvent({
    required this.latitude,
    required this.longitude,
    this.radius = 5.0,
    this.limit = 10,
  });

  @override
  List<Object> get props => [latitude, longitude, radius, limit];
}