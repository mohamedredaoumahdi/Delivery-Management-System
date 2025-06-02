import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:domain/domain.dart';

part 'favorites_event.dart';
part 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final ManageFavoritesUseCase _manageFavoritesUseCase;

  FavoritesBloc({
    required ManageFavoritesUseCase manageFavoritesUseCase,
  })  : _manageFavoritesUseCase = manageFavoritesUseCase,
        super(const FavoritesInitial()) {
    on<FavoritesLoadEvent>(_onFavoritesLoad);
    on<FavoritesToggleEvent>(_onFavoritesToggle);
    on<FavoritesCheckEvent>(_onFavoritesCheck);
    on<FavoritesRefreshEvent>(_onFavoritesRefresh);
  }

  Future<void> _onFavoritesLoad(
    FavoritesLoadEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(const FavoritesLoading());

    try {
      final result = await _manageFavoritesUseCase.getFavoriteShops();

      result.fold(
        (failure) => emit(FavoritesError(failure.message)),
        (shops) => emit(FavoritesLoaded(shops)),
      );
    } catch (e) {
      emit(FavoritesError('Failed to load favorites: $e'));
    }
  }

  Future<void> _onFavoritesToggle(
    FavoritesToggleEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    final currentState = state;
    
    // Show toggling state
    emit(FavoritesToggling(event.shopId));

    try {
      final result = await _manageFavoritesUseCase.toggleFavorite(event.shopId);

      result.fold(
        (failure) {
          // Restore previous state and show error
          if (currentState is FavoritesLoaded) {
            emit(currentState);
          }
          emit(FavoritesError(failure.message));
        },
        (isFavorite) {
          // Update the state
          if (currentState is FavoritesLoaded) {
            List<Shop> updatedShops;
            if (isFavorite) {
              // Shop was added to favorites, but we need the shop data
              // For now, just reload the favorites list
              add(const FavoritesLoadEvent());
              return;
            } else {
              // Shop was removed from favorites
              updatedShops = currentState.favoriteShops
                  .where((shop) => shop.id != event.shopId)
                  .toList();
              emit(FavoritesLoaded(updatedShops));
            }
          }
          
          emit(FavoritesToggled(event.shopId, isFavorite));
        },
      );
    } catch (e) {
      // Restore previous state and show error
      if (currentState is FavoritesLoaded) {
        emit(currentState);
      }
      emit(FavoritesError('Failed to toggle favorite: $e'));
    }
  }

  Future<void> _onFavoritesCheck(
    FavoritesCheckEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      final result = await _manageFavoritesUseCase.isShopFavorite(event.shopId);

      result.fold(
        (failure) => emit(FavoritesError(failure.message)),
        (isFavorite) => emit(FavoritesChecked(event.shopId, isFavorite)),
      );
    } catch (e) {
      emit(FavoritesError('Failed to check favorite status: $e'));
    }
  }

  Future<void> _onFavoritesRefresh(
    FavoritesRefreshEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    // Don't show loading state for refresh
    try {
      final result = await _manageFavoritesUseCase.getFavoriteShops();

      result.fold(
        (failure) => emit(FavoritesError(failure.message)),
        (shops) => emit(FavoritesLoaded(shops)),
      );
    } catch (e) {
      emit(FavoritesError('Failed to refresh favorites: $e'));
    }
  }
} 