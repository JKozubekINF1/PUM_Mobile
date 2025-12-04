import 'package:latlong2/latlong.dart';
import 'dart:typed_data';

class Activity {
  final int duration;
  final double distance;
  final double avgSpeed;
  final List<LatLng> routelist;
  final String title;
  final String? description;
  final String activityType;
  final String filename;
  final Uint8List? imageBytes;

  Activity({
    required this.duration,
    required this.distance,
    required this.avgSpeed,
    required this.routelist,
    required this.title,
    required this.description,
    required this.activityType,
    required this.filename,
    this.imageBytes,
  });

  Map<String, dynamic> toJson() => {
    'duration': duration,
    'distance': distance,
    'avgSpeed': avgSpeed,
    'routelist': routelist.map((latLng) => {'coordinates': [latLng.latitude, latLng.longitude]}).toList(),
    'title': title,
    'description': description,
    'activityType': activityType,
    'filename': filename,
  };

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
    duration: json['duration'],
    distance: json['distance'],
    avgSpeed: json['avgSpeed'],
    routelist: (json['routelist'] as List).map<LatLng>((e) => LatLng((e['coordinates'][0] as num).toDouble(), (e['coordinates'][1] as num).toDouble(),)).toList(),
    title: json['title'],
    description: json['description'],
    activityType: json['activityType'],
    filename: json['filename'],
  );
}