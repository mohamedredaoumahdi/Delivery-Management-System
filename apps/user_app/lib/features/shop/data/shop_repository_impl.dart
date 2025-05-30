import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:domain/domain.dart';
import 'package:data/src/api/api_client.dart' as data_api;

class ShopRepositoryImpl implements ShopRepository {
  final data_api.ApiClient apiClient;
  final LoggerService logger;

  ShopRepositoryImpl({
    required this.apiClient,
    required this.logger,
  });

  @override
  Future<Either<Failure, List<Shop>>> getShops({
    String? query,
    ShopCategory? category,
    double? latitude,
    double? longitude,
    double? radius,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await apiClient.get('/shops', queryParameters: {
        if (query != null) 'q': query,
        if (category != null) 'category': _categoryToString(category),
        if (latitude != null) 'lat': latitude,
        if (longitude != null) 'lng': longitude,
        if (radius != null) 'radius': radius,
        'page': page,
        'limit': limit,
      });
      final shops = (response.data['data'] as List)
          .map((json) => Shop.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(shops);
    } catch (e) {
      logger.e('Error getting shops', e);
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Convert ShopCategory enum to backend string format
  String _categoryToString(ShopCategory category) {
    switch (category) {
      case ShopCategory.restaurant:
        return 'RESTAURANT';
      case ShopCategory.grocery:
        return 'GROCERY';
      case ShopCategory.pharmacy:
        return 'PHARMACY';
      case ShopCategory.retail:
        return 'RETAIL';
      case ShopCategory.other:
        return 'OTHER';
    }
  }

  @override
  Future<Either<Failure, Shop>> getShopById(String id) async {
    try {
      final response = await apiClient.get('/shops/$id');
      final shop = Shop.fromJson(response.data['data'] as Map<String, dynamic>);
      return Right(shop);
    } catch (e) {
      logger.e('Error getting shop by id', e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getShopProducts({
    required String shopId,
    String? query,
    String? category,
    bool? inStock,
    bool? featured,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await apiClient.get('/shops/$shopId/products', queryParameters: {
        if (query != null) 'q': query,
        if (category != null) 'category': category,
        if (inStock != null) 'in_stock': inStock,
        if (featured != null) 'featured': featured,
        'page': page,
        'limit': limit,
      });
      final products = (response.data['data'] as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(products);
    } catch (e) {
      logger.e('Error getting shop products', e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    try {
      final response = await apiClient.get('/products/$id');
      final product = Product.fromJson(response.data['data'] as Map<String, dynamic>);
      return Right(product);
    } catch (e) {
      logger.e('Error getting product by id', e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, (Product, Shop)>> getProductWithShop(String productId) async {
    try {
      final response = await apiClient.get('/products/$productId');
      final data = response.data['data'] as Map<String, dynamic>;
      
      // Parse product
      final product = Product.fromJson(data);
      
      // Parse shop from embedded data
      final shopData = data['shop'] as Map<String, dynamic>?;
      if (shopData == null) {
        // Fallback: load shop separately if not embedded
        final shopResult = await getShopById(product.shopId);
        return shopResult.fold(
          (failure) => Left(failure),
          (shop) => Right((product, shop)),
        );
      }
      
      final shop = Shop.fromJson(shopData);
      return Right((product, shop));
    } catch (e) {
      logger.e('Error getting product with shop', e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Shop>>> getFeaturedShops({int limit = 10}) async {
    try {
      final response = await apiClient.get('/shops/featured', queryParameters: {
        'limit': limit,
      });
      final shops = (response.data['data'] as List)
          .map((json) => Shop.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(shops);
    } catch (e) {
      logger.e('Error getting featured shops', e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Shop>>> getNearbyShops({
    required double latitude,
    required double longitude,
    double radius = 5.0,
    int limit = 20,
  }) async {
    try {
      final response = await apiClient.get('/shops/nearby', queryParameters: {
        'lat': latitude,
        'lng': longitude,
        'radius': radius,
        'limit': limit,
      });
      final shops = (response.data['data'] as List)
          .map((json) => Shop.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(shops);
    } catch (e) {
      logger.e('Error getting nearby shops', e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getProductCategories({required String shopId}) async {
    try {
      final response = await apiClient.get('/shops/$shopId/categories');
      final categories = (response.data['data'] as List)
          .map((category) => category['name'] as String)
          .toList();
      return Right(categories);
    } catch (e) {
      logger.e('Error getting product categories', e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Shop>> createShop(Shop shop) async {
    try {
      final response = await apiClient.post('/shops', data: shop.toJson());
      final createdShop = Shop.fromJson(response.data['data'] as Map<String, dynamic>);
      return Right(createdShop);
    } catch (e) {
      logger.e('Error creating shop', e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Shop>> updateShop(Shop shop) async {
    try {
      final response = await apiClient.put('/shops/${shop.id}', data: shop.toJson());
      final updatedShop = Shop.fromJson(response.data['data'] as Map<String, dynamic>);
      return Right(updatedShop);
    } catch (e) {
      logger.e('Error updating shop', e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteShop(String id) async {
    try {
      await apiClient.delete('/shops/$id');
      return const Right(null);
    } catch (e) {
      logger.e('Error deleting shop', e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> createProduct(Product product) async {
    try {
      final response = await apiClient.post('/products', data: product.toJson());
      final createdProduct = Product.fromJson(response.data['data'] as Map<String, dynamic>);
      return Right(createdProduct);
    } catch (e) {
      logger.e('Error creating product', e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> updateProduct(Product product) async {
    try {
      final response = await apiClient.put('/products/${product.id}', data: product.toJson());
      final updatedProduct = Product.fromJson(response.data['data'] as Map<String, dynamic>);
      return Right(updatedProduct);
    } catch (e) {
      logger.e('Error updating product', e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      await apiClient.delete('/products/$id');
      return const Right(null);
    } catch (e) {
      logger.e('Error deleting product', e);
      return Left(ServerFailure(e.toString()));
    }
  }
} 