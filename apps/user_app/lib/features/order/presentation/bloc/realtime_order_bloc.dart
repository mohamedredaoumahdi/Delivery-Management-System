import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:core/core.dart';
import 'package:domain/domain.dart';

import '../../../../core/realtime/socket_service.dart';
import '../../../../core/notifications/push_notification_service.dart';

// Events
abstract class RealtimeOrderEvent extends Equatable {
  const RealtimeOrderEvent();

  @override
  List<Object?> get props => [];
}

class RealtimeOrderConnect extends RealtimeOrderEvent {
  final String userId;
  final String? authToken;

  const RealtimeOrderConnect({
    required this.userId,
    this.authToken,
  });

  @override
  List<Object?> get props => [userId, authToken];
}

class RealtimeOrderSubscribe extends RealtimeOrderEvent {
  final String orderId;

  const RealtimeOrderSubscribe(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class RealtimeOrderUnsubscribe extends RealtimeOrderEvent {
  final String orderId;

  const RealtimeOrderUnsubscribe(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class RealtimeOrderDisconnect extends RealtimeOrderEvent {}

// States
abstract class RealtimeOrderState extends Equatable {
  const RealtimeOrderState();

  @override
  List<Object?> get props => [];
}

class RealtimeOrderInitial extends RealtimeOrderState {}

class RealtimeOrderConnecting extends RealtimeOrderState {}

class RealtimeOrderConnected extends RealtimeOrderState {}

class RealtimeOrderDisconnected extends RealtimeOrderState {}

class RealtimeOrderError extends RealtimeOrderState {
  final String message;

  const RealtimeOrderError(this.message);

  @override
  List<Object?> get props => [message];
}

class RealtimeOrderUpdate extends RealtimeOrderState {
  final Order order;
  final String updateType; // 'status', 'delivery', 'general'

  const RealtimeOrderUpdate({
    required this.order,
    required this.updateType,
  });

  @override
  List<Object?> get props => [order, updateType];
}

// BLoC
class RealtimeOrderBloc extends Bloc<RealtimeOrderEvent, RealtimeOrderState> {
  final SocketService _socketService;
  final PushNotificationService _pushNotificationService;
  final LoggerService _logger;
  
  StreamSubscription? _orderUpdateSubscription;
  StreamSubscription? _orderStatusSubscription;
  StreamSubscription? _deliveryUpdateSubscription;
  StreamSubscription? _connectionStatusSubscription;
  StreamSubscription? _notificationSubscription;

  RealtimeOrderBloc({
    required SocketService socketService,
    required PushNotificationService pushNotificationService,
    required LoggerService logger,
  })  : _socketService = socketService,
        _pushNotificationService = pushNotificationService,
        _logger = logger,
        super(RealtimeOrderInitial()) {
    
    on<RealtimeOrderConnect>(_onConnect);
    on<RealtimeOrderSubscribe>(_onSubscribe);
    on<RealtimeOrderUnsubscribe>(_onUnsubscribe);
    on<RealtimeOrderDisconnect>(_onDisconnect);
  }

  Future<void> _onConnect(
    RealtimeOrderConnect event,
    Emitter<RealtimeOrderState> emit,
  ) async {
    emit(RealtimeOrderConnecting());
    
    try {
      // Connect to socket service
      await _socketService.connect();
      
      // Subscribe to user updates
      _socketService.subscribeToUser(event.userId);
      
      // Listen to order updates
      _orderUpdateSubscription = _socketService.orderUpdates.listen((data) {
        _handleOrderUpdate(data);
      });
      
      // Listen to order status updates
      _orderStatusSubscription = _socketService.orderStatusUpdates.listen((data) {
        _handleOrderStatusUpdate(data);
      });
      
      // Listen to delivery updates
      _deliveryUpdateSubscription = _socketService.deliveryUpdates.listen((data) {
        _handleDeliveryUpdate(data);
      });
      
      // Listen to connection status
      _connectionStatusSubscription = _socketService.connectionStatus.listen((status) {
        _handleConnectionStatus(status);
      });
      
      // Listen to push notifications
      _notificationSubscription = _pushNotificationService.onMessageReceived.listen((message) {
        _handlePushNotification(message);
      });
      
      emit(RealtimeOrderConnected());
      _logger.i('Realtime order tracking connected');
    } catch (e) {
      _logger.e('Error connecting to realtime order tracking', e);
      emit(RealtimeOrderError(e.toString()));
    }
  }

  Future<void> _onSubscribe(
    RealtimeOrderSubscribe event,
    Emitter<RealtimeOrderState> emit,
  ) async {
    try {
      _socketService.subscribeToOrder(event.orderId);
      _logger.i('Subscribed to order updates: ${event.orderId}');
    } catch (e) {
      _logger.e('Error subscribing to order: ${event.orderId}', e);
    }
  }

  Future<void> _onUnsubscribe(
    RealtimeOrderUnsubscribe event,
    Emitter<RealtimeOrderState> emit,
  ) async {
    try {
      _socketService.unsubscribeFromOrder(event.orderId);
      _logger.i('Unsubscribed from order updates: ${event.orderId}');
    } catch (e) {
      _logger.e('Error unsubscribing from order: ${event.orderId}', e);
    }
  }

  Future<void> _onDisconnect(
    RealtimeOrderDisconnect event,
    Emitter<RealtimeOrderState> emit,
  ) async {
    try {
      // Cancel all subscriptions
      await _orderUpdateSubscription?.cancel();
      await _orderStatusSubscription?.cancel();
      await _deliveryUpdateSubscription?.cancel();
      await _connectionStatusSubscription?.cancel();
      await _notificationSubscription?.cancel();
      
      // Disconnect socket service
      _socketService.disconnect();
      
      emit(RealtimeOrderDisconnected());
      _logger.i('Realtime order tracking disconnected');
    } catch (e) {
      _logger.e('Error disconnecting from realtime order tracking', e);
    }
  }

  void _handleOrderUpdate(Map<String, dynamic> data) {
    try {
      // Parse order data and emit update
      // This would typically involve converting the data to an Order object
      _logger.i('Received order update: $data');
      
      // For now, we'll emit a general update
      // In a real implementation, you'd parse the data and create an Order object
      // emit(RealtimeOrderUpdate(order: order, updateType: 'general'));
    } catch (e) {
      _logger.e('Error handling order update', e);
    }
  }

  void _handleOrderStatusUpdate(Map<String, dynamic> data) {
    try {
      _logger.i('Received order status update: $data');
      
      // Parse status update and emit
      // emit(RealtimeOrderUpdate(order: order, updateType: 'status'));
    } catch (e) {
      _logger.e('Error handling order status update', e);
    }
  }

  void _handleDeliveryUpdate(Map<String, dynamic> data) {
    try {
      _logger.i('Received delivery update: $data');
      
      // Parse delivery update and emit
      // emit(RealtimeOrderUpdate(order: order, updateType: 'delivery'));
    } catch (e) {
      _logger.e('Error handling delivery update', e);
    }
  }

  void _handleConnectionStatus(String status) {
    _logger.i('Connection status changed: $status');
    
    switch (status) {
      case 'connected':
        // Handle connected state
        break;
      case 'disconnected':
        // Handle disconnected state
        break;
      case 'error':
        // Handle error state
        break;
    }
  }

  void _handlePushNotification(dynamic message) {
    try {
      _logger.i('Received push notification: $message');
      
      // Handle push notification
      // This could trigger a UI update or navigation
    } catch (e) {
      _logger.e('Error handling push notification', e);
    }
  }

  @override
  Future<void> close() {
    _orderUpdateSubscription?.cancel();
    _orderStatusSubscription?.cancel();
    _deliveryUpdateSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    _notificationSubscription?.cancel();
    _socketService.dispose();
    return super.close();
  }
}
