class AppConfig {
  static const String appName = 'Vendor Dashboard';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String baseUrl = 'http://localhost:8000/api';
  static const String apiVersion = 'v1';
  
  // App Settings
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Image Settings
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
  
  // Order Settings
  static const int orderRefreshInterval = 30; // seconds
  static const int maxOrderProcessingTime = 60; // minutes
} 