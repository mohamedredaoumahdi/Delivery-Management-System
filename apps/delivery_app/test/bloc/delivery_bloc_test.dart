import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:delivery_app/features/delivery/presentation/bloc/delivery_bloc.dart';
import 'package:delivery_app/features/delivery/data/delivery_service.dart';

class MockDeliveryService extends Mock implements DeliveryService {}

void main() {
  late MockDeliveryService mockDeliveryService;
  late DeliveryBloc deliveryBloc;

  setUp(() {
    mockDeliveryService = MockDeliveryService();
    deliveryBloc = DeliveryBloc(mockDeliveryService);
  });

  tearDown(() {
    deliveryBloc.close();
  });

  group('DeliveryBloc', () {
    test('initial state is DeliveryInitial', () {
      expect(deliveryBloc.state, equals(const DeliveryInitial()));
    });

    blocTest<DeliveryBloc, DeliveryState>(
      'emits [DeliveryLoading, DeliveryLoaded] when available deliveries load successfully',
      build: () {
        when(() => mockDeliveryService.getAvailableOrders())
            .thenAnswer((_) async => []);
        return deliveryBloc;
      },
      act: (bloc) => bloc.add(const DeliveryLoadAvailableEvent()),
      expect: () => [
        const DeliveryLoading(),
        isA<DeliveryLoaded>(),
      ],
    );

    blocTest<DeliveryBloc, DeliveryState>(
      'accepts delivery successfully',
      build: () {
        when(() => mockDeliveryService.acceptOrder('1'))
            .thenAnswer((_) async => {
                  'success': true,
                  'order': {'id': '1', 'status': 'IN_DELIVERY'}
                });
        return deliveryBloc;
      },
      act: (bloc) => bloc.add(const DeliveryAcceptEvent('1')),
      expect: () => [
        const DeliveryLoading(),
        isA<DeliveryAccepted>(),
      ],
      verify: (_) {
        verify(() => mockDeliveryService.acceptOrder('1')).called(1);
      },
    );

    blocTest<DeliveryBloc, DeliveryState>(
      'marks delivery as delivered successfully',
      build: () {
        when(() => mockDeliveryService.markDelivered('1'))
            .thenAnswer((_) async => {});
        when(() => mockDeliveryService.getOrderDetails('1'))
            .thenAnswer((_) async => {
                  'id': '1',
                  'status': 'DELIVERED',
                  'orderNumber': 'ORD-001',
                  'user': {'name': 'Test Customer'},
                  'shopName': 'Test Shop',
                  'deliveryAddress': '123 Test St',
                  'total': 25.99,
                  'items': [],
                });
        return deliveryBloc;
      },
      act: (bloc) => bloc.add(const DeliveryMarkDeliveredEvent('1')),
      expect: () => [
        const DeliveryLoading(),
        isA<DeliveryMarkedAsDelivered>(),
        // After marking delivered, it reloads details (DeliveryLoadDetailsEvent)
        isA<DeliveryLoading>(),
        isA<DeliveryDetailsLoaded>(),
      ],
      verify: (_) {
        verify(() => mockDeliveryService.markDelivered('1')).called(1);
        verify(() => mockDeliveryService.getOrderDetails('1')).called(1);
      },
    );
  });
}
