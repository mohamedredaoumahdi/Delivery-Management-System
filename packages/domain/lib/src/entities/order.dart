import 'package:equatable/equatable.dart';

/// Order status types
enum OrderStatus {
  /// Order has been placed but not yet accepted by vendor
  pending,
  
  /// Order has been accepted by vendor but not yet prepared
  accepted,
  
  /// Order is being prepared
  preparing,
  
  /// Order is ready for pickup
  readyForPickup,
  
  /// Order has been picked up by delivery person
  inDelivery,
  
  /// Order has been delivered
  delivered,
  
  /// Order has been cancelled
  cancelled,
  
  /// Order has been refunded
  refunded,
}

/// Payment method types
enum PaymentMethod {
  /// Cash on delivery
  cashOnDelivery,
  
  /// Credit/debit card
  card,
  
  /// Digital wallet
  wallet,
  
  /// Bank transfer
  bankTransfer,
}

/// Order item representing a product in an order
class OrderItem extends Equatable {
  /// Product ID
  final String productId;
  
  /// Product name (stored to keep history even if product changes)
  final String productName;
  
  /// Product price at time of order
  final double productPrice;
  
  /// Quantity ordered
  final int quantity;
  
  /// Total price for this item (price * quantity)
  final double totalPrice;
  
  /// Special instructions for this item
  final String? instructions;
  
  /// Creates an order item
  const OrderItem({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    required this.totalPrice,
    this.instructions,
  });
  
  /// Creates an order item from JSON
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productPrice: (json['productPrice'] as num).toDouble(),
      quantity: json['quantity'] as int,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      instructions: json['instructions'] as String?,
    );
  }
  
  /// Converts the order item to JSON
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'productPrice': productPrice,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'instructions': instructions,
    };
  }
  
  @override
  List<Object?> get props => [
    productId, productName, productPrice, quantity, totalPrice, instructions,
  ];
}

/// Order entity representing an order in the system
class Order extends Equatable {
  /// Unique identifier for the order
  final String id;
  
  /// User ID who placed the order
  final String userId;
  
  /// Shop ID where the order was placed
  final String shopId;
  
  /// Shop name (stored to keep history)
  final String shopName;
  
  /// Order items
  final List<OrderItem> items;
  
  /// Subtotal (sum of all items)
  final double subtotal;
  
  /// Delivery fee
  final double deliveryFee;
  
  /// Service fee
  final double serviceFee;
  
  /// Tax amount
  final double tax;
  
  /// Tip amount
  final double tip;
  
  /// Discount amount (if any)
  final double discount;
  
  /// Total amount (subtotal + fees + tax - discount)
  final double total;
  
  /// Payment method
  final PaymentMethod paymentMethod;
  
  /// Payment ID (for card/online payments)
  final String? paymentId;
  
  /// Order status
  final OrderStatus status;
  
  /// Delivery address
  final String deliveryAddress;
  
  /// Delivery latitude
  final double deliveryLatitude;
  
  /// Delivery longitude
  final double deliveryLongitude;
  
  /// Delivery instructions
  final String? deliveryInstructions;
  
  /// Delivery ETA
  final DateTime? estimatedDeliveryTime;
  
  /// Actual delivery time (null if not delivered yet)
  final DateTime? deliveredAt;
  
  /// Delivery person ID (null if not assigned yet)
  final String? deliveryPersonId;
  
  /// Order placed time
  final DateTime createdAt;
  
  /// Order last updated time
  final DateTime updatedAt;

