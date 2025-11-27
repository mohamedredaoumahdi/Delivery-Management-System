import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:user_app/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:user_app/features/cart/domain/cart_repository.dart';
import 'package:domain/domain.dart';

class MockCartRepository extends Mock implements CartRepository {}

void main() {
  late MockCartRepository mockCartRepository;
  late CartBloc cartBloc;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(Product(
      id: 'fallback',
      name: 'Fallback Product',
      description: 'Fallback',
      price: 0.0,
      shopId: 'fallback',
      category: 'Fallback',
      inStock: true,
      isFeatured: false,
      rating: 0.0,
      ratingCount: 0,
      tags: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });

  setUp(() {
    mockCartRepository = MockCartRepository();
    // Mock the streams
    when(() => mockCartRepository.cartItemsStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockCartRepository.cartSummaryStream)
        .thenAnswer((_) => const Stream.empty());
    // Mock getCartItems for auto-load
    when(() => mockCartRepository.getCartItems())
        .thenAnswer((_) async => []);
    when(() => mockCartRepository.isSingleShopCart())
        .thenAnswer((_) async => true);
    cartBloc = CartBloc(cartRepository: mockCartRepository);
  });

  tearDown(() {
    cartBloc.close();
  });

  group('CartBloc', () {
    test('initial state is CartInitial', () {
      // Create a new bloc without auto-loading
      final testBloc = CartBloc(cartRepository: mockCartRepository);
      // Check state immediately before auto-load completes
      expect(testBloc.state, equals(const CartInitial()));
      testBloc.close();
    });

    blocTest<CartBloc, CartState>(
      'emits [CartLoading, CartEmpty] when cart is empty',
      build: () {
        when(() => mockCartRepository.getCartItems())
            .thenAnswer((_) async => []);
        when(() => mockCartRepository.isSingleShopCart())
            .thenAnswer((_) async => true);
        when(() => mockCartRepository.cartItemsStream)
            .thenAnswer((_) => const Stream.empty());
        when(() => mockCartRepository.cartSummaryStream)
            .thenAnswer((_) => const Stream.empty());
        return CartBloc(cartRepository: mockCartRepository);
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [
        const CartLoading(),
        const CartEmpty(),
      ],
    );

    blocTest<CartBloc, CartState>(
      'adds item to cart successfully',
      build: () {
        when(() => mockCartRepository.getCartItems())
            .thenAnswer((_) async => []);
        when(() => mockCartRepository.isSingleShopCart())
            .thenAnswer((_) async => true);
        when(() => mockCartRepository.getCurrentShopId())
            .thenAnswer((_) async => null); // Empty cart
        when(() => mockCartRepository.addToCart(
          product: any(named: 'product'),
          shopId: any(named: 'shopId'),
          shopName: any(named: 'shopName'),
          quantity: any(named: 'quantity'),
          instructions: any(named: 'instructions'),
        )).thenAnswer((_) async => {});
        when(() => mockCartRepository.cartItemsStream)
            .thenAnswer((_) => const Stream.empty());
        when(() => mockCartRepository.cartSummaryStream)
            .thenAnswer((_) => const Stream.empty());
        return CartBloc(cartRepository: mockCartRepository);
      },
      wait: const Duration(milliseconds: 200),
      act: (bloc) async {
        // Wait for initial load to complete
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(CartAddItemEvent(
          product: Product(
            id: '1',
            name: 'Test Product',
            description: 'Test Description',
            price: 10.0,
            shopId: '1',
            category: 'Test',
            inStock: true,
            isFeatured: false,
            rating: 0.0,
            ratingCount: 0,
            tags: const [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          shopId: '1',
          shopName: 'Test Shop',
          quantity: 1,
        ));
      },
      skip: 2, // Skip initial CartLoading and CartEmpty from auto-load
      verify: (_) {
        verify(() => mockCartRepository.addToCart(
          product: any(named: 'product'),
          shopId: '1',
          shopName: 'Test Shop',
          quantity: 1,
          instructions: any(named: 'instructions'),
        )).called(1);
      },
    );

    blocTest<CartBloc, CartState>(
      'removes item from cart successfully',
      build: () {
        // Return items so the cart is loaded (not empty)
        final testProduct = Product(
          id: '1',
          name: 'Test Product',
          description: 'Test',
          price: 10.0,
          shopId: '1',
          category: 'Test',
          inStock: true,
          isFeatured: false,
          rating: 0.0,
          ratingCount: 0,
          tags: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        when(() => mockCartRepository.getCartItems())
            .thenAnswer((_) async => [
                  const CartItem(
                    productId: '1',
                    productName: 'Test Product',
                    productDescription: 'Test Description',
                    productPrice: 10.0,
                    productImageUrl: null,
                    shopId: '1',
                    shopName: 'Test Shop',
                    quantity: 1,
                    instructions: null,
                  )
                ]);
        when(() => mockCartRepository.isSingleShopCart())
            .thenAnswer((_) async => true);
        when(() => mockCartRepository.getCartSummary(
          deliveryFee: any(named: 'deliveryFee'),
          serviceFee: any(named: 'serviceFee'),
          taxRate: any(named: 'taxRate'),
        )).thenAnswer((_) async => const CartSummary(
          subtotal: 10.0,
          deliveryFee: 3.99,
          serviceFee: 1.99,
          tax: 1.28,
          total: 17.26,
          itemCount: 1,
          totalQuantity: 1,
        ));
        when(() => mockCartRepository.removeFromCart('1'))
            .thenAnswer((_) async => {});
        when(() => mockCartRepository.cartItemsStream)
            .thenAnswer((_) => const Stream.empty());
        when(() => mockCartRepository.cartSummaryStream)
            .thenAnswer((_) => const Stream.empty());
        return CartBloc(cartRepository: mockCartRepository);
      },
      wait: const Duration(milliseconds: 400),
      act: (bloc) async {
        // Wait for auto-load to complete and state to be CartLoaded
        await Future.delayed(const Duration(milliseconds: 200));
        bloc.add(const CartRemoveItemEvent(productId: '1'));
      },
      skip: 2, // Skip initial CartLoading and CartLoaded from auto-load
      verify: (_) {
        verify(() => mockCartRepository.removeFromCart('1')).called(1);
      },
    );

    blocTest<CartBloc, CartState>(
      'clears cart successfully',
      build: () {
        when(() => mockCartRepository.getCartItems())
            .thenAnswer((_) async => []);
        when(() => mockCartRepository.isSingleShopCart())
            .thenAnswer((_) async => true);
        when(() => mockCartRepository.clearCart())
            .thenAnswer((_) async => {});
        when(() => mockCartRepository.cartItemsStream)
            .thenAnswer((_) => const Stream.empty());
        when(() => mockCartRepository.cartSummaryStream)
            .thenAnswer((_) => const Stream.empty());
        return CartBloc(cartRepository: mockCartRepository);
      },
      wait: const Duration(milliseconds: 200),
      seed: () => const CartLoaded(
        items: [],
        summary: CartSummary(
          subtotal: 0.0,
          deliveryFee: 0.0,
          serviceFee: 0.0,
          tax: 0.0,
          total: 0.0,
          itemCount: 0,
          totalQuantity: 0,
        ),
      ),
      act: (bloc) => bloc.add(const CartClearEvent()),
      skip: 2, // Skip initial CartLoading and CartEmpty from auto-load
      expect: () => [
        const CartLoading(),
        const CartEmpty(),
      ],
      verify: (_) {
        verify(() => mockCartRepository.clearCart()).called(1);
      },
    );
  });
}

