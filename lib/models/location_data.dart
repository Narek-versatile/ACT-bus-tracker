/// Model representing location data to send to the server
class LocationData {
  final double lat;
  final double lon;

  LocationData({required this.lat, required this.lon});

  Map<String, dynamic> toJson() {
    return {'lat': lat, 'lon': lon};
  }

  @override
  String toString() {
    return 'LocationData(lat: $lat, lon: $lon)';
  }
}