  /// Creates an order entity
  const Order({
    required this.id,
    required this.userId,
    required this.shopId,
    required this.shopName,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.tax,
    this.tip = 0,
    this.discount = 0,
    required this.total,
    required this.paymentMethod,
    this.paymentId,
    required this.status,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    this.deliveryInstructions,
    this.estimatedDeliveryTime,
    this.deliveredAt,
    this.deliveryPersonId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this order with the given fields replaced
  Order copyWith({
    String? id,
    String? userId,
    String? shopId,
    String? shopName,
    List<OrderItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? serviceFee,
    double? tax,
    double? tip,
    double? discount,
    double? total,
    PaymentMethod? paymentMethod,
    String? Function()? paymentId,
    OrderStatus? status,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? Function()? deliveryInstructions,
    DateTime? Function()? estimatedDeliveryTime,
    DateTime? Function()? deliveredAt,
    String? Function()? deliveryPersonId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      serviceFee: serviceFee ?? this.serviceFee,
      tax: tax ?? this.tax,
      tip: tip ?? this.tip,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId != null ? paymentId() : this.paymentId,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      deliveryInstructions: deliveryInstructions != null 
          ? deliveryInstructions() 
          : this.deliveryInstructions,
      estimatedDeliveryTime: estimatedDeliveryTime != null 
          ? estimatedDeliveryTime() 
          : this.estimatedDeliveryTime,
      deliveredAt: deliveredAt != null ? deliveredAt() : this.deliveredAt,
      deliveryPersonId: deliveryPersonId != null 
          ? deliveryPersonId() 
          : this.deliveryPersonId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// Empty order instance
  factory Order.empty() {
    return Order(
      id: '',
      userId: '',
      shopId: '',
      shopName: '',
      items: const [],
      subtotal: 0,
      deliveryFee: 0,
      serviceFee: 0,
      tax: 0,
      total: 0,
      paymentMethod: PaymentMethod.cashOnDelivery,
      status: OrderStatus.pending,
      deliveryAddress: '',
      deliveryLatitude: 0,
      deliveryLongitude: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Creates an order from JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['userId'] as String,
      shopId: json['shopId'] as String,
      shopName: json['shopName'] as String,
      items: (json['items'] as List)
          .map((e) => OrderItem.fromJson(e))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      serviceFee: (json['serviceFee'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      tip: (json['tip'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num).toDouble(),
      paymentMethod: _parsePaymentMethod(json['paymentMethod'] as String),
      paymentId: json['paymentId'] as String?,
      status: _parseOrderStatus(json['status'] as String),
      deliveryAddress: json['deliveryAddress'] as String,
      deliveryLatitude: (json['deliveryLatitude'] as num).toDouble(),
      deliveryLongitude: (json['deliveryLongitude'] as num).toDouble(),
      deliveryInstructions: json['deliveryInstructions'] as String?,
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null 
          ? DateTime.parse(json['estimatedDeliveryTime'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null 
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      deliveryPersonId: json['deliveryPersonId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Parse order status from string
  static OrderStatus _parseOrderStatus(String statusString) {
    switch (statusString.toUpperCase()) {
      case 'PENDING':
        return OrderStatus.pending;
      case 'ACCEPTED':
        return OrderStatus.accepted;
      case 'PREPARING':
        return OrderStatus.preparing;
      case 'READY_FOR_PICKUP':
        return OrderStatus.readyForPickup;
      case 'IN_DELIVERY':
        return OrderStatus.inDelivery;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      case 'REFUNDED':
        return OrderStatus.refunded;
      default:
        return OrderStatus.pending;
    }
  }

  /// Parse payment method from string
  static PaymentMethod _parsePaymentMethod(String methodString) {
    switch (methodString.toUpperCase()) {
      case 'CASH_ON_DELIVERY':
        return PaymentMethod.cashOnDelivery;
      case 'CARD':
        return PaymentMethod.card;
      case 'WALLET':
        return PaymentMethod.wallet;
      case 'BANK_TRANSFER':
        return PaymentMethod.bankTransfer;
      default:
        return PaymentMethod.cashOnDelivery;
    }
  }

  /// Converts the order to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'shopId': shopId,
      'shopName': shopName,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'serviceFee': serviceFee,
      'tax': tax,
      'tip': tip,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'paymentId': paymentId,
      'status': status.toString().split('.').last,
      'deliveryAddress': deliveryAddress,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'deliveryInstructions': deliveryInstructions,
      'estimatedDeliveryTime': estimatedDeliveryTime?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'deliveryPersonId': deliveryPersonId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  /// Calculate total number of items
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  
  /// Check if order can be cancelled
  bool get canBeCancelled => [
    OrderStatus.pending, 
    OrderStatus.accepted
  ].contains(status);
  
  /// Check if order is active (not completed or cancelled)
  bool get isActive => ![
    OrderStatus.delivered, 
    OrderStatus.cancelled, 
    OrderStatus.refunded
  ].contains(status);
  
  @override
  List<Object?> get props => [
    id, userId, shopId, shopName, items, subtotal, deliveryFee, serviceFee,
    tax, tip, discount, total, paymentMethod, paymentId, status, deliveryAddress,
    deliveryLatitude, deliveryLongitude, deliveryInstructions, estimatedDeliveryTime,
    deliveredAt, deliveryPersonId, createdAt, updatedAt,
  ];
}