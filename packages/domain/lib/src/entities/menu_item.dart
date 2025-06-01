import 'package:equatable/equatable.dart';

/// Menu item availability status
enum MenuItemStatus {
  /// Item is available for ordering
  available,
  
  /// Item is temporarily out of stock
  outOfStock,
  
  /// Item is hidden from customers
  hidden,
  
  /// Item is discontinued
  discontinued,
}

/// Menu item entity for vendor menu management
/// This is the vendor-side representation for managing menu items
class MenuItem extends Equatable {
  /// Unique identifier for the menu item
  final String id;
  
  /// Name of the menu item
  final String name;
  
  /// Description of the menu item
  final String description;
  
  /// Price of the menu item
  final double price;
  
  /// Category this item belongs to
  final String category;
  
  /// Subcategory for more specific grouping
  final String? subcategory;
  
  /// Current availability status
  final MenuItemStatus status;
  
  /// Whether this item is available for ordering
  final bool isAvailable;
  
  /// List of image URLs for this item
  final List<String> images;
  
  /// Main image URL (first in images list or featured image)
  final String? mainImageUrl;
  
  /// Preparation time in minutes
  final int preparationTime;
  
  /// Calories per serving (optional)
  final int? calories;
  
  /// List of allergens
  final List<String> allergens;
  
  /// List of dietary tags (vegetarian, vegan, gluten-free, etc.)
  final List<String> dietaryTags;
  
  /// List of available customizations/variations
  final List<MenuItemVariation> variations;
  
  /// List of available add-ons
  final List<MenuItemAddOn> addOns;
  
  /// Whether this item can be customized
  final bool isCustomizable;
  
  /// Vendor/Shop ID this menu item belongs to
  final String vendorId;
  
  /// Sort order for display
  final int sortOrder;
  
  /// Whether this item is featured/recommended
  final bool isFeatured;
  
  /// Discount percentage if any
  final double? discountPercentage;
  
  /// Discounted price if discount is applied
  final double? discountedPrice;
  
  /// Date when the item was created
  final DateTime createdAt;
  
  /// Date when the item was last updated
  final DateTime updatedAt;

