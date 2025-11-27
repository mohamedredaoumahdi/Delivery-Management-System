import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vendor_app/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:vendor_app/di/injection_container.dart';

class MockVendorService extends Mock implements VendorService {}

void main() {
  late MockVendorService mockVendorService;
  late DashboardBloc dashboardBloc;

  setUp(() {
    mockVendorService = MockVendorService();
    dashboardBloc = DashboardBloc(vendorService: mockVendorService);
  });

  tearDown(() {
    dashboardBloc.close();
  });

  group('Vendor DashboardBloc', () {
    test('initial state is DashboardInitial', () {
      expect(dashboardBloc.state, isA<DashboardInitial>());
    });

    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoading, DashboardLoaded] when dashboard loads successfully',
      build: () {
        when(() => mockVendorService.getDashboardData())
            .thenAnswer((_) async => {
                  'shop': {
                    'id': '1',
                    'name': 'Test Restaurant',
                  },
                  'stats': {
                    'totalOrders': 10,
                    'totalRevenue': 250.0,
                  }
                });
        return dashboardBloc;
      },
      act: (bloc) => bloc.add(LoadDashboard()),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardLoaded>(),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoading, DashboardError] when dashboard load fails',
      build: () {
        when(() => mockVendorService.getDashboardData())
            .thenThrow(Exception('Network error'));
        return dashboardBloc;
      },
      act: (bloc) => bloc.add(LoadDashboard()),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardError>(),
      ],
    );
  });
}

