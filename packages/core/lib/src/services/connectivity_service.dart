import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'logger_service.dart';

/// A service for monitoring connectivity status
class ConnectivityService {
  /// The connectivity plugin
  final Connectivity _connectivity = Connectivity();
  
  /// Stream controller for connectivity status
  final StreamController<bool> _connectionStatusController = 
      StreamController<bool>.broadcast();
  
  /// Stream of connectivity status (true = connected, false = disconnected)
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  
  /// The current connectivity status
  bool _isConnected = true;
  
  /// Whether the device is currently connected
  bool get isConnected => _isConnected;
  
  /// Initialize the service and start listening for connectivity changes
  Future<void> initialize() async {
    try {
      // Get initial connection status
      ConnectivityResult result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      
      // Listen for changes
      _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
      
      logger.i('ConnectivityService initialized');
    } catch (e) {
      logger.e('Error initializing ConnectivityService', e);
      _isConnected = true; // Assume connected if we can't determine
      _connectionStatusController.add(_isConnected);
    }
  }
  
  /// Update connection status based on connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    logger.d('Connectivity changed: $result');
    
    bool isConnected = result != ConnectivityResult.none;
    
    // Only emit event if status changed
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectionStatusController.add(_isConnected);
      
      logger.i('Connection status updated: ${_isConnected ? 'Connected' : 'Disconnected'}');
    }
  }
  
  /// Dispose of resources
  void dispose() {
    _connectionStatusController.close();
    logger.d('ConnectivityService disposed');
  }
}