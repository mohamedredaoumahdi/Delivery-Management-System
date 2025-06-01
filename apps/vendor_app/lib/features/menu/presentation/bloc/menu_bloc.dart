import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../di/injection_container.dart';

// Events
abstract class MenuEvent extends Equatable {
  const MenuEvent();

  @override
  List<Object?> get props => [];
}

class LoadMenuItems extends MenuEvent {}

// States
abstract class MenuState extends Equatable {
  const MenuState();

  @override
  List<Object?> get props => [];
}

class MenuInitial extends MenuState {}

class MenuLoading extends MenuState {}

class MenuLoaded extends MenuState {
  final List<Map<String, dynamic>> menuItems;

  const MenuLoaded({required this.menuItems});

  @override
  List<Object?> get props => [menuItems];
}

class MenuError extends MenuState {
  final String message;

  const MenuError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Bloc
class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final MockMenuService menuService;

  MenuBloc({
    required this.menuService,
  }) : super(MenuInitial()) {
    on<LoadMenuItems>(_onLoadMenuItems);
  }

  Future<void> _onLoadMenuItems(
    LoadMenuItems event,
    Emitter<MenuState> emit,
  ) async {
    emit(MenuLoading());
    
    try {
      final items = await menuService.getMenuItems();
      emit(MenuLoaded(menuItems: items));
    } catch (e) {
      emit(MenuError(message: e.toString()));
    }
  }
}