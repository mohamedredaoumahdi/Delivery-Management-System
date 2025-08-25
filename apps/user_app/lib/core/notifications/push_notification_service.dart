import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:core/core.dart';

class PushNotificationService {
  final LoggerService _logger;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Stream controllers
  final StreamController<RemoteMessage> _messageController = 
      StreamController<RemoteMessage>.broadcast();
  final StreamController<RemoteMessage> _notificationTapController = 
      StreamController<RemoteMessage>.broadcast();

  PushNotificationService(this._logger);

  // Streams
  Stream<RemoteMessage> get onMessageReceived => _messageController.stream;
  Stream<RemoteMessage> get onNotificationTapped => _notificationTapController.stream;

  /// Initialize push notification service
  Future<void> initialize() async {
    try {
      _logger.i('Initializing push notification service');
      
      // Request permission
      await _requestPermission();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Setup message handlers
      await _setupMessageHandlers();
      
      // Get FCM token
      await _getFCMToken();
      
      _logger.i('Push notification service initialized successfully');
    } catch (e) {
      _logger.e('Error initializing push notification service', e);
    }
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      _logger.i('User granted permission: ${settings.authorizationStatus}');
    } catch (e) {
      _logger.e('Error requesting notification permission', e);
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _logger.i('Local notifications initialized');
    } catch (e) {
      _logger.e('Error initializing local notifications', e);
    }
  }

  /// Setup message handlers
  Future<void> _setupMessageHandlers() async {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.i('Got a message whilst in the foreground!');
      _logger.i('Message data: ${message.data}');

      if (message.notification != null) {
        _logger.i('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }

      _messageController.add(message);
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.i('A new onMessageOpenedApp event was published!');
      _notificationTapController.add(message);
    });

    // Handle notification tap when app is terminated
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _logger.i('App opened from terminated state via notification');
      _notificationTapController.add(initialMessage);
    }
  }

  /// Get FCM token
  Future<String?> _getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        _logger.i('FCM Token: $token');
        return token;
      } else {
        _logger.w('Failed to get FCM token');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting FCM token', e);
      return null;
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'delivery_system',
        'Delivery System',
        channelDescription: 'Notifications for delivery system',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );
      
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title,
        message.notification?.body,
        platformChannelSpecifics,
        payload: json.encode(message.data),
      );
    } catch (e) {
      _logger.e('Error showing local notification', e);
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    try {
      if (response.payload != null) {
        final data = json.decode(response.payload!);
        final message = RemoteMessage.fromMap(data);
        _notificationTapController.add(message);
      }
    } catch (e) {
      _logger.e('Error handling notification tap', e);
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      _logger.i('Subscribed to topic: $topic');
    } catch (e) {
      _logger.e('Error subscribing to topic: $topic', e);
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      _logger.i('Unsubscribed from topic: $topic');
    } catch (e) {
      _logger.e('Error unsubscribing from topic: $topic', e);
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Dispose of resources
  void dispose() {
    _messageController.close();
    _notificationTapController.close();
  }
}