  /// Creates a menu item entity
  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.subcategory,
    required this.status,
    required this.isAvailable,
    required this.images,
    this.mainImageUrl,
    required this.preparationTime,
    this.calories,
    required this.allergens,
    required this.dietaryTags,
    required this.variations,
    required this.addOns,
    required this.isCustomizable,
    required this.vendorId,
    required this.sortOrder,
    required this.isFeatured,
    this.discountPercentage,
    this.discountedPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this menu item with the given fields replaced
  MenuItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? Function()? subcategory,
    MenuItemStatus? status,
    bool? isAvailable,
    List<String>? images,
    String? Function()? mainImageUrl,
    int? preparationTime,
    int? Function()? calories,
    List<String>? allergens,
    List<String>? dietaryTags,
    List<MenuItemVariation>? variations,
    List<MenuItemAddOn>? addOns,
    bool? isCustomizable,
    String? vendorId,
    int? sortOrder,
    bool? isFeatured,
    double? Function()? discountPercentage,
    double? Function()? discountedPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      subcategory: subcategory != null ? subcategory() : this.subcategory,
      status: status ?? this.status,
      isAvailable: isAvailable ?? this.isAvailable,
      images: images ?? this.images,
      mainImageUrl: mainImageUrl != null ? mainImageUrl() : this.mainImageUrl,
      preparationTime: preparationTime ?? this.preparationTime,
      calories: calories != null ? calories() : this.calories,
      allergens: allergens ?? this.allergens,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      variations: variations ?? this.variations,
      addOns: addOns ?? this.addOns,
      isCustomizable: isCustomizable ?? this.isCustomizable,
      vendorId: vendorId ?? this.vendorId,
      sortOrder: sortOrder ?? this.sortOrder,
      isFeatured: isFeatured ?? this.isFeatured,
      discountPercentage: discountPercentage != null ? discountPercentage() : this.discountPercentage,
      discountedPrice: discountedPrice != null ? discountedPrice() : this.discountedPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// Empty menu item instance
  factory MenuItem.empty() {
    return MenuItem(
      id: '',
      name: '',
      description: '',
      price: 0,
      category: '',
      status: MenuItemStatus.available,
      isAvailable: true,
      images: [],
      preparationTime: 0,
      allergens: [],
      dietaryTags: [],
      variations: [],
      addOns: [],
      isCustomizable: false,
      vendorId: '',
      sortOrder: 0,
      isFeatured: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Creates a menu item from JSON
  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      status: _parseMenuItemStatus(json['status'] as String),
      isAvailable: json['isAvailable'] as bool,
      images: List<String>.from(json['images'] as List),
      mainImageUrl: json['mainImageUrl'] as String?,
      preparationTime: json['preparationTime'] as int,
      calories: json['calories'] as int?,
      allergens: List<String>.from(json['allergens'] as List),
      dietaryTags: List<String>.from(json['dietaryTags'] as List),
      variations: (json['variations'] as List)
          .map((e) => MenuItemVariation.fromJson(e))
          .toList(),
      addOns: (json['addOns'] as List)
          .map((e) => MenuItemAddOn.fromJson(e))
          .toList(),
      isCustomizable: json['isCustomizable'] as bool,
      vendorId: json['vendorId'] as String,
      sortOrder: json['sortOrder'] as int,
      isFeatured: json['isFeatured'] as bool,
      discountPercentage: json['discountPercentage'] != null 
          ? (json['discountPercentage'] as num).toDouble()
          : null,
      discountedPrice: json['discountedPrice'] != null 
          ? (json['discountedPrice'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Parse menu item status from string
  static MenuItemStatus _parseMenuItemStatus(String statusString) {
    switch (statusString.toUpperCase()) {
      case 'AVAILABLE':
        return MenuItemStatus.available;
      case 'OUT_OF_STOCK':
        return MenuItemStatus.outOfStock;
      case 'HIDDEN':
        return MenuItemStatus.hidden;
      case 'DISCONTINUED':
        return MenuItemStatus.discontinued;
      default:
        return MenuItemStatus.available;
    }
  }

  /// Converts the menu item to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'subcategory': subcategory,
      'status': status.toString().split('.').last,
      'isAvailable': isAvailable,
      'images': images,
      'mainImageUrl': mainImageUrl,
      'preparationTime': preparationTime,
      'calories': calories,
      'allergens': allergens,
      'dietaryTags': dietaryTags,
      'variations': variations.map((e) => e.toJson()).toList(),
      'addOns': addOns.map((e) => e.toJson()).toList(),
      'isCustomizable': isCustomizable,
      'vendorId': vendorId,
      'sortOrder': sortOrder,
      'isFeatured': isFeatured,
      'discountPercentage': discountPercentage,
      'discountedPrice': discountedPrice,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  /// Get the effective price (considering discounts)
  double get effectivePrice => discountedPrice ?? price;
  
  /// Check if item has a discount
  bool get hasDiscount => discountPercentage != null && discountPercentage! > 0;
  
  @override
  List<Object?> get props => [
    id, name, description, price, category, subcategory, status,
    isAvailable, images, mainImageUrl, preparationTime, calories,
    allergens, dietaryTags, variations, addOns, isCustomizable,
    vendorId, sortOrder, isFeatured, discountPercentage, discountedPrice,
    createdAt, updatedAt,
  ];
}

/// Menu item variation (size, style, etc.)
class MenuItemVariation extends Equatable {
  final String id;
  final String name;
  final double priceModifier;
  final bool isDefault;
  
  const MenuItemVariation({
    required this.id,
    required this.name,
    required this.priceModifier,
    required this.isDefault,
  });
  
  factory MenuItemVariation.fromJson(Map<String, dynamic> json) {
    return MenuItemVariation(
      id: json['id'] as String,
      name: json['name'] as String,
      priceModifier: (json['priceModifier'] as num).toDouble(),
      isDefault: json['isDefault'] as bool,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'priceModifier': priceModifier,
      'isDefault': isDefault,
    };
  }
  
  @override
  List<Object?> get props => [id, name, priceModifier, isDefault];
}

/// Menu item add-on (extras, toppings, etc.)
class MenuItemAddOn extends Equatable {
  final String id;
  final String name;
  final double price;
  final bool isRequired;
  final int maxQuantity;
  
  const MenuItemAddOn({
    required this.id,
    required this.name,
    required this.price,
    required this.isRequired,
    required this.maxQuantity,
  });
  
  factory MenuItemAddOn.fromJson(Map<String, dynamic> json) {
    return MenuItemAddOn(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      isRequired: json['isRequired'] as bool,
      maxQuantity: json['maxQuantity'] as int,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'isRequired': isRequired,
      'maxQuantity': maxQuantity,
    };
  }
  
  @override
  List<Object?> get props => [id, name, price, isRequired, maxQuantity];
} 