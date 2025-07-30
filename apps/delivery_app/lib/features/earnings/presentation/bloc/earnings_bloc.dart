import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/models/earnings_data.dart';

part 'earnings_event.dart';
part 'earnings_state.dart';


class EarningsBloc extends Bloc<EarningsEvent, EarningsState> {
  EarningsBloc() : super(const EarningsInitial()) {
    on<EarningsLoadEvent>(_onLoad);
    on<EarningsRefreshEvent>(_onRefresh);
    on<EarningsPeriodChangedEvent>(_onPeriodChanged);
  }

  Future<void> _onLoad(
    EarningsLoadEvent event,
    Emitter<EarningsState> emit,
  ) async {
    try {
      emit(const EarningsLoading());
      // TODO: Implement actual data loading
      final data = EarningsData(
        totalEarnings: 125.50,
        todayEarnings: 25.50,
        deliveryCount: 5,
        averagePerOrder: 25.10,
        onlineHours: 4,
        onlineMinutes: 30,
        recentDeliveries: [
          DeliveryEarning(
            orderNumber: "123",
            completedAt: DateTime.now(),
            earnings: 25.50,
            distance: 3.2,
          ),
        ],
        basePay: 100.00,
        tips: 25.50,
        bonuses: 0.00,
        distanceBonus: 0.00,
        paymentHistory: [
          PaymentHistory(
            description: "Weekly Payment",
            date: DateTime.now(),
            amount: 625.50,
            status: "Completed",
          ),
        ],
        weeklyDeliveries: 25,
        weeklyEarnings: 625.50,
        weeklyHours: 20,
        acceptanceRate: 95.0,
        customerRating: 4.8,
        onTimeRate: 98.0,
        averageTip: 5.0,
        bestTip: 10.0,
        tipRate: 80.0,
        dailyGoal: 100.0,
        weeklyGoal: 500.0,
      );
      emit(EarningsLoaded(data));
    } catch (e) {
      emit(EarningsError(e.toString()));
    }
  }

  Future<void> _onRefresh(
    EarningsRefreshEvent event,
    Emitter<EarningsState> emit,
  ) async {
    try {
      emit(const EarningsLoading());
      // TODO: Implement actual data refresh
      final data = EarningsData(
        totalEarnings: 125.50,
        todayEarnings: 25.50,
        deliveryCount: 5,
        averagePerOrder: 25.10,
        onlineHours: 4,
        onlineMinutes: 30,
        recentDeliveries: [
          DeliveryEarning(
            orderNumber: "123",
            completedAt: DateTime.now(),
            earnings: 25.50,
            distance: 3.2,
          ),
        ],
        basePay: 100.00,
        tips: 25.50,
        bonuses: 0.00,
        distanceBonus: 0.00,
        paymentHistory: [
          PaymentHistory(
            description: "Weekly Payment",
            date: DateTime.now(),
            amount: 625.50,
            status: "Completed",
          ),
        ],
        weeklyDeliveries: 25,
        weeklyEarnings: 625.50,
        weeklyHours: 20,
        acceptanceRate: 95.0,
        customerRating: 4.8,
        onTimeRate: 98.0,
        averageTip: 5.0,
        bestTip: 10.0,
        tipRate: 80.0,
        dailyGoal: 100.0,
        weeklyGoal: 500.0,
      );
      emit(EarningsLoaded(data));
    } catch (e) {
      emit(EarningsError(e.toString()));
    }
  }

  Future<void> _onPeriodChanged(
    EarningsPeriodChangedEvent event,
    Emitter<EarningsState> emit,
  ) async {
    try {
      emit(const EarningsLoading());
      // TODO: Implement period change logic
      final data = EarningsData(
        totalEarnings: 125.50,
        todayEarnings: 25.50,
        deliveryCount: 5,
        averagePerOrder: 25.10,
        onlineHours: 4,
        onlineMinutes: 30,
        recentDeliveries: [
          DeliveryEarning(
            orderNumber: "123",
            completedAt: DateTime.now(),
            earnings: 25.50,
            distance: 3.2,
          ),
        ],
        basePay: 100.00,
        tips: 25.50,
        bonuses: 0.00,
        distanceBonus: 0.00,
        paymentHistory: [
          PaymentHistory(
            description: "Weekly Payment",
            date: DateTime.now(),
            amount: 625.50,
            status: "Completed",
          ),
        ],
        weeklyDeliveries: 25,
        weeklyEarnings: 625.50,
        weeklyHours: 20,
        acceptanceRate: 95.0,
        customerRating: 4.8,
        onTimeRate: 98.0,
        averageTip: 5.0,
        bestTip: 10.0,
        tipRate: 80.0,
        dailyGoal: 100.0,
        weeklyGoal: 500.0,
      );
      emit(EarningsLoaded(data));
    } catch (e) {
      emit(EarningsError(e.toString()));
    }
  }
} 