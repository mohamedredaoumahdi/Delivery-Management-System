import 'package:logger/logger.dart';

/// A logging service for the application
class LoggerService {
  late final Logger _logger;
  
  /// Whether verbose logging is enabled
  final bool verbose;
  
  /// Creates a new logger service
  LoggerService({this.verbose = false}) {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      level: verbose ? Level.verbose : Level.info,
    );
  }
  
  /// Log a verbose message
  void v(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.v(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log a debug message
  void d(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log an info message
  void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log a warning message
  void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log an error message
  void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log a critical error message
  void wtf(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}

/// Global logger instance for easy access
final logger = LoggerService(
  verbose: const bool.fromEnvironment('VERBOSE_LOGGING', defaultValue: false),
);