import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants.dart';
import 'location_service.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Service for managing background location tracking using flutter_background_service
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  /// Initialize background service
  Future<void> init() async {
    final service = FlutterBackgroundService();

    // Create notification channel for Android (in main isolate)
    const androidChannel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: 'Shows when bus tracking is active',
      importance: Importance.low,
    );

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        // This will be executed when app is in foreground or background in separate isolate
        onStart: onStart,

        // auto start service
        autoStart: false,
        isForegroundMode: true,

        notificationChannelId: AppConstants.notificationChannelId,
        initialNotificationTitle: 'Bus Tracking',
        initialNotificationContent: 'Initializing service...',
        foregroundServiceNotificationId: AppConstants.notificationId,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
  }

  /// Start background tracking
  Future<void> startTracking() async {
    final service = FlutterBackgroundService();
    // Start the service if not running
    if (!await service.isRunning()) {
      await service.startService();
    }
    // Invoke logic to ensure we are tracking
    service.invoke('startTracking');
  }

  /// Stop background tracking
  Future<void> stopTracking() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }
}

// Top-level function for background execution
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    // Only available for flutter 3.0.0 and later
    DartPluginRegistrant.ensureInitialized();

    // Initialize services in this isolate
    final storage = StorageService();
    await storage.init();

    final locationService = LocationService();
    final apiService = ApiService();

    // For Android, we manage the notification
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Initialize notifications in background isolate
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    // Explicitly create channel to ensure it exists
    const androidChannel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: 'Shows when bus tracking is active',
      importance: Importance.low,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Start periodic timer for location updates
    Timer.periodic(Duration(seconds: AppConstants.updateIntervalSeconds), (
      timer,
    ) async {
      try {
        if (service is AndroidServiceInstance) {
          if (await service.isForegroundService()) {
            // Check if tracking is enabled in storage
            if (!storage.getTrackingEnabled()) {
              service.stopSelf();
              return;
            }

            final location = await locationService.getLocationData();

            String notificationBody = 'Updates running...';

            if (location != null) {
              notificationBody =
                  'Last update: ${DateTime.now().toLocal().toString().split('.').first}';

              // Send to API
              await apiService.sendLocation(location);
            } else {
              notificationBody = 'Waiting for GPS...';
            }

            flutterLocalNotificationsPlugin.show(
              AppConstants.notificationId,
              'Bus Tracking Active',
              notificationBody,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  AppConstants.notificationChannelId,
                  AppConstants.notificationChannelName,
                  icon: '@mipmap/ic_launcher',
                  ongoing: true,
                  importance: Importance.low,
                  priority: Priority.low,
                ),
              ),
            );
          }
        }
      } catch (e) {
        print('Error in background timer: $e');
      }
    });
  } catch (e) {
    print('Error starting background service: $e');
  }
}
