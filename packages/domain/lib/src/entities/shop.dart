import 'package:equatable/equatable.dart';

/// Shop category types
enum ShopCategory {
  /// Restaurant or food establishment
  restaurant,
  
  /// Grocery store
  grocery,
  
  /// Pharmacy
  pharmacy,
  
  /// Retail store
  retail,
  
  /// Other type of shop
  other,
}

/// Shop entity representing a vendor/shop in the system
class Shop extends Equatable {
  /// Unique identifier for the shop
  final String id;
  
  /// Name of the shop
  final String name;
  
  /// Description of the shop
  final String description;
  
  /// Category of the shop
  final ShopCategory category;
  
  /// Logo URL of the shop
  final String? logoUrl;
  
  /// Cover image URL of the shop
  final String? coverImageUrl;
  
  /// Address of the shop
  final String address;
  
  /// Latitude of the shop location
  final double latitude;
  
  /// Longitude of the shop location
  final double longitude;
  
  /// Phone number of the shop
  final String phone;
  
  /// Email of the shop
  final String email;
  
  /// Website of the shop (optional)
  final String? website;
  
  /// Opening hours in JSON format (can be parsed by client)
  final String openingHours;
  
  /// Average rating of the shop (1-5)
  final double rating;
  
  /// Number of ratings
  final int ratingCount;
  
  /// Whether the shop is currently open
  final bool isOpen;
  
  /// Whether the shop offers delivery
  final bool hasDelivery;
  
  /// Whether the shop offers pickup
  final bool hasPickup;
  
  /// Minimum order amount for delivery
  final double minimumOrderAmount;
  
  /// Delivery fee
  final double deliveryFee;
  
  /// Estimated delivery time in minutes
  final int estimatedDeliveryTime;
  
  /// Owner/Vendor user ID
  final String ownerId;
  
  /// Date when the shop was created
  final DateTime createdAt;
  
  /// Date when the shop was last updated
  final DateTime updatedAt;

  /// Creates a shop entity
  const Shop({
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
    required this.openingHours,
    required this.rating,
    required this.ratingCount,
    required this.isOpen,
    required this.hasDelivery,
    required this.hasPickup,
    required this.minimumOrderAmount,
    required this.deliveryFee,
    required this.estimatedDeliveryTime,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this shop with the given fields replaced
  Shop copyWith({
    String? id,
    String? name,
    String? description,
    ShopCategory? category,
    String? Function()? logoUrl,
    String? Function()? coverImageUrl,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    String? email,
    String? Function()? website,
    String? openingHours,
    double? rating,
    int? ratingCount,
    bool? isOpen,
    bool? hasDelivery,
    bool? hasPickup,
    double? minimumOrderAmount,
    double? deliveryFee,
    int? estimatedDeliveryTime,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      logoUrl: logoUrl != null ? logoUrl() : this.logoUrl,
      coverImageUrl: coverImageUrl != null ? coverImageUrl() : this.coverImageUrl,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website != null ? website() : this.website,
      openingHours: openingHours ?? this.openingHours,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      isOpen: isOpen ?? this.isOpen,
      hasDelivery: hasDelivery ?? this.hasDelivery,
      hasPickup: hasPickup ?? this.hasPickup,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// Empty shop instance
  factory Shop.empty() {
    return Shop(
      id: '',
      name: '',
      description: '',
      category: ShopCategory.other,
      address: '',
      latitude: 0,
      longitude: 0,
      phone: '',
      email: '',
      openingHours: '{}',
      rating: 0,
      ratingCount: 0,
      isOpen: false,
      hasDelivery: false,
      hasPickup: false,
      minimumOrderAmount: 0,
      deliveryFee: 0,
      estimatedDeliveryTime: 0,
      ownerId: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Creates a shop from JSON
  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: _parseShopCategory(json['category'] as String),
      logoUrl: json['logoUrl'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phone: json['phone'] as String,
      email: json['email'] as String,
      website: json['website'] as String?,
      openingHours: json['openingHours'] as String,
      rating: (json['rating'] as num).toDouble(),
      ratingCount: json['ratingCount'] as int,
      isOpen: json['isOpen'] as bool,
      hasDelivery: json['hasDelivery'] as bool,
      hasPickup: json['hasPickup'] as bool,
      minimumOrderAmount: (json['minimumOrderAmount'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      estimatedDeliveryTime: json['estimatedDeliveryTime'] as int,
      ownerId: json['ownerId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Parse shop category from string
  static ShopCategory _parseShopCategory(String categoryString) {
    switch (categoryString.toUpperCase()) {
      case 'RESTAURANT':
        return ShopCategory.restaurant;
      case 'GROCERY':
        return ShopCategory.grocery;
      case 'PHARMACY':
        return ShopCategory.pharmacy;
      case 'RETAIL':
        return ShopCategory.retail;
      default:
        return ShopCategory.other;
    }
  }

  /// Converts the shop to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.toString().split('.').last,
      'logo_url': logoUrl,
      'cover_image_url': coverImageUrl,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'website': website,
      'opening_hours': openingHours,
      'rating': rating,
      'rating_count': ratingCount,
      'is_open': isOpen,
      'has_delivery': hasDelivery,
      'has_pickup': hasPickup,
      'minimum_order_amount': minimumOrderAmount,
      'delivery_fee': deliveryFee,
      'estimated_delivery_time': estimatedDeliveryTime,
      'owner_id': ownerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  @override
  List<Object?> get props => [
    id, name, description, category, logoUrl, coverImageUrl,
    address, latitude, longitude, phone, email, website,
    openingHours, rating, ratingCount, isOpen, hasDelivery,
    hasPickup, minimumOrderAmount, deliveryFee, estimatedDeliveryTime,
    ownerId, createdAt, updatedAt,
  ];
}