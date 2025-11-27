import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vendor_app/features/menu/presentation/bloc/menu_bloc.dart';
import 'package:vendor_app/di/injection_container.dart';

class MockMenuService extends Mock implements MenuService {}

void main() {
  late MockMenuService mockMenuService;
  late MenuBloc menuBloc;

  setUp(() {
    mockMenuService = MockMenuService();
    menuBloc = MenuBloc(menuService: mockMenuService);
  });

  tearDown(() {
    menuBloc.close();
  });

  group('Vendor MenuBloc', () {
    test('initial state is MenuInitial', () {
      expect(menuBloc.state, isA<MenuInitial>());
    });

    blocTest<MenuBloc, MenuState>(
      'emits [MenuLoading, MenuLoaded] when menu items load successfully',
      build: () {
        when(() => mockMenuService.getMenuItems())
            .thenAnswer((_) async => [
                  {
                    'id': '1',
                    'name': 'Test Item',
                    'price': 10.0,
                    'description': 'Test Description',
                  }
                ]);
        return menuBloc;
      },
      act: (bloc) => bloc.add(LoadMenuItems()),
      expect: () => [
        isA<MenuLoading>(),
        isA<MenuLoaded>(),
      ],
    );

    blocTest<MenuBloc, MenuState>(
      'emits [MenuLoading, MenuError] when menu items load fails',
      build: () {
        when(() => mockMenuService.getMenuItems())
            .thenThrow(Exception('Network error'));
        return menuBloc;
      },
      act: (bloc) => bloc.add(LoadMenuItems()),
      expect: () => [
        isA<MenuLoading>(),
        isA<MenuError>(),
      ],
    );

    blocTest<MenuBloc, MenuState>(
      'creates menu item successfully',
      build: () {
        when(() => mockMenuService.createMenuItem(any()))
            .thenAnswer((_) async => {
                  'id': '1',
                  'name': 'New Item',
                  'price': 15.0,
                });
        when(() => mockMenuService.getMenuItems())
            .thenAnswer((_) async => [
                  {
                    'id': '1',
                    'name': 'New Item',
                    'price': 15.0,
                  }
                ]);
        return menuBloc;
      },
      seed: () => const MenuLoaded(menuItems: []),
      act: (bloc) => bloc.add(const CreateMenuItem({
        'name': 'New Item',
        'price': 15.0,
        'description': 'New Description',
      })),
      verify: (_) {
        verify(() => mockMenuService.createMenuItem(any())).called(1);
      },
    );

    blocTest<MenuBloc, MenuState>(
      'deletes menu item successfully',
      build: () {
        when(() => mockMenuService.deleteMenuItem('1'))
            .thenAnswer((_) async => {});
        when(() => mockMenuService.getMenuItems())
            .thenAnswer((_) async => []);
        return menuBloc;
      },
      seed: () => const MenuLoaded(menuItems: [
        {
          'id': '1',
          'name': 'Test Item',
          'price': 10.0,
        }
      ]),
      act: (bloc) => bloc.add(const DeleteMenuItem('1')),
      verify: (_) {
        verify(() => mockMenuService.deleteMenuItem('1')).called(1);
      },
    );
  });
}

