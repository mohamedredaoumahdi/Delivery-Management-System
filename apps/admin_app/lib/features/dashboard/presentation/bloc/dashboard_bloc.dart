import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/dashboard_service.dart';
import '../../data/models/dashboard_overview_model.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardService dashboardService;

  DashboardBloc({required this.dashboardService}) : super(const DashboardInitial()) {
    on<LoadDashboardStatistics>(_onLoadDashboardStatistics);
    on<RefreshDashboardStatistics>(_onRefreshDashboardStatistics);
  }

  Future<void> _onLoadDashboardStatistics(
    LoadDashboardStatistics event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    await _loadAndEmitOverview(emit);
  }

  Future<void> _onRefreshDashboardStatistics(
    RefreshDashboardStatistics event,
    Emitter<DashboardState> emit,
  ) async {
    await _loadAndEmitOverview(emit);
  }

  Future<void> _loadAndEmitOverview(Emitter<DashboardState> emit) async {
    try {
      final DashboardOverview overview = await dashboardService.getStatistics();
      emit(DashboardLoaded(
        overview: overview,
        fetchedAt: DateTime.now(),
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
