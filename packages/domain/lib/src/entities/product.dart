import 'package:equatable/equatable.dart';

/// Product entity representing a product in a shop
class Product extends Equatable {
  /// Unique identifier for the product
  final String id;
  
  /// Name of the product
  final String name;
  
  /// Description of the product
  final String description;
  
  /// Price of the product
  final double price;
  
  /// Discounted price (null if no discount)
  final double? discountedPrice;
  
  /// Image URL of the product
  final String? imageUrl;
  
  /// Category of the product
  final String category;
  
  /// Tags for the product (for searching/filtering)
  final List<String> tags;
  
  /// Nutritional information (for food items)
  final Map<String, dynamic>? nutritionalInfo;
  
  /// Whether the product is in stock
  final bool inStock;
  
  /// Stock quantity (null if unlimited)
  final int? stockQuantity;
  
  /// Shop ID that owns this product
  final String shopId;
  
  /// Whether the product is featured
  final bool isFeatured;
  
  /// Average rating of the product (1-5)
  final double rating;
  
  /// Number of ratings
  final int ratingCount;
  
  /// Date when the product was created
  final DateTime createdAt;
  
  /// Date when the product was last updated
  final DateTime updatedAt;

  /// Creates a product entity
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountedPrice,
    this.imageUrl,
    required this.category,
    this.tags = const [],
    this.nutritionalInfo,
    required this.inStock,
    this.stockQuantity,
    required this.shopId,
    this.isFeatured = false,
    this.rating = 0,
    this.ratingCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this product with the given fields replaced
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? Function()? discountedPrice,
    String? Function()? imageUrl,
    String? category,
    List<String>? tags,
    Map<String, dynamic>? Function()? nutritionalInfo,
    bool? inStock,
    int? Function()? stockQuantity,
    String? shopId,
    bool? isFeatured,
    double? rating,
    int? ratingCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discountedPrice: discountedPrice != null ? discountedPrice() : this.discountedPrice,
      imageUrl: imageUrl != null ? imageUrl() : this.imageUrl,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      nutritionalInfo: nutritionalInfo != null ? nutritionalInfo() : this.nutritionalInfo,
      inStock: inStock ?? this.inStock,
      stockQuantity: stockQuantity != null ? stockQuantity() : this.stockQuantity,
      shopId: shopId ?? this.shopId,
      isFeatured: isFeatured ?? this.isFeatured,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// Empty product instance
  factory Product.empty() {
    return Product(
      id: '',
      name: '',
      description: '',
      price: 0,
      category: '',
      inStock: false,
      shopId: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Get the current active price (discounted if available, otherwise regular)
  double get activePrice => discountedPrice ?? price;
  
  /// Check if the product has a discount
  bool get hasDiscount => discountedPrice != null && discountedPrice! < price;
  
  /// Calculate discount percentage
  double? get discountPercentage => hasDiscount 
      ? ((price - discountedPrice!) / price * 100).roundToDouble() 
      : null;
  
  /// Creates a product from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      discountedPrice: json['discountedPrice'] != null 
          ? (json['discountedPrice'] as num).toDouble() 
          : null,
      imageUrl: json['imageUrl'] as String?,
      category: json['categoryName'] as String,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      nutritionalInfo: json['nutritionalInfo'] as Map<String, dynamic>?,
      inStock: json['inStock'] as bool,
      stockQuantity: json['stockQuantity'] as int?,
      shopId: json['shopId'] as String,
      isFeatured: json['isFeatured'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Converts the product to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discounted_price': discountedPrice,
      'image_url': imageUrl,
      'category': category,
      'tags': tags,
      'nutritional_info': nutritionalInfo,
      'in_stock': inStock,
      'stock_quantity': stockQuantity,
      'shop_id': shopId,
      'is_featured': isFeatured,
      'rating': rating,
      'rating_count': ratingCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id, name, description, price, discountedPrice, imageUrl,
    category, tags, nutritionalInfo, inStock, stockQuantity,
    shopId, isFeatured, rating, ratingCount, createdAt, updatedAt,
  ];
}