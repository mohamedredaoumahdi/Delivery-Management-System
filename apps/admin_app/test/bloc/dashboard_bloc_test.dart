import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:admin_app/features/dashboard/data/dashboard_service.dart';
import 'package:admin_app/features/dashboard/data/models/dashboard_overview_model.dart';
import 'package:admin_app/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:admin_app/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:admin_app/features/dashboard/presentation/bloc/dashboard_state.dart';

class MockDashboardService extends Mock implements DashboardService {}

DashboardOverview _buildOverview({
  int ordersToday = 10,
  int ordersWeek = 40,
  int ordersMonth = 150,
  int activeOrders = 6,
  int pendingDeliveries = 3,
}) {
  final now = DateTime.now();
  return DashboardOverview(
    orders: OrdersSummary(
      totals: OrdersTotals(today: ordersToday, week: ordersWeek, month: ordersMonth),
      active: activeOrders,
      pendingDeliveries: pendingDeliveries,
    ),
    revenue: const RevenueSummary(today: 1200, week: 5600, month: 22000, total: 98500),
    vendors: const VendorInsights(
      total: 20,
      active: 15,
      averageRating: 4.6,
      topPerformers: [
        VendorPerformance(shopId: 'shop-1', shopName: 'Cafe Central', orders: 34, revenue: 3400),
      ],
    ),
    delivery: const DeliveryInsights(
      totalAgents: 18,
      activeAgents: 15,
      onlineAgents: 11,
      offlineAgents: 4,
      completedToday: 48,
      averageDeliveryTimeMinutes: 32,
    ),
    customers: const CustomerInsights(
      totalCustomers: 820,
      growthRate: 12.5,
      trend: [
        CustomerTrendPoint(label: 'Sep', count: 80),
        CustomerTrendPoint(label: 'Oct', count: 90),
        CustomerTrendPoint(label: 'Nov', count: 110),
        CustomerTrendPoint(label: 'Dec', count: 120),
        CustomerTrendPoint(label: 'Jan', count: 160),
        CustomerTrendPoint(label: 'Feb', count: 180),
      ],
    ),
    generatedAt: now,
  );
}

void main() {
  late MockDashboardService mockDashboardService;
  late DashboardBloc dashboardBloc;
  late DashboardOverview updatedOverview;

  setUp(() {
    mockDashboardService = MockDashboardService();
    dashboardBloc = DashboardBloc(dashboardService: mockDashboardService);
  });

  tearDown(() {
    dashboardBloc.close();
  });

  group('DashboardBloc', () {
    test('initial state is DashboardInitial', () {
      expect(dashboardBloc.state, equals(const DashboardInitial()));
    });

    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoading, DashboardLoaded] when statistics load successfully',
      build: () {
        final overview = _buildOverview(ordersToday: 25, activeOrders: 9);
        when(() => mockDashboardService.getStatistics()).thenAnswer((_) async => overview);
        return dashboardBloc;
      },
      act: (bloc) => bloc.add(const LoadDashboardStatistics()),
      expect: () => [
        const DashboardLoading(),
        isA<DashboardLoaded>()
          ..having((s) => s.overview.orders.totals.today, 'ordersToday', 25)
          ..having((s) => s.overview.orders.active, 'activeOrders', 9),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoading, DashboardError] when statistics load fails',
      build: () {
        when(() => mockDashboardService.getStatistics())
            .thenThrow(Exception('Network error'));
        return dashboardBloc;
      },
      act: (bloc) => bloc.add(const LoadDashboardStatistics()),
      expect: () => [
        const DashboardLoading(),
        isA<DashboardError>(),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits DashboardLoaded when statistics are refreshed',
      build: () {
        updatedOverview = _buildOverview(ordersToday: 32, ordersWeek: 70);
        when(() => mockDashboardService.getStatistics()).thenAnswer((_) async => updatedOverview);
        return dashboardBloc;
      },
      seed: () => DashboardLoaded(
        overview: _buildOverview(),
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      act: (bloc) => bloc.add(const RefreshDashboardStatistics()),
      expect: () => [
        isA<DashboardLoaded>()
          ..having((s) => s.overview, 'overview', updatedOverview),
      ],
    );
  });
}

