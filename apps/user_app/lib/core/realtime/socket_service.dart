import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:core/core.dart';

class SocketService {
  final LoggerService _logger;
  IO.Socket? _socket;
  final String _baseUrl;
  final String? _authToken;
  
  // Stream controllers for different events
  final StreamController<Map<String, dynamic>> _orderUpdateController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _orderStatusController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _deliveryUpdateController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _connectionStatusController = 
      StreamController<String>.broadcast();

  SocketService({
    required LoggerService logger,
    required String baseUrl,
    String? authToken,
  })  : _logger = logger,
        _baseUrl = baseUrl,
        _authToken = authToken;

  // Streams for different events
  Stream<Map<String, dynamic>> get orderUpdates => _orderUpdateController.stream;
  Stream<Map<String, dynamic>> get orderStatusUpdates => _orderStatusController.stream;
  Stream<Map<String, dynamic>> get deliveryUpdates => _deliveryUpdateController.stream;
  Stream<String> get connectionStatus => _connectionStatusController.stream;

  /// Initialize and connect to socket server
  Future<void> connect() async {
    try {
      _logger.i('Connecting to socket server: $_baseUrl');
      
      _socket = IO.io(_baseUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {
          'token': _authToken,
        },
      });

      _setupEventListeners();
      
      _socket!.connect();
      _logger.i('Socket connection initiated');
    } catch (e) {
      _logger.e('Error connecting to socket server', e);
      _connectionStatusController.add('error');
    }
  }

  /// Setup event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      _logger.i('Socket connected');
      _connectionStatusController.add('connected');
    });

    _socket!.onDisconnect((_) {
      _logger.i('Socket disconnected');
      _connectionStatusController.add('disconnected');
    });

    _socket!.onConnectError((error) {
      _logger.e('Socket connection error: $error');
      _connectionStatusController.add('error');
    });

    // Order events
    _socket!.on('order:update', (data) {
      _logger.i('Received order update: $data');
      _orderUpdateController.add(data);
    });

    _socket!.on('order:status', (data) {
      _logger.i('Received order status update: $data');
      _orderStatusController.add(data);
    });

    _socket!.on('delivery:update', (data) {
      _logger.i('Received delivery update: $data');
      _deliveryUpdateController.add(data);
    });

    // General events
    _socket!.on('notification', (data) {
      _logger.i('Received notification: $data');
      // Handle general notifications
    });
  }

  /// Subscribe to order updates
  void subscribeToOrder(String orderId) {
    if (_socket?.connected == true) {
      _logger.i('Subscribing to order updates: $orderId');
      _socket!.emit('subscribe:order', {'orderId': orderId});
    } else {
      _logger.w('Socket not connected, cannot subscribe to order');
    }
  }

  /// Subscribe to user updates
  void subscribeToUser(String userId) {
    if (_socket?.connected == true) {
      _logger.i('Subscribing to user updates: $userId');
      _socket!.emit('subscribe:user', {'userId': userId});
    } else {
      _logger.w('Socket not connected, cannot subscribe to user');
    }
  }

  /// Unsubscribe from order updates
  void unsubscribeFromOrder(String orderId) {
    if (_socket?.connected == true) {
      _logger.i('Unsubscribing from order updates: $orderId');
      _socket!.emit('unsubscribe:order', {'orderId': orderId});
    }
  }

  /// Unsubscribe from user updates
  void unsubscribeFromUser(String userId) {
    if (_socket?.connected == true) {
      _logger.i('Unsubscribing from user updates: $userId');
      _socket!.emit('unsubscribe:user', {'userId': userId});
    }
  }

  /// Send a message to the server
  void emit(String event, dynamic data) {
    if (_socket?.connected == true) {
      _logger.i('Emitting event: $event with data: $data');
      _socket!.emit(event, data);
    } else {
      _logger.w('Socket not connected, cannot emit event: $event');
    }
  }

  /// Update authentication token
  void updateAuthToken(String? newToken) {
    if (_socket?.connected == true) {
      _socket!.emit('auth:update', {'token': newToken});
    }
  }

  /// Disconnect from socket server
  void disconnect() {
    _logger.i('Disconnecting from socket server');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// Check if socket is connected
  bool get isConnected => _socket?.connected ?? false;

  /// Dispose of resources
  void dispose() {
    disconnect();
    _orderUpdateController.close();
    _orderStatusController.close();
    _deliveryUpdateController.close();
    _connectionStatusController.close();
  }
}
