import 'package:domain/domain.dart';
import 'package:json_annotation/json_annotation.dart';

// Uncomment this line after running code generation
// part 'order_model.g.dart';

/// Data model for Order entity
@JsonSerializable()
class OrderModel {
  /// Order ID
  final String id;
  
  /// User ID
  final String userId;
  
  /// Shop ID
  final String shopId;
  
  /// Shop name
  final String shopName;
  
  /// Order items
  final List<OrderItemModel> items;
  
  /// Subtotal
  final double subtotal;
  
  /// Delivery fee
  final double deliveryFee;
  
  /// Service fee
  final double serviceFee;
  
  /// Tax amount
  final double tax;
  
  /// Tip amount
  final double tip;
  
  /// Discount amount
  final double discount;
  
  /// Total amount
  final double total;
  
  /// Payment method as string
  final String paymentMethod;
  
  /// Payment ID
  final String? paymentId;
  
  /// Order status as string
  final String status;
  
  /// Delivery address
  final String deliveryAddress;
  
  /// Delivery latitude
  final double deliveryLatitude;
  
  /// Delivery longitude
  final double deliveryLongitude;
  
  /// Delivery instructions
  final String? deliveryInstructions;
  
  /// Estimated delivery time
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? estimatedDeliveryTime;
  
  /// Actual delivery time
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? deliveredAt;
  
  /// Delivery person ID
  final String? deliveryPersonId;
  
  /// Created at
  @JsonKey(fromJson: _dateTimeFromJson)
  final DateTime createdAt;
  
  /// Updated at
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime updatedAt;

