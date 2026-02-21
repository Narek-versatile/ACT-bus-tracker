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

  Map<String, dynamic> toJson() {
    return {'lat': latitude, 'lng': longitude, 'time': timestamp};
  }

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, time: $timestamp)';
  }
}
