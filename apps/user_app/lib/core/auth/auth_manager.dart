import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

/// Global authentication manager to handle token expiration and automatic logout
class AuthManager {
  // Stream controller for authentication errors
  final StreamController<void> _authErrorController = StreamController<void>.broadcast();
  
  /// Stream of authentication errors
  Stream<void> get authErrorStream => _authErrorController.stream;
  
  /// Global navigator key to access navigation context
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  /// Handle authentication error (token expiration, unauthorized access, etc.)
  void handleAuthError() {
    print('🔐 AuthManager: Handling authentication error');
    _authErrorController.add(null);
    
    // Try to navigate to login if we have a valid context
    final context = navigatorKey.currentContext;
    if (context != null) {
      print('🔐 AuthManager: Navigating to login page');
      context.go('/login');
    } else {
      print('⚠️ AuthManager: No navigation context available');
    }
  }
  
  /// Dispose resources
  void dispose() {
    _authErrorController.close();
  }
} 