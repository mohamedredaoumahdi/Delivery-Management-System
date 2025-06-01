import 'package:equatable/equatable.dart';
import 'order.dart';

/// Vendor dashboard analytics and overview data
class VendorDashboard extends Equatable {
  /// Today's orders count
  final int todayOrders;
  
  /// Today's revenue
  final double todayRevenue;
  
  /// Number of pending orders
  final int pendingOrders;
  
  /// Number of preparing orders
  final int preparingOrders;
  
  /// Number of ready orders
  final int readyOrders;
  
  /// Number of completed orders today
  final int completedOrders;
  
  /// Vendor's current rating
  final double rating;
  
  /// Total number of ratings
  final int totalRatings;
  
  /// This week's orders count
  final int weekOrders;
  
  /// This week's revenue
  final double weekRevenue;
  
  /// This month's orders count
  final int monthOrders;
  
  /// This month's revenue
  final double monthRevenue;
  
  /// Total orders all time
  final int totalOrders;
  
  /// Total revenue all time
  final double totalRevenue;
  
  /// Average order value
  final double averageOrderValue;
  
  /// Recent orders (last 10)
  final List<Order> recentOrders;
  
  /// Top selling items today
  final List<DashboardMenuItem> topItems;
  
  /// Revenue trend data for charts (last 7 days)
  final List<DashboardDataPoint> revenueTrend;
  
  /// Orders trend data for charts (last 7 days)
  final List<DashboardDataPoint> ordersTrend;
  
  /// Peak hours data
  final List<PeakHourData> peakHours;
  
  /// Whether the vendor shop is currently open
  final bool isShopOpen;
  
  /// Number of active menu items
  final int activeMenuItems;
  
  /// Number of out of stock items
  final int outOfStockItems;
  
  /// Date and time of last update
  final DateTime lastUpdated;

  /// Creates a vendor dashboard entity
  const VendorDashboard({
    required this.todayOrders,
    required this.todayRevenue,
    required this.pendingOrders,
    required this.preparingOrders,
    required this.readyOrders,
    required this.completedOrders,
    required this.rating,
    required this.totalRatings,
    required this.weekOrders,
    required this.weekRevenue,
    required this.monthOrders,
    required this.monthRevenue,
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.recentOrders,
    required this.topItems,
    required this.revenueTrend,
    required this.ordersTrend,
    required this.peakHours,
    required this.isShopOpen,
    required this.activeMenuItems,
    required this.outOfStockItems,
    required this.lastUpdated,
  });

