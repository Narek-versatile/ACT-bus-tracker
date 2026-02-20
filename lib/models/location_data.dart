/// Model representing location data to send to the server
class LocationData {
  final double latitude;
  final double longitude;
  final String timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  /// Convert to JSON format matching the backend API specification
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
    };
  }

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, time: $timestamp)';
  }
}
