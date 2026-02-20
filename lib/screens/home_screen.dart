import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../services/background_service.dart';

/// Main home screen showing tracking status and controls
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService();
  final _locationService = LocationService();
  final _backgroundService = BackgroundService();

  bool _isTracking = false;
  String? _login;
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load driver info
    _login = _storage.getLogin();
    _isTracking = _storage.getTrackingEnabled();

    // Check permissions
    _hasLocationPermission = await _locationService.hasPermissions();

    setState(() {});

    // Auto-start tracking if it was previously enabled
    if (_isTracking && !_hasLocationPermission) {
      // Request permissions
      final granted = await _locationService.requestPermissions();
      if (granted) {
        _hasLocationPermission = true;
        await _startTracking();
      } else {
        // Permissions denied, disable tracking
        _isTracking = false;
        await _storage.setTrackingEnabled(false);
      }
      setState(() {});
    } else if (_isTracking && _hasLocationPermission) {
      // Resume tracking
      await _backgroundService.startTracking();
    }
  }

  Future<void> _startTracking() async {
    // Request permissions if not already granted
    if (!_hasLocationPermission) {
      final granted = await _locationService.requestPermissions();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required for tracking'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      _hasLocationPermission = true;
    }

    setState(() => _isTracking = true);
    await _storage.setTrackingEnabled(true);
    await _backgroundService.startTracking();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tracking started'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _stopTracking() async {
    setState(() => _isTracking = false);
    await _storage.setTrackingEnabled(false);
    await _backgroundService.stopTracking();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tracking stopped'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Tracking'),
        backgroundColor: _isTracking ? Colors.green : Colors.grey,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Indicator
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: _isTracking
                    ? Colors.green.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isTracking ? Colors.green : Colors.grey,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _isTracking ? Icons.location_on : Icons.location_off,
                    size: 80,
                    color: _isTracking ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isTracking ? 'TRACKING ACTIVE' : 'TRACKING INACTIVE',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _isTracking
                          ? Colors.green.shade800
                          : Colors.grey.shade700,
                    ),
                  ),
                  if (_isTracking) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Location updates every 10 seconds',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Driver Information
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Driver Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Logged in as',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                _login ?? 'Not logged in',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Control Button
            ElevatedButton(
              onPressed: _isTracking ? _stopTracking : _startTracking,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTracking ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isTracking ? 'DISABLE TRACKING' : 'ENABLE TRACKING',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
