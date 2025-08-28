import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:core/core.dart';
import '../../data/earnings_service.dart';
import '../../domain/models/earnings_data.dart';

part 'earnings_event.dart';
part 'earnings_state.dart';

class EarningsBloc extends Bloc<EarningsEvent, EarningsState> {
  final EarningsService _earningsService;
  final LoggerService _logger;
  String _currentPeriod = 'today';

  EarningsBloc(this._earningsService, this._logger) : super(const EarningsInitial()) {
    on<EarningsLoadEvent>(_onLoad);
    on<EarningsRefreshEvent>(_onRefresh);
    on<EarningsPeriodChangedEvent>(_onPeriodChanged);
  }

  Future<void> _onLoad(
    EarningsLoadEvent event,
    Emitter<EarningsState> emit,
  ) async {
    _logger.i('🚀 EarningsBloc: Loading earnings data');
    try {
      emit(const EarningsLoading());
      final data = await _earningsService.getEarnings(period: _currentPeriod);
      _logger.i('✅ EarningsBloc: Successfully loaded earnings data');
      emit(EarningsLoaded(data));
    } catch (e) {
      _logger.e('❌ EarningsBloc: Error loading earnings: $e');
      emit(EarningsError(e.toString()));
    }
  }

  Future<void> _onRefresh(
    EarningsRefreshEvent event,
    Emitter<EarningsState> emit,
  ) async {
    _logger.i('🔄 EarningsBloc: Refreshing earnings data');
    try {
      emit(const EarningsLoading());
      final data = await _earningsService.getEarnings(period: _currentPeriod);
      _logger.i('✅ EarningsBloc: Successfully refreshed earnings data');
      emit(EarningsLoaded(data));
    } catch (e) {
      _logger.e('❌ EarningsBloc: Error refreshing earnings: $e');
      emit(EarningsError(e.toString()));
    }
  }

  Future<void> _onPeriodChanged(
    EarningsPeriodChangedEvent event,
    Emitter<EarningsState> emit,
  ) async {
    _logger.i('🔄 EarningsBloc: Changing period to: ${event.period}');
    try {
      emit(const EarningsLoading());
      _currentPeriod = event.period;
      final data = await _earningsService.getEarnings(period: _currentPeriod);
      _logger.i('✅ EarningsBloc: Successfully loaded earnings for new period');
      emit(EarningsLoaded(data));
    } catch (e) {
      _logger.e('❌ EarningsBloc: Error changing period: $e');
      emit(EarningsError(e.toString()));
    }
  }
} 