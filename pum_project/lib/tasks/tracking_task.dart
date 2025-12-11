import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

class TrackingTask extends TaskHandler {
  StreamSubscription<Position>? _positionStream;
  Timer? _timer;
  List<LatLng> routeList = [];
  final List<double> speedList = [];
  LatLng? lastPosition;
  LatLng? currentPosition;
  LatLng? positionFiveSecondsAgo;
  Distance distance = Distance();
  int maxDistance = 0;
  double speed = 0;
  double speedAvg = 0;
  Duration duration = Duration(seconds:0);
  bool activityIsRunning = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter? taskStarter) async {
    startLocationStream();
    activityLoop();
    FlutterForegroundTask.addTaskDataCallback(onReceiveData);
  }

  void startLocationStream() {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
    );
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((position) {
      currentPosition = LatLng(position.latitude, position.longitude);
    }, onError: (e) {
      debugPrint('Location stream error: $e');
    });
  }

  void activityLoop() {
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (activityIsRunning) {
        duration = Duration(seconds: duration.inSeconds + 1);
        if (duration.inSeconds % 10 == 0 && currentPosition != null) {
          routeList.add(currentPosition!);
        }
        if (duration.inSeconds % 5 == 0) {
          _calculateSpeed();
        }
        if (lastPosition != null && currentPosition != null) {
          final gained = distance(lastPosition!, currentPosition!).toInt();
          maxDistance += gained;
        }
        lastPosition = currentPosition;
      }
      if (currentPosition != null) {
        FlutterForegroundTask.sendDataToMain({
          'lat': currentPosition!.latitude,
          'lng': currentPosition!.longitude,
          'routeList': routeList.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
          'distance': maxDistance,
          'speed': speed,
          'speedAvg': speedAvg,
          'duration': duration.inSeconds,
        });
      }
    });
  }

  void _calculateSpeed() {
    if (positionFiveSecondsAgo != null && lastPosition != null) {
      speed = distance(positionFiveSecondsAgo!, lastPosition!) / 5;
      speedList.add(speed);
    }
    positionFiveSecondsAgo = lastPosition;
    _getSpeedAverage();
  }

  void _getSpeedAverage() async {
    if (speedList.isEmpty) {
      speedAvg = 0.0;
      return;
    }
    int x = 0;
    double sum = 0.0;
    for(x;x<speedList.length;x++) {
      sum += speedList[x];
    }
    speedAvg = sum / speedList.length;
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isCancelled) async {
    _timer?.cancel();
    _positionStream?.cancel();
    FlutterForegroundTask.removeTaskDataCallback(onReceiveData);
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map<String, dynamic>) {
      if (data['startActivity'] != null) {
        activityIsRunning = data['startActivity'] as bool;
        routeList.clear();
        maxDistance = 0;
        speed = 0;
        speedAvg = 0;
        duration = Duration(seconds: 0);
      }
    }
  }
}