  /// Creates a copy of this dashboard with the given fields replaced
  VendorDashboard copyWith({
    int? todayOrders,
    double? todayRevenue,
    int? pendingOrders,
    int? preparingOrders,
    int? readyOrders,
    int? completedOrders,
    double? rating,
    int? totalRatings,
    int? weekOrders,
    double? weekRevenue,
    int? monthOrders,
    double? monthRevenue,
    int? totalOrders,
    double? totalRevenue,
    double? averageOrderValue,
    List<Order>? recentOrders,
    List<DashboardMenuItem>? topItems,
    List<DashboardDataPoint>? revenueTrend,
    List<DashboardDataPoint>? ordersTrend,
    List<PeakHourData>? peakHours,
    bool? isShopOpen,
    int? activeMenuItems,
    int? outOfStockItems,
    DateTime? lastUpdated,
  }) {
    return VendorDashboard(
      todayOrders: todayOrders ?? this.todayOrders,
      todayRevenue: todayRevenue ?? this.todayRevenue,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      preparingOrders: preparingOrders ?? this.preparingOrders,
      readyOrders: readyOrders ?? this.readyOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      weekOrders: weekOrders ?? this.weekOrders,
      weekRevenue: weekRevenue ?? this.weekRevenue,
      monthOrders: monthOrders ?? this.monthOrders,
      monthRevenue: monthRevenue ?? this.monthRevenue,
      totalOrders: totalOrders ?? this.totalOrders,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      averageOrderValue: averageOrderValue ?? this.averageOrderValue,
      recentOrders: recentOrders ?? this.recentOrders,
      topItems: topItems ?? this.topItems,
      revenueTrend: revenueTrend ?? this.revenueTrend,
      ordersTrend: ordersTrend ?? this.ordersTrend,
      peakHours: peakHours ?? this.peakHours,
      isShopOpen: isShopOpen ?? this.isShopOpen,
      activeMenuItems: activeMenuItems ?? this.activeMenuItems,
      outOfStockItems: outOfStockItems ?? this.outOfStockItems,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  /// Empty dashboard instance
  factory VendorDashboard.empty() {
    return VendorDashboard(
      todayOrders: 0,
      todayRevenue: 0,
      pendingOrders: 0,
      preparingOrders: 0,
      readyOrders: 0,
      completedOrders: 0,
      rating: 0,
      totalRatings: 0,
      weekOrders: 0,
      weekRevenue: 0,
      monthOrders: 0,
      monthRevenue: 0,
      totalOrders: 0,
      totalRevenue: 0,
      averageOrderValue: 0,
      recentOrders: [],
      topItems: [],
      revenueTrend: [],
      ordersTrend: [],
      peakHours: [],
      isShopOpen: false,
      activeMenuItems: 0,
      outOfStockItems: 0,
      lastUpdated: DateTime.now(),
    );
  }
  
  /// Creates a dashboard from JSON
  factory VendorDashboard.fromJson(Map<String, dynamic> json) {
    return VendorDashboard(
      todayOrders: json['todayOrders'] as int,
      todayRevenue: (json['todayRevenue'] as num).toDouble(),
      pendingOrders: json['pendingOrders'] as int,
      preparingOrders: json['preparingOrders'] as int,
      readyOrders: json['readyOrders'] as int,
      completedOrders: json['completedOrders'] as int,
      rating: (json['rating'] as num).toDouble(),
      totalRatings: json['totalRatings'] as int,
      weekOrders: json['weekOrders'] as int,
      weekRevenue: (json['weekRevenue'] as num).toDouble(),
      monthOrders: json['monthOrders'] as int,
      monthRevenue: (json['monthRevenue'] as num).toDouble(),
      totalOrders: json['totalOrders'] as int,
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      averageOrderValue: (json['averageOrderValue'] as num).toDouble(),
      recentOrders: (json['recentOrders'] as List)
          .map((e) => Order.fromJson(e))
          .toList(),
      topItems: (json['topItems'] as List)
          .map((e) => DashboardMenuItem.fromJson(e))
          .toList(),
      revenueTrend: (json['revenueTrend'] as List)
          .map((e) => DashboardDataPoint.fromJson(e))
          .toList(),
      ordersTrend: (json['ordersTrend'] as List)
          .map((e) => DashboardDataPoint.fromJson(e))
          .toList(),
      peakHours: (json['peakHours'] as List)
          .map((e) => PeakHourData.fromJson(e))
          .toList(),
      isShopOpen: json['isShopOpen'] as bool,
      activeMenuItems: json['activeMenuItems'] as int,
      outOfStockItems: json['outOfStockItems'] as int,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  /// Converts the dashboard to JSON
  Map<String, dynamic> toJson() {
    return {
      'todayOrders': todayOrders,
      'todayRevenue': todayRevenue,
      'pendingOrders': pendingOrders,
      'preparingOrders': preparingOrders,
      'readyOrders': readyOrders,
      'completedOrders': completedOrders,
      'rating': rating,
      'totalRatings': totalRatings,
      'weekOrders': weekOrders,
      'weekRevenue': weekRevenue,
      'monthOrders': monthOrders,
      'monthRevenue': monthRevenue,
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'averageOrderValue': averageOrderValue,
      'recentOrders': recentOrders.map((e) => e.toJson()).toList(),
      'topItems': topItems.map((e) => e.toJson()).toList(),
      'revenueTrend': revenueTrend.map((e) => e.toJson()).toList(),
      'ordersTrend': ordersTrend.map((e) => e.toJson()).toList(),
      'peakHours': peakHours.map((e) => e.toJson()).toList(),
      'isShopOpen': isShopOpen,
      'activeMenuItems': activeMenuItems,
      'outOfStockItems': outOfStockItems,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
  
  /// Get total active orders (pending + preparing + ready)
  int get totalActiveOrders => pendingOrders + preparingOrders + readyOrders;
  
  /// Get completion rate for today
  double get todayCompletionRate {
    final totalTodayOrders = completedOrders + totalActiveOrders;
    return totalTodayOrders > 0 ? (completedOrders / totalTodayOrders) * 100 : 0;
  }
  
  @override
  List<Object?> get props => [
    todayOrders, todayRevenue, pendingOrders, preparingOrders, readyOrders,
    completedOrders, rating, totalRatings, weekOrders, weekRevenue,
    monthOrders, monthRevenue, totalOrders, totalRevenue, averageOrderValue,
    recentOrders, topItems, revenueTrend, ordersTrend, peakHours,
    isShopOpen, activeMenuItems, outOfStockItems, lastUpdated,
  ];
}

/// Dashboard menu item with sales data
class DashboardMenuItem extends Equatable {
  final String id;
  final String name;
  final int orderCount;
  final double revenue;
  final String? imageUrl;
  
  const DashboardMenuItem({
    required this.id,
    required this.name,
    required this.orderCount,
    required this.revenue,
    this.imageUrl,
  });
  
  factory DashboardMenuItem.fromJson(Map<String, dynamic> json) {
    return DashboardMenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      orderCount: json['orderCount'] as int,
      revenue: (json['revenue'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'orderCount': orderCount,
      'revenue': revenue,
      'imageUrl': imageUrl,
    };
  }
  
  @override
  List<Object?> get props => [id, name, orderCount, revenue, imageUrl];
}

/// Data point for charts and trends
class DashboardDataPoint extends Equatable {
  final DateTime date;
  final double value;
  final String? label;
  
  const DashboardDataPoint({
    required this.date,
    required this.value,
    this.label,
  });
  
  factory DashboardDataPoint.fromJson(Map<String, dynamic> json) {
    return DashboardDataPoint(
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
      label: json['label'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'value': value,
      'label': label,
    };
  }
  
  @override
  List<Object?> get props => [date, value, label];
}

/// Peak hour data for analytics
class PeakHourData extends Equatable {
  final int hour; // 0-23
  final int orderCount;
  final double revenue;
  
  const PeakHourData({
    required this.hour,
    required this.orderCount,
    required this.revenue,
  });
  
  factory PeakHourData.fromJson(Map<String, dynamic> json) {
    return PeakHourData(
      hour: json['hour'] as int,
      orderCount: json['orderCount'] as int,
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'orderCount': orderCount,
      'revenue': revenue,
    };
  }
  
  /// Get formatted hour string (e.g., "2 PM", "14:00")
  String get formattedHour {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
  
  @override
  List<Object?> get props => [hour, orderCount, revenue];
} 