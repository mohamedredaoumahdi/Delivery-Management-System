import 'package:dartz/dartz.dart' as dartz;

import '../entities/shop.dart';
import '../errors/failures.dart';
import '../repositories/user_repository.dart';

/// Use case for managing user favorites
class ManageFavoritesUseCase {
  final UserRepository _userRepository;

  ManageFavoritesUseCase(this._userRepository);

  /// Add shop to favorites
  Future<dartz.Either<Failure, void>> addToFavorites(String shopId) async {
    return await _userRepository.addToFavorites(shopId);
  }

  /// Remove shop from favorites
  Future<dartz.Either<Failure, void>> removeFromFavorites(String shopId) async {
    return await _userRepository.removeFromFavorites(shopId);
  }

  /// Get user's favorite shops
  Future<dartz.Either<Failure, List<Shop>>> getFavoriteShops() async {
    return await _userRepository.getFavoriteShops();
  }

  /// Check if shop is in favorites
  Future<dartz.Either<Failure, bool>> isShopFavorite(String shopId) async {
    return await _userRepository.isShopFavorite(shopId);
  }

  /// Toggle favorite status
  Future<dartz.Either<Failure, bool>> toggleFavorite(String shopId) async {
    final isAlreadyFavorite = await _userRepository.isShopFavorite(shopId);
    
    return await isAlreadyFavorite.fold(
      (failure) => dartz.Left(failure),
      (isFavorite) async {
        if (isFavorite) {
          final result = await _userRepository.removeFromFavorites(shopId);
          return result.fold(
            (failure) => dartz.Left(failure),
            (_) => dartz.Right(false), // Now not favorite
          );
        } else {
          final result = await _userRepository.addToFavorites(shopId);
          return result.fold(
            (failure) => dartz.Left(failure),
            (_) => dartz.Right(true), // Now favorite
          );
        }
      },
    );
  }
} 