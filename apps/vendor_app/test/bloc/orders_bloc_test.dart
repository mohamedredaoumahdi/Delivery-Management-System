import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vendor_app/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:vendor_app/di/injection_container.dart';

class MockOrderService extends Mock implements OrderService {}

void main() {
  late MockOrderService mockOrderService;
  late OrdersBloc ordersBloc;

  setUp(() {
    mockOrderService = MockOrderService();
    ordersBloc = OrdersBloc(orderService: mockOrderService);
  });

  tearDown(() {
    ordersBloc.close();
  });

  group('Vendor OrdersBloc', () {
    test('initial state is OrdersInitial', () {
      expect(ordersBloc.state, isA<OrdersInitial>());
    });

    blocTest<OrdersBloc, OrdersState>(
      'emits [OrdersLoading, OrdersLoaded] when orders load successfully',
      build: () {
        when(() => mockOrderService.getOrders())
            .thenAnswer((_) async => [
                  {
                    'id': '1',
                    'orderNumber': 'ORD-001',
                    'status': 'PENDING',
                    'total': 25.99,
                  }
                ]);
        return ordersBloc;
      },
      act: (bloc) => bloc.add(LoadOrders()),
      expect: () => [
        isA<OrdersLoading>(),
        isA<OrdersLoaded>(),
      ],
    );

    blocTest<OrdersBloc, OrdersState>(
      'emits [OrdersLoading, OrdersError] when orders load fails',
      build: () {
        when(() => mockOrderService.getOrders())
            .thenThrow(Exception('Network error'));
        return ordersBloc;
      },
      act: (bloc) => bloc.add(LoadOrders()),
      expect: () => [
        isA<OrdersLoading>(),
        isA<OrdersError>(),
      ],
    );

    blocTest<OrdersBloc, OrdersState>(
      'loads empty orders list successfully',
      build: () {
        when(() => mockOrderService.getOrders())
            .thenAnswer((_) async => []);
        return ordersBloc;
      },
      act: (bloc) => bloc.add(LoadOrders()),
      expect: () => [
        isA<OrdersLoading>(),
        isA<OrdersLoaded>(),
      ],
      verify: (bloc) {
        expect((bloc.state as OrdersLoaded).orders, isEmpty);
      },
    );
  });
}
