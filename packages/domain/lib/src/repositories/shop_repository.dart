import 'package:dartz/dartz.dart';

import '../entities/shop.dart';
import '../entities/product.dart';
import '../errors/failures.dart';

/// Repository for shop operations
abstract class ShopRepository {
  /// Get a list of shops
  /// [query] is an optional search query
  /// [category] is an optional category filter
  /// [page] is the page number (starting from 1)
  /// [limit] is the number of items per page
  Future<Either<Failure, List<Shop>>> getShops({
    String? query,
    ShopCategory? category,
    double? latitude,
    double? longitude,
    double? radius,
    int page = 1,
    int limit = 20,
  });
  
  /// Get a shop by ID
  Future<Either<Failure, Shop>> getShopById(String id);
  
  /// Get a list of products for a shop
  /// [query] is an optional search query
  /// [category] is an optional category filter
  /// [page] is the page number (starting from 1)
  /// [limit] is the number of items per page
  Future<Either<Failure, List<Product>>> getShopProducts({
    required String shopId,
    String? query,
    String? category,
    bool? inStock,
    bool? featured,
    int page = 1,
    int limit = 20,
  });
  
  /// Get a product by ID
  Future<Either<Failure, Product>> getProductById(String id);
  
  /// Get a product by ID with shop data
  /// Returns a tuple containing the product and its associated shop
  Future<Either<Failure, (Product, Shop)>> getProductWithShop(String productId);
  
  /// Get featured shops
  Future<Either<Failure, List<Shop>>> getFeaturedShops({
    int limit = 10,
  });
  
  /// Get nearby shops
  Future<Either<Failure, List<Shop>>> getNearbyShops({
    required double latitude,
    required double longitude,
    double radius = 5.0, // in kilometers
    int limit = 20,
  });
  
  /// Get shop categories
  Future<Either<Failure, List<String>>> getProductCategories({
    required String shopId,
  });
  
  /// For Vendor: Create a shop
  Future<Either<Failure, Shop>> createShop(Shop shop);
  
  /// For Vendor: Update a shop
  Future<Either<Failure, Shop>> updateShop(Shop shop);
  
  /// For Vendor: Delete a shop
  Future<Either<Failure, void>> deleteShop(String id);
  
  /// For Vendor: Create a product
  Future<Either<Failure, Product>> createProduct(Product product);
  
  /// For Vendor: Update a product
  Future<Either<Failure, Product>> updateProduct(Product product);
  
  /// For Vendor: Delete a product
  Future<Either<Failure, void>> deleteProduct(String id);
}