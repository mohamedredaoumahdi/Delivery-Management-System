import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:user_app/features/order/presentation/bloc/order_bloc.dart';
import 'package:domain/domain.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late MockOrderRepository mockOrderRepository;
  late OrderBloc orderBloc;

  setUp(() {
    mockOrderRepository = MockOrderRepository();
    orderBloc = OrderBloc(orderRepository: mockOrderRepository);
  });

  tearDown(() {
    orderBloc.close();
  });

  group('OrderBloc', () {
    test('initial state is OrderInitial', () {
      expect(orderBloc.state, equals(const OrderInitial()));
    });

    blocTest<OrderBloc, OrderState>(
      'emits [OrderLoadingList, OrderListLoaded] when orders load successfully',
      build: () {
        when(() => mockOrderRepository.getUserOrders(
          status: any(named: 'status'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => const dartz.Right([]));
        return orderBloc;
      },
      act: (bloc) => bloc.add(const OrderLoadListEvent(active: true)),
      expect: () => [
        isA<OrderLoadingList>(),
        isA<OrderListLoaded>(),
      ],
    );

    blocTest<OrderBloc, OrderState>(
      'emits [OrderLoadingList, OrderError] when orders load fails',
      build: () {
        when(() => mockOrderRepository.getUserOrders(
          status: any(named: 'status'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => const dartz.Left(ServerFailure('Network error')));
        return orderBloc;
      },
      act: (bloc) => bloc.add(const OrderLoadListEvent(active: true)),
      expect: () => [
        isA<OrderLoadingList>(),
        isA<OrderError>(),
      ],
    );

    blocTest<OrderBloc, OrderState>(
      'loads order details successfully',
      build: () {
        final mockOrder = Order(
          id: '1',
          userId: '1',
          shopId: '1',
          shopName: 'Test Shop',
          items: const [],
          subtotal: 25.0,
          deliveryFee: 5.0,
          serviceFee: 2.0,
          tax: 3.0,
          tip: 0.0,
          discount: 0.0,
          total: 35.0,
          paymentMethod: PaymentMethod.cashOnDelivery,
          status: OrderStatus.pending,
          deliveryAddress: '123 Test St',
          deliveryLatitude: 0.0,
          deliveryLongitude: 0.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        when(() => mockOrderRepository.getOrderById('1'))
            .thenAnswer((_) async => dartz.Right(mockOrder));
        return orderBloc;
      },
      act: (bloc) => bloc.add(const OrderLoadDetailsEvent('1')),
      expect: () => [
        isA<OrderLoadingDetails>(),
        isA<OrderDetailsLoaded>(),
      ],
    );
  });
}