  /// Creates an order model
  OrderModel({
    required this.id,
    required this.userId,
    required this.shopId,
    required this.shopName,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.tax,
    required this.tip,
    required this.discount,
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

  /// Create a model from JSON
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      shopId: json['shopId'] as String,
      shopName: json['shopName'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      serviceFee: (json['serviceFee'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      tip: (json['tip'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      paymentId: json['paymentId'] as String?,
      status: json['status'] as String,
      deliveryAddress: json['deliveryAddress'] as String,
      deliveryLatitude: (json['deliveryLatitude'] as num).toDouble(),
      deliveryLongitude: (json['deliveryLongitude'] as num).toDouble(),
      deliveryInstructions: json['deliveryInstructions'] as String?,
      estimatedDeliveryTime: _dateTimeFromJson(json['estimatedDeliveryTime']),
      deliveredAt: _dateTimeFromJson(json['deliveredAt']),
      deliveryPersonId: json['deliveryPersonId'] as String?,
      createdAt: _dateTimeFromJson(json['createdAt']),
      updatedAt: _dateTimeFromJson(json['updatedAt']),
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'shopId': shopId,
      'shopName': shopName,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'serviceFee': serviceFee,
      'tax': tax,
      'tip': tip,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'deliveryInstructions': deliveryInstructions,
      'estimatedDeliveryTime': _dateTimeToJson(estimatedDeliveryTime),
      'deliveredAt': _dateTimeToJson(deliveredAt),
      'deliveryPersonId': deliveryPersonId,
      'createdAt': _dateTimeToJson(createdAt),
      'updatedAt': _dateTimeToJson(updatedAt),
    };
  }

  /// Convert to domain entity
  Order toDomain() {
    return Order(
      id: id,
      userId: userId,
      shopId: shopId,
      shopName: shopName,
      items: items.map((item) => item.toDomain()).toList(),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      tax: tax,
      tip: tip,
      discount: discount,
      total: total,
      paymentMethod: _mapStringToPaymentMethod(paymentMethod),
      paymentId: paymentId,
      status: _mapStringToOrderStatus(status),
      deliveryAddress: deliveryAddress,
      deliveryLatitude: deliveryLatitude,
      deliveryLongitude: deliveryLongitude,
      deliveryInstructions: deliveryInstructions,
      estimatedDeliveryTime: estimatedDeliveryTime,
      deliveredAt: deliveredAt,
      deliveryPersonId: deliveryPersonId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create from domain entity
  factory OrderModel.fromDomain(Order order) {
    return OrderModel(
      id: order.id,
      userId: order.userId,
      shopId: order.shopId,
      shopName: order.shopName,
      items: order.items.map((item) => OrderItemModel.fromDomain(item)).toList(),
      subtotal: order.subtotal,
      deliveryFee: order.deliveryFee,
      serviceFee: order.serviceFee,
      tax: order.tax,
      tip: order.tip,
      discount: order.discount,
      total: order.total,
      paymentMethod: _mapPaymentMethodToString(order.paymentMethod),
      paymentId: order.paymentId,
      status: _mapOrderStatusToString(order.status),
      deliveryAddress: order.deliveryAddress,
      deliveryLatitude: order.deliveryLatitude,
      deliveryLongitude: order.deliveryLongitude,
      deliveryInstructions: order.deliveryInstructions,
      estimatedDeliveryTime: order.estimatedDeliveryTime,
      deliveredAt: order.deliveredAt,
      deliveryPersonId: order.deliveryPersonId,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    );
  }

  /// Map string to OrderStatus enum
  static OrderStatus _mapStringToOrderStatus(String statusString) {
    switch (statusString.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'accepted':
        return OrderStatus.accepted;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready_for_pickup':
      case 'readyforpickup':
        return OrderStatus.readyForPickup;
      case 'in_delivery':
      case 'indelivery':
        return OrderStatus.inDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'refunded':
        return OrderStatus.refunded;
      default:
        return OrderStatus.pending;
    }
  }

  /// Map OrderStatus enum to string
  static String _mapOrderStatusToString(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.readyForPickup:
        return 'ready_for_pickup';
      case OrderStatus.inDelivery:
        return 'in_delivery';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
      case OrderStatus.refunded:
        return 'refunded';
    }
  }

  /// Map string to PaymentMethod enum
  static PaymentMethod _mapStringToPaymentMethod(String methodString) {
    switch (methodString.toLowerCase()) {
      case 'cash_on_delivery':
      case 'cashondelivery':
      case 'cod':
        return PaymentMethod.cashOnDelivery;
      case 'card':
        return PaymentMethod.card;
      case 'wallet':
        return PaymentMethod.wallet;
      case 'bank_transfer':
      case 'banktransfer':
        return PaymentMethod.bankTransfer;
      default:
        return PaymentMethod.cashOnDelivery;
    }
  }

  /// Map PaymentMethod enum to string
  static String _mapPaymentMethodToString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cashOnDelivery:
        return 'cash_on_delivery';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.wallet:
        return 'wallet';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
    }
  }

  /// Convert timestamp to DateTime
  static DateTime _dateTimeFromJson(String date) => DateTime.parse(date);

  /// Convert DateTime to ISO string
  static String? _dateTimeToJson(DateTime? date) => date?.toIso8601String();
}

/// Data model for OrderItem entity
@JsonSerializable()
class OrderItemModel {
  /// Product ID
  final String productId;
  
  /// Product name
  final String productName;
  
  /// Product price
  final double productPrice;
  
  /// Quantity
  final int quantity;
  
  /// Total price
  final double totalPrice;
  
  /// Instructions
  final String? instructions;

  /// Creates an order item model
  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    required this.totalPrice,
    this.instructions,
  });

  /// Create a model from JSON
  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productPrice: (json['productPrice'] as num).toDouble(),
      quantity: json['quantity'] as int,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      instructions: json['instructions'] as String?,
    );
  }

  /// Convert model to JSON
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

  /// Convert to domain entity
  OrderItem toDomain() {
    return OrderItem(
      productId: productId,
      productName: productName,
      productPrice: productPrice,
      quantity: quantity,
      totalPrice: totalPrice,
      instructions: instructions,
    );
  }

  /// Create from domain entity
  factory OrderItemModel.fromDomain(OrderItem item) {
    return OrderItemModel(
      productId: item.productId,
      productName: item.productName,
      productPrice: item.productPrice,
      quantity: item.quantity,
      totalPrice: item.totalPrice,
      instructions: item.instructions,
    );
  }
}