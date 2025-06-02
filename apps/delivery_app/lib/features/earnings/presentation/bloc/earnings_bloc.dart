import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'earnings_event.dart';
part 'earnings_state.dart';

@injectable
class EarningsBloc extends Bloc<EarningsEvent, EarningsState> {
  EarningsBloc() : super(const EarningsInitial()) {
    on<EarningsLoadEvent>(_onLoad);
    on<EarningsRefreshEvent>(_onRefresh);
  }

  Future<void> _onLoad(
    EarningsLoadEvent event,
    Emitter<EarningsState> emit,
  ) async {
    emit(const EarningsLoading());

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock earnings data
      emit(const EarningsLoaded(EarningsData(
        todayEarnings: 125.50,
        weeklyEarnings: 847.25,
        monthlyEarnings: 3425.75,
        totalEarnings: 15842.00,
        deliveriesCompleted: 1247,
        averageRating: 4.8,
        hoursWorked: 145,
      )));
    } catch (error) {
      emit(EarningsError(error.toString()));
    }
  }

  Future<void> _onRefresh(
    EarningsRefreshEvent event,
    Emitter<EarningsState> emit,
  ) async {
    // Don't show loading for refresh
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock updated earnings data
      emit(const EarningsLoaded(EarningsData(
        todayEarnings: 125.50,
        weeklyEarnings: 847.25,
        monthlyEarnings: 3425.75,
        totalEarnings: 15842.00,
        deliveriesCompleted: 1247,
        averageRating: 4.8,
        hoursWorked: 145,
      )));
    } catch (error) {
      emit(EarningsError(error.toString()));
    }
  }
}

// Mock data model
class EarningsData {
  final double todayEarnings;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final double totalEarnings;
  final int deliveriesCompleted;
  final double averageRating;
  final int hoursWorked;

  const EarningsData({
    required this.todayEarnings,
    required this.weeklyEarnings,
    required this.monthlyEarnings,
    required this.totalEarnings,
    required this.deliveriesCompleted,
    required this.averageRating,
    required this.hoursWorked,
  });
} 