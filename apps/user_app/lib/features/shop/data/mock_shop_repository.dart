import 'package:dartz/dartz.dart';
import 'package:domain/domain.dart';

class MockShopRepository implements ShopRepository {
  final List<Shop> _mockShops = [
    Shop(
      id: 'shop1',
      name: 'Mock Pizza Place',
      description: 'Best pizza in town!',
      category: ShopCategory.restaurant,
      logoUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
      coverImageUrl: null,
      address: '123 Main St',
      latitude: 37.7749,
      longitude: -122.4194,
      phone: '555-1234',
      email: 'pizza@mock.com',
      website: null,
      openingHours: '10:00 - 22:00',
      rating: 4.7,
      ratingCount: 120,
      isOpen: true,
      hasDelivery: true,
      hasPickup: true,
      minimumOrderAmount: 10.0,
      deliveryFee: 2.0,
      estimatedDeliveryTime: 30,
      ownerId: 'owner1',
      createdAt: DateTime.now().subtract(const Duration(days: 100)),
      updatedAt: DateTime.now(),
    ),
    Shop(
      id: 'shop2',
      name: 'Mock Coffee Shop',
      description: 'Fresh coffee and pastries.',
      category: ShopCategory.restaurant,
      logoUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
      coverImageUrl: null,
      address: '456 Market St',
      latitude: 37.7750,
      longitude: -122.4183,
      phone: '555-5678',
      email: 'coffee@mock.com',
      website: null,
      openingHours: '07:00 - 19:00',
      rating: 4.5,
      ratingCount: 80,
      isOpen: true,
      hasDelivery: false,
      hasPickup: true,
      minimumOrderAmount: 5.0,
      deliveryFee: 0.0,
      estimatedDeliveryTime: 10,
      ownerId: 'owner2',
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
      updatedAt: DateTime.now(),
    ),
  ];

  final Map<String, List<Product>> _mockProducts = {
    'shop1': [
      Product(
        id: 'prod1',
        shopId: 'shop1',
        name: 'Margherita Pizza',
        description: 'Classic pizza with tomato, mozzarella, and basil.',
        price: 12.99,
        imageUrl: 'https://images.unsplash.com/photo-1542281286-9e0a16bb7366',
        category: 'Pizza',
        inStock: true,
        isFeatured: true,
        rating: 4.8,
        ratingCount: 50,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'prod2',
        shopId: 'shop1',
        name: 'Pepperoni Pizza',
        description: 'Spicy pepperoni with mozzarella and tomato sauce.',
        price: 14.99,
        imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591',
        category: 'Pizza',
        inStock: true,
        isFeatured: false,
        rating: 4.6,
        ratingCount: 30,
        createdAt: DateTime.now().subtract(const Duration(days: 80)),
        updatedAt: DateTime.now(),
      ),
    ],
    'shop2': [
      Product(
        id: 'prod3',
        shopId: 'shop2',
        name: 'Cappuccino',
        description: 'Espresso with steamed milk and foam.',
        price: 3.99,
        imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
        category: 'Coffee',
        inStock: true,
        isFeatured: true,
        rating: 4.9,
        ratingCount: 70,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'prod4',
        shopId: 'shop2',
        name: 'Blueberry Muffin',
        description: 'Freshly baked muffin with blueberries.',
        price: 2.49,
        imageUrl: 'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0',
        category: 'Pastry',
        inStock: true,
        isFeatured: false,
        rating: 4.3,
        ratingCount: 20,
        createdAt: DateTime.now().subtract(const Duration(days: 50)),
        updatedAt: DateTime.now(),
      ),
    ],
  };

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
    await Future.delayed(const Duration(milliseconds: 200));
    var shops = _mockShops;
    if (category != null) {
      shops = shops.where((s) => s.category == category).toList();
    }
    if (query != null && query.isNotEmpty) {
      shops = shops.where((s) => s.name.toLowerCase().contains(query.toLowerCase())).toList();
    }
    return Right(shops);
  }

  @override
  Future<Either<Failure, Shop>> getShopById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final shop = _mockShops.firstWhere((s) => s.id == id, orElse: () => throw Exception('Shop not found'));
    return Right(shop);
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
    await Future.delayed(const Duration(milliseconds: 100));
    var products = _mockProducts[shopId] ?? [];
    if (category != null) {
      products = products.where((p) => p.category == category).toList();
    }
    if (query != null && query.isNotEmpty) {
      products = products.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList();
    }
    if (inStock != null) {
      products = products.where((p) => p.inStock == inStock).toList();
    }
    if (featured != null) {
      products = products.where((p) => p.isFeatured == featured).toList();
    }
    return Right(products);
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final product = _mockProducts.values.expand((list) => list).firstWhere((p) => p.id == id, orElse: () => throw Exception('Product not found'));
    return Right(product);
  }

  @override
  Future<Either<Failure, List<Shop>>> getFeaturedShops({int limit = 10}) async {
    // Return only shops with a rating above 4.4
    final featured = _mockShops.where((shop) => shop.rating > 4.4).take(limit).toList();
    return Right(featured);
  }

  @override
  Future<Either<Failure, List<Shop>>> getNearbyShops({
    required double latitude,
    required double longitude,
    double radius = 5.0,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // For mock, just return all shops
    return Right(_mockShops.take(limit).toList());
  }

  @override
  Future<Either<Failure, List<String>>> getProductCategories({required String shopId}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final products = _mockProducts[shopId] ?? [];
    final categories = products.map((p) => p.category).toSet().toList();
    return Right(categories);
  }

  // The following methods are not implemented for mock
  @override
  Future<Either<Failure, Shop>> createShop(Shop shop) async => throw UnimplementedError();
  @override
  Future<Either<Failure, Shop>> updateShop(Shop shop) async => throw UnimplementedError();
  @override
  Future<Either<Failure, void>> deleteShop(String id) async => throw UnimplementedError();
  @override
  Future<Either<Failure, Product>> createProduct(Product product) async => throw UnimplementedError();
  @override
  Future<Either<Failure, Product>> updateProduct(Product product) async => throw UnimplementedError();
  @override
  Future<Either<Failure, void>> deleteProduct(String id) async => throw UnimplementedError();
} 