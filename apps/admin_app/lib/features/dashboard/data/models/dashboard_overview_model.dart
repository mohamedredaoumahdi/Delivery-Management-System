import 'package:equatable/equatable.dart';

class DashboardOverview extends Equatable {
  final OrdersSummary orders;
  final RevenueSummary revenue;
  final VendorInsights vendors;
  final DeliveryInsights delivery;
  final CustomerInsights customers;
  final DateTime generatedAt;

  const DashboardOverview({
    required this.orders,
    required this.revenue,
    required this.vendors,
    required this.delivery,
    required this.customers,
    required this.generatedAt,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      orders: OrdersSummary.fromJson(Map<String, dynamic>.from(json['orders'] as Map)),
      revenue: RevenueSummary.fromJson(Map<String, dynamic>.from(json['revenue'] as Map)),
      vendors: VendorInsights.fromJson(Map<String, dynamic>.from(json['vendors'] as Map)),
      delivery: DeliveryInsights.fromJson(Map<String, dynamic>.from(json['delivery'] as Map)),
      customers: CustomerInsights.fromJson(Map<String, dynamic>.from(json['customers'] as Map)),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [orders, revenue, vendors, delivery, customers, generatedAt];
}

class OrdersSummary extends Equatable {
  final OrdersTotals totals;
  final int active;
  final int pendingDeliveries;

  const OrdersSummary({
    required this.totals,
    required this.active,
    required this.pendingDeliveries,
  });

  factory OrdersSummary.fromJson(Map<String, dynamic> json) {
    return OrdersSummary(
      totals: OrdersTotals.fromJson(Map<String, dynamic>.from(json['totals'] as Map)),
      active: json['active'] as int? ?? 0,
      pendingDeliveries: json['pendingDeliveries'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [totals, active, pendingDeliveries];
}

class OrdersTotals extends Equatable {
  final int today;
  final int week;
  final int month;

  const OrdersTotals({
    required this.today,
    required this.week,
    required this.month,
  });

  factory OrdersTotals.fromJson(Map<String, dynamic> json) {
    return OrdersTotals(
      today: json['today'] as int? ?? 0,
      week: json['week'] as int? ?? 0,
      month: json['month'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [today, week, month];
}

class RevenueSummary extends Equatable {
  final double today;
  final double week;
  final double month;
  final double total;

  const RevenueSummary({
    required this.today,
    required this.week,
    required this.month,
    required this.total,
  });

  factory RevenueSummary.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return 0;
    }

    return RevenueSummary(
      today: parseDouble(json['today']),
      week: parseDouble(json['week']),
      month: parseDouble(json['month']),
      total: parseDouble(json['total']),
    );
  }

  @override
  List<Object?> get props => [today, week, month, total];
}

class VendorInsights extends Equatable {
  final int total;
  final int active;
  final double averageRating;
  final List<VendorPerformance> topPerformers;

  const VendorInsights({
    required this.total,
    required this.active,
    required this.averageRating,
    required this.topPerformers,
  });

  factory VendorInsights.fromJson(Map<String, dynamic> json) {
    final performers = (json['topPerformers'] as List? ?? [])
        .map((item) => VendorPerformance.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();

    return VendorInsights(
      total: json['total'] as int? ?? 0,
      active: json['active'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      topPerformers: performers,
    );
  }

  @override
  List<Object?> get props => [total, active, averageRating, topPerformers];
}

class VendorPerformance extends Equatable {
  final String shopId;
  final String shopName;
  final int orders;
  final double revenue;

  const VendorPerformance({
    required this.shopId,
    required this.shopName,
    required this.orders,
    required this.revenue,
  });

  factory VendorPerformance.fromJson(Map<String, dynamic> json) {
    return VendorPerformance(
      shopId: json['shopId'] as String? ?? '',
      shopName: json['shopName'] as String? ?? 'Unknown',
      orders: json['orders'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [shopId, shopName, orders, revenue];
}

class DeliveryInsights extends Equatable {
  final int totalAgents;
  final int activeAgents;
  final int onlineAgents;
  final int offlineAgents;
  final int completedToday;
  final int averageDeliveryTimeMinutes;

  const DeliveryInsights({
    required this.totalAgents,
    required this.activeAgents,
    required this.onlineAgents,
    required this.offlineAgents,
    required this.completedToday,
    required this.averageDeliveryTimeMinutes,
  });

  factory DeliveryInsights.fromJson(Map<String, dynamic> json) {
    return DeliveryInsights(
      totalAgents: json['totalAgents'] as int? ?? 0,
      activeAgents: json['activeAgents'] as int? ?? 0,
      onlineAgents: json['onlineAgents'] as int? ?? 0,
      offlineAgents: json['offlineAgents'] as int? ?? 0,
      completedToday: json['completedToday'] as int? ?? 0,
      averageDeliveryTimeMinutes: json['averageDeliveryTimeMinutes'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [totalAgents, activeAgents, onlineAgents, offlineAgents, completedToday, averageDeliveryTimeMinutes];
}

class CustomerInsights extends Equatable {
  final int totalCustomers;
  final double growthRate;
  final List<CustomerTrendPoint> trend;

  const CustomerInsights({
    required this.totalCustomers,
    required this.growthRate,
    required this.trend,
  });

  factory CustomerInsights.fromJson(Map<String, dynamic> json) {
    final trend = (json['trend'] as List? ?? [])
        .map((item) => CustomerTrendPoint.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();

    return CustomerInsights(
      totalCustomers: json['totalCustomers'] as int? ?? 0,
      growthRate: (json['growthRate'] as num?)?.toDouble() ?? 0,
      trend: trend,
    );
  }

  @override
  List<Object?> get props => [totalCustomers, growthRate, trend];
}

class CustomerTrendPoint extends Equatable {
  final String label;
  final int count;

  const CustomerTrendPoint({
    required this.label,
    required this.count,
  });

  factory CustomerTrendPoint.fromJson(Map<String, dynamic> json) {
    return CustomerTrendPoint(
      label: json['label'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [label, count];
}

