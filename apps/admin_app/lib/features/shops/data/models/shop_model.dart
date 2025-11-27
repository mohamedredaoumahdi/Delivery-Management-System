class ShopModel {
  final String id;
  final String name;
  final String description;
  final String category; // RESTAURANT, GROCERY, PHARMACY, RETAIL, OTHER
  final String? logoUrl;
  final String? coverImageUrl;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final String email;
  final String? website;
  final double rating;
  final int ratingCount;
  final bool isOpen;
  final bool hasDelivery;
  final bool hasPickup;
  final double minimumOrderAmount;
  final double deliveryFee;
  final int? estimatedDeliveryTime;
  final bool isActive;
  final bool isFeatured;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShopModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.logoUrl,
    this.coverImageUrl,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.email,
    this.website,
    required this.rating,
    required this.ratingCount,
    required this.isOpen,
    required this.hasDelivery,
    required this.hasPickup,
    required this.minimumOrderAmount,
    required this.deliveryFee,
    this.estimatedDeliveryTime,
    required this.isActive,
    required this.isFeatured,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      logoUrl: json['logoUrl'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phone: json['phone'] as String,
      email: json['email'] as String,
      website: json['website'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      isOpen: json['isOpen'] as bool? ?? true,
      hasDelivery: json['hasDelivery'] as bool? ?? true,
      hasPickup: json['hasPickup'] as bool? ?? true,
      minimumOrderAmount: (json['minimumOrderAmount'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      estimatedDeliveryTime: json['estimatedDeliveryTime'] as int?,
      isActive: json['isActive'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      ownerId: json['ownerId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  String get categoryDisplayName {
    switch (category) {
      case 'RESTAURANT':
        return 'Restaurant';
      case 'GROCERY':
        return 'Grocery';
      case 'PHARMACY':
        return 'Pharmacy';
      case 'RETAIL':
        return 'Retail';
      case 'OTHER':
        return 'Other';
      default:
        return category;
    }
  }
}

