import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../di/injection_container.dart';
import '../../../analytics/presentation/bloc/analytics_bloc.dart';

// Events
abstract class MenuEvent extends Equatable {
  const MenuEvent();

  @override
  List<Object?> get props => [];
}

class LoadMenuItems extends MenuEvent {}

class CreateMenuItem extends MenuEvent {
  final Map<String, dynamic> data;

  const CreateMenuItem(this.data);

  @override
  List<Object?> get props => [data];
}

class UpdateMenuItem extends MenuEvent {
  final String id;
  final Map<String, dynamic> data;

  const UpdateMenuItem(this.id, this.data);

  @override
  List<Object?> get props => [id, data];
}

class DeleteMenuItem extends MenuEvent {
  final String id;

  const DeleteMenuItem(this.id);

  @override
  List<Object?> get props => [id];
}

class ToggleMenuItemAvailability extends MenuEvent {
  final String id;
  final bool isAvailable;

  const ToggleMenuItemAvailability(this.id, this.isAvailable);

  @override
  List<Object?> get props => [id, isAvailable];
}

// States
abstract class MenuState extends Equatable {
  const MenuState();

  @override
  List<Object?> get props => [];
}

class MenuInitial extends MenuState {}

class MenuLoading extends MenuState {}

class MenuOperationLoading extends MenuState {
  final String operation; // 'creating', 'updating', 'deleting'
  final List<Map<String, dynamic>> currentItems;
  
  const MenuOperationLoading(this.operation, this.currentItems);
  
  @override
  List<Object?> get props => [operation, currentItems];
}

class MenuLoaded extends MenuState {
  final List<Map<String, dynamic>> menuItems;

  const MenuLoaded({required this.menuItems});

  @override
  List<Object?> get props => [menuItems];
}

class MenuOperationSuccess extends MenuState {
  final String message;
  final List<Map<String, dynamic>> menuItems;

  const MenuOperationSuccess(this.message, this.menuItems);

  @override
  List<Object?> get props => [message, menuItems];
}

class MenuError extends MenuState {
  final String message;

  const MenuError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Bloc
class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final MenuService menuService;

  MenuBloc({
    required this.menuService,
  }) : super(MenuInitial()) {
    on<LoadMenuItems>(_onLoadMenuItems);
    on<CreateMenuItem>(_onCreateMenuItem);
    on<UpdateMenuItem>(_onUpdateMenuItem);
    on<DeleteMenuItem>(_onDeleteMenuItem);
    on<ToggleMenuItemAvailability>(_onToggleMenuItemAvailability);
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

  Future<void> _onCreateMenuItem(
    CreateMenuItem event,
    Emitter<MenuState> emit,
  ) async {
    // Get current items to show during loading
    final currentItems = state is MenuLoaded ? (state as MenuLoaded).menuItems : <Map<String, dynamic>>[];
    
    emit(MenuOperationLoading('creating', currentItems));
    
    try {
      await menuService.createMenuItem(event.data);
      
      // Reload menu items to show the new item
      final items = await menuService.getMenuItems();
      emit(MenuOperationSuccess('Menu item created successfully!', items));
      
      // Trigger analytics update for menu stats
      _updateAnalyticsMenu();
      
      // Auto-transition to normal loaded state after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      if (!emit.isDone) {
        emit(MenuLoaded(menuItems: items));
      }
    } catch (e) {
      emit(MenuError(message: e.toString()));
    }
  }

  Future<void> _onUpdateMenuItem(
    UpdateMenuItem event,
    Emitter<MenuState> emit,
  ) async {
    final currentItems = state is MenuLoaded ? (state as MenuLoaded).menuItems : <Map<String, dynamic>>[];
    
    emit(MenuOperationLoading('updating', currentItems));
    
    try {
      await menuService.updateMenuItem(event.id, event.data);
      
      // Reload menu items to show the updated item
      final items = await menuService.getMenuItems();
      emit(MenuOperationSuccess('Menu item updated successfully!', items));
      
      // Trigger analytics update for menu stats
      _updateAnalyticsMenu();
      
      // Auto-transition to normal loaded state after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      if (!emit.isDone) {
        emit(MenuLoaded(menuItems: items));
      }
    } catch (e) {
      emit(MenuError(message: e.toString()));
    }
  }

  Future<void> _onDeleteMenuItem(
    DeleteMenuItem event,
    Emitter<MenuState> emit,
  ) async {
    final currentItems = state is MenuLoaded ? (state as MenuLoaded).menuItems : <Map<String, dynamic>>[];
    
    emit(MenuOperationLoading('deleting', currentItems));
    
    try {
      await menuService.deleteMenuItem(event.id);
      
      // Reload menu items to remove the deleted item
      final items = await menuService.getMenuItems();
      emit(MenuOperationSuccess('Menu item deleted successfully!', items));
      
      // Trigger analytics update for menu stats
      _updateAnalyticsMenu();
      
      // Auto-transition to normal loaded state after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      if (!emit.isDone) {
        emit(MenuLoaded(menuItems: items));
      }
    } catch (e) {
      emit(MenuError(message: e.toString()));
    }
  }

  Future<void> _onToggleMenuItemAvailability(
    ToggleMenuItemAvailability event,
    Emitter<MenuState> emit,
  ) async {
    final currentItems = state is MenuLoaded ? (state as MenuLoaded).menuItems : <Map<String, dynamic>>[];
    
    emit(MenuOperationLoading('updating availability', currentItems));
    
    try {
      // Make the API call to update availability
      await menuService.toggleAvailability(event.id, event.isAvailable);
      
      // Force reload menu items to get the updated data from backend
      final items = await menuService.getMenuItems();
      
      // Verify the update was successful by checking the specific item
      final updatedItem = items.firstWhere(
        (item) => item['id'] == event.id,
        orElse: () => <String, dynamic>{},
      );
      
      String statusMessage;
      if (updatedItem.isNotEmpty) {
        // Verify the update was successful
        final actualAvailability = _getItemAvailability(updatedItem);
        if (actualAvailability == event.isAvailable) {
          statusMessage = 'Item marked as ${event.isAvailable ? 'available' : 'unavailable'}!';
        } else {
          statusMessage = 'Availability update completed!';
        }
      } else {
        statusMessage = 'Item updated!';
      }
      
      emit(MenuOperationSuccess(statusMessage, items));
      
      // Trigger analytics update for menu stats
      _updateAnalyticsMenu();
      
      // Auto-transition to normal loaded state after 1 second for quick actions
      await Future.delayed(const Duration(seconds: 1));
      if (!emit.isDone) {
        emit(MenuLoaded(menuItems: items));
      }
    } catch (e) {
      emit(MenuError(message: e.toString()));
    }
  }
  
  // Helper method to determine item availability from various possible field names
  bool _getItemAvailability(Map<String, dynamic> menuItem) {
    // Check in order of preference: isActive, inStock, isAvailable
    if (menuItem['isActive'] != null) {
      return menuItem['isActive'] as bool;
    }
    if (menuItem['inStock'] != null) {
      return menuItem['inStock'] as bool;
    }
    if (menuItem['isAvailable'] != null) {
      return menuItem['isAvailable'] as bool;
    }
    
    // Default to true if no field is found
    return true;
  }
  
  void _updateAnalyticsMenu() {
    try {
      // Get the analytics bloc if it exists and trigger menu metric update
      final analyticsBloc = sl<AnalyticsBloc>();
      analyticsBloc.add(RefreshMetric('menu'));
    } catch (e) {
      // Analytics bloc might not be available, ignore
      print('Analytics update skipped: $e');
    }
  }
}