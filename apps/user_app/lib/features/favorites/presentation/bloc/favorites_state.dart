part of 'favorites_bloc.dart';

abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class FavoritesInitial extends FavoritesState {
  const FavoritesInitial();
}

/// Loading favorites
class FavoritesLoading extends FavoritesState {
  const FavoritesLoading();
}

/// Favorites loaded successfully
class FavoritesLoaded extends FavoritesState {
  final List<Shop> favoriteShops;

  const FavoritesLoaded(this.favoriteShops);

  @override
  List<Object> get props => [favoriteShops];
}

/// Error loading favorites
class FavoritesError extends FavoritesState {
  final String message;

  const FavoritesError(this.message);

  @override
  List<Object> get props => [message];
}

/// Toggling favorite status
class FavoritesToggling extends FavoritesState {
  final String shopId;

  const FavoritesToggling(this.shopId);

  @override
  List<Object> get props => [shopId];
}

/// Favorite status toggled
class FavoritesToggled extends FavoritesState {
  final String shopId;
  final bool isFavorite;

  const FavoritesToggled(this.shopId, this.isFavorite);

  @override
  List<Object> get props => [shopId, isFavorite];
}

/// Checked if shop is favorite
class FavoritesChecked extends FavoritesState {
  final String shopId;
  final bool isFavorite;

  const FavoritesChecked(this.shopId, this.isFavorite);

  @override
  List<Object> get props => [shopId, isFavorite];
} 