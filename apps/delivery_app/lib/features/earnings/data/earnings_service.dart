import 'package:dio/dio.dart';
import '../domain/models/earnings_data.dart';

class EarningsService {
  final Dio _dio;

  EarningsService(this._dio);

  Future<EarningsData> getEarnings({String period = 'today'}) async {
    print('🚀 EarningsService: Getting earnings for period: $period');
    try {
      final response = await _dio.get('/delivery/earnings', queryParameters: {'period': period});
      print('📥 EarningsService: Response status: ${response.statusCode}');
      print('📥 EarningsService: Response data: ${response.data}');

      if (response.data['status'] == 'success') {
        final data = response.data['data'];
        print('✅ EarningsService: Successfully got earnings data');

        return EarningsData(
          totalEarnings: (data['totalEarnings'] ?? 0).toDouble(),
          todayEarnings: (data['todayEarnings'] ?? 0).toDouble(),
          deliveryCount: data['deliveryCount'] ?? 0,
          averagePerOrder: (data['averagePerOrder'] ?? 0).toDouble(),
          onlineHours: data['onlineHours'] ?? 0,
          onlineMinutes: data['onlineMinutes'] ?? 0,
          recentDeliveries: (data['recentDeliveries'] as List? ?? []).map((delivery) => DeliveryEarning(
            orderNumber: delivery['orderNumber'] ?? '',
            completedAt: DateTime.parse(delivery['completedAt'] ?? DateTime.now().toIso8601String()),
            earnings: (delivery['earnings'] ?? 0).toDouble(),
            distance: (delivery['distance'] ?? 0).toDouble(),
          )).toList(),
          basePay: (data['basePay'] ?? 0).toDouble(),
          tips: (data['tips'] ?? 0).toDouble(),
          bonuses: (data['bonuses'] ?? 0).toDouble(),
          distanceBonus: (data['distanceBonus'] ?? 0).toDouble(),
          paymentHistory: (data['paymentHistory'] as List? ?? []).map((payment) => PaymentHistory(
            description: payment['description'] ?? '',
            date: DateTime.parse(payment['date'] ?? DateTime.now().toIso8601String()),
            amount: (payment['amount'] ?? 0).toDouble(),
            status: payment['status'] ?? 'Pending',
          )).toList(),
          weeklyDeliveries: data['weeklyDeliveries'] ?? 0,
          weeklyEarnings: (data['weeklyEarnings'] ?? 0).toDouble(),
          weeklyHours: data['weeklyHours'] ?? 0,
          acceptanceRate: (data['acceptanceRate'] ?? 0).toDouble(),
          customerRating: (data['customerRating'] ?? 5.0).toDouble(),
          onTimeRate: (data['onTimeRate'] ?? 0).toDouble(),
          averageTip: (data['averageTip'] ?? 0).toDouble(),
          bestTip: (data['bestTip'] ?? 0).toDouble(),
          tipRate: (data['tipRate'] ?? 0).toDouble(),
          dailyGoal: (data['dailyGoal'] ?? 0).toDouble(),
          weeklyGoal: (data['weeklyGoal'] ?? 0).toDouble(),
        );
      } else {
        print('❌ EarningsService: Failed to get earnings - response status is not success');
        throw Exception('Failed to get earnings data');
      }
    } on DioException catch (e) {
      print('❌ EarningsService: DioException in getEarnings');
      print('❌ EarningsService: Status code: ${e.response?.statusCode}');
      print('❌ EarningsService: Response data: ${e.response?.data}');
      print('❌ EarningsService: Error message: ${e.message}');
      throw Exception('Failed to get earnings: ${e.message}');
    } catch (e) {
      print('❌ EarningsService: Unexpected error in getEarnings: $e');
      rethrow;
    }
  }
} 