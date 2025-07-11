import 'package:flutter/material.dart';

class EarningsData {
  final double totalEarnings;
  final double todayEarnings;
  final int deliveryCount;
  final double averagePerOrder;
  final int onlineHours;
  final int onlineMinutes;
  final List<DeliveryEarning> recentDeliveries;
  final double basePay;
  final double tips;
  final double bonuses;
  final double distanceBonus;
  final List<PaymentHistory> paymentHistory;
  final int weeklyDeliveries;
  final double weeklyEarnings;
  final int weeklyHours;
  final double acceptanceRate;
  final double customerRating;
  final double onTimeRate;
  final double averageTip;
  final double bestTip;
  final double tipRate;
  final double dailyGoal;
  final double weeklyGoal;

  const EarningsData({
    required this.totalEarnings,
    required this.todayEarnings,
    required this.deliveryCount,
    required this.averagePerOrder,
    required this.onlineHours,
    required this.onlineMinutes,
    required this.recentDeliveries,
    required this.basePay,
    required this.tips,
    required this.bonuses,
    required this.distanceBonus,
    required this.paymentHistory,
    required this.weeklyDeliveries,
    required this.weeklyEarnings,
    required this.weeklyHours,
    required this.acceptanceRate,
    required this.customerRating,
    required this.onTimeRate,
    required this.averageTip,
    required this.bestTip,
    required this.tipRate,
    required this.dailyGoal,
    required this.weeklyGoal,
  });
}

class DeliveryEarning {
  final String orderNumber;
  final DateTime completedAt;
  final double earnings;
  final double distance;

  const DeliveryEarning({
    required this.orderNumber,
    required this.completedAt,
    required this.earnings,
    required this.distance,
  });
}

class PaymentHistory {
  final String description;
  final DateTime date;
  final double amount;
  final String status;

  const PaymentHistory({
    required this.description,
    required this.date,
    required this.amount,
    required this.status,
  });
} 