part of 'favorites_bloc.dart';

abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

/// Load user's favorite shops
class FavoritesLoadEvent extends FavoritesEvent {
  const FavoritesLoadEvent();
}

/// Toggle favorite status of a shop
class FavoritesToggleEvent extends FavoritesEvent {
  final String shopId;

  const FavoritesToggleEvent(this.shopId);

  @override
  List<Object> get props => [shopId];
}

/// Check if a shop is in favorites
class FavoritesCheckEvent extends FavoritesEvent {
  final String shopId;

  const FavoritesCheckEvent(this.shopId);

  @override
  List<Object> get props => [shopId];
}

/// Refresh favorites list
class FavoritesRefreshEvent extends FavoritesEvent {
  const FavoritesRefreshEvent();
} 