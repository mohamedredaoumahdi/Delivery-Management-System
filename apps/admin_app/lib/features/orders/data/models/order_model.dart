import 'package:flutter/material.dart';

class OrderModel {
  final String id;
  final String orderNumber;
  final String userId;
  final String shopId;
  final String shopName;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final String? deliveryInstructions;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double tax;
  final double tip;
  final double discount;
  final double total;
  final String paymentMethod;
  final String? paymentId;
  final String status;
  final DateTime? estimatedDeliveryTime;
  final DateTime? deliveredAt;
  final String? deliveryPersonId;
  final String? rejectionReason;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? shop;
  final Map<String, dynamic>? deliveryPerson;
  final List<dynamic>? items;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.shopId,
    required this.shopName,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    this.deliveryInstructions,
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
    this.estimatedDeliveryTime,
    this.deliveredAt,
    this.deliveryPersonId,
    this.rejectionReason,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.shop,
    this.deliveryPerson,
    this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String? ?? json['order_number'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String,
      shopId: json['shopId'] as String? ?? json['shop_id'] as String,
      shopName: json['shopName'] as String? ?? json['shop_name'] as String? ?? '',
      deliveryAddress: json['deliveryAddress'] as String? ?? json['delivery_address'] as String,
      deliveryLatitude: (json['deliveryLatitude'] as num?)?.toDouble() ?? (json['delivery_latitude'] as num).toDouble(),
      deliveryLongitude: (json['deliveryLongitude'] as num?)?.toDouble() ?? (json['delivery_longitude'] as num).toDouble(),
      deliveryInstructions: json['deliveryInstructions'] as String? ?? json['delivery_instructions'] as String?,
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? (json['delivery_fee'] as num).toDouble(),
      serviceFee: (json['serviceFee'] as num?)?.toDouble() ?? (json['service_fee'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      tip: (json['tip'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String? ?? json['payment_method'] as String,
      paymentId: json['paymentId'] as String? ?? json['payment_id'] as String?,
      status: json['status'] as String,
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null
          ? DateTime.parse(json['estimatedDeliveryTime'] as String)
          : (json['estimated_delivery_time'] != null
              ? DateTime.parse(json['estimated_delivery_time'] as String)
              : null),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : (json['delivered_at'] != null
              ? DateTime.parse(json['delivered_at'] as String)
              : null),
      deliveryPersonId: json['deliveryPersonId'] as String? ?? json['delivery_person_id'] as String?,
      rejectionReason: json['rejectionReason'] as String? ?? json['rejection_reason'] as String?,
      cancellationReason: json['cancellationReason'] as String? ?? json['cancellation_reason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? json['updated_at'] as String),
      user: json['user'] as Map<String, dynamic>?,
      shop: json['shop'] as Map<String, dynamic>?,
      deliveryPerson: json['deliveryPerson'] as Map<String, dynamic>? ?? json['deliveryPerson'] as Map<String, dynamic>?,
      items: json['items'] as List<dynamic>?,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'ACCEPTED':
        return 'Accepted';
      case 'PREPARING':
        return 'Preparing';
      case 'READY_FOR_PICKUP':
        return 'Ready for Pickup';
      case 'IN_DELIVERY':
        return 'In Delivery';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLATION_REQUESTED':
        return 'Cancellation Requested';
      case 'CANCELLED':
        return 'Cancelled';
      case 'REFUNDED':
        return 'Refunded';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
        return Colors.blue;
      case 'PREPARING':
        return Colors.purple;
      case 'READY_FOR_PICKUP':
        return Colors.teal;
      case 'IN_DELIVERY':
        return Colors.indigo;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLATION_REQUESTED':
        return Colors.amber;
      case 'CANCELLED':
        return Colors.red;
      case 'REFUNDED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

