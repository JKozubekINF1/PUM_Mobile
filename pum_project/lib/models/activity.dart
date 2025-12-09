import 'package:latlong2/latlong.dart';

class Activity {
  final String? id;
  final int duration;
  final double distance;
  final double avgSpeed;
  final List<LatLng> routelist;
  final String title;
  final String? description;
  final String activityType;
  final String filename;
  final String? photoUrl;

  Activity({
    this.id,
    required this.duration,
    required this.distance,
    required this.avgSpeed,
    required this.routelist,
    required this.title,
    required this.description,
    required this.activityType,
    required this.filename,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() => {
    'duration': duration,
    'distance': distance,
    'avgSpeed': avgSpeed,
    'routelist': routelist.map((latLng) => [latLng.latitude, latLng.longitude]).toList(),
    'title': title,
    'description': description,
    'activityType': activityType,
    'filename': filename,
  };


  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
    id: json['id'],
    duration: json['durationSeconds'] ?? json['duration'], // Backend czasem zwraca DurationSeconds
    distance: (json['distanceMeters'] ?? json['distance']).toDouble(),
    avgSpeed: (json['averageSpeedMs'] ?? json['avgSpeed']).toDouble(),
    routelist: [],
    title: json['title'],
    description: json['description'],
    activityType: json['activityType'],
    filename: json['filename'] ?? "",
    photoUrl: json['photoUrl'],
  );
}