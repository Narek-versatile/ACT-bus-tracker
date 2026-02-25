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
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: AppConstants.notificationChannelId,
        initialNotificationTitle: 'ACT Drive',
        initialNotificationContent: 'Location tracking active',
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
    if (!await service.isRunning()) {
      await service.startService();
      // Give the isolate a moment to boot before invoking
      await Future.delayed(const Duration(milliseconds: 500));
    }
    service.invoke('startTracking');
  }

  /// Stop background tracking
  Future<void> stopTracking() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }
}

// Top-level function for background execution — runs in a separate isolate
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // IMPORTANT: Only DartPluginRegistrant here — NOT WidgetsFlutterBinding.
  // WidgetsFlutterBinding cannot be used in a background isolate and will
  // cause a permanent hang on Samsung One UI devices.
  DartPluginRegistrant.ensureInitialized();

  // Initialize storage in this isolate
  final storage = StorageService();
  await storage.init();

  final locationService = LocationService();
  final apiService = ApiService();

  // Immediately update the foreground notification so it never shows
  // "Initializing service..." for more than an instant.
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'ACT Drive',
      content: 'Location tracking active',
    );

    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  // Listen for stop command
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Track whether the periodic timer is active
  Timer? locationTimer;

  void startLocationTimer() {
    // Avoid creating duplicate timers
    if (locationTimer != null && locationTimer!.isActive) return;

    locationTimer = Timer.periodic(
      Duration(seconds: AppConstants.updateIntervalSeconds),
      (timer) async {
        try {
          if (service is AndroidServiceInstance) {
            // Stop if tracking was disabled externally
            if (!storage.getTrackingEnabled()) {
              timer.cancel();
              service.stopSelf();
              return;
            }

            final location = await locationService.getLocationData();

            String notificationContent;
            if (location != null) {
              notificationContent =
                  'Last update: ${DateTime.now().toLocal().toString().split('.').first}';
              await apiService.sendLocation(location);
            } else {
              notificationContent = 'Waiting for GPS signal...';
            }

            // Use setForegroundNotificationInfo — this is the correct way
            // to update the foreground service's own notification.
            // Do NOT use flutter_local_notifications.show() for this.
            service.setForegroundNotificationInfo(
              title: 'ACT Drive',
              content: notificationContent,
            );
          }
        } catch (e) {
          print('Error in background timer: $e');
        }
      },
    );
  }

  // Listen for startTracking event from the main isolate
  service.on('startTracking').listen((event) {
    startLocationTimer();
  });

  // Also auto-start the timer if tracking was already enabled before
  // the service was launched (e.g. after a device reboot or app resume)
  if (storage.getTrackingEnabled()) {
    startLocationTimer();
  }
}
