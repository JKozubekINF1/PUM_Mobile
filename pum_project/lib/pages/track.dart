import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:ui';
import 'package:pum_project/services/local_storage.dart';
import 'package:provider/provider.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:pum_project/services/foreground_task_service.dart';
import 'package:permission_handler/permission_handler.dart';

class TrackPage extends StatefulWidget {
  const TrackPage({
    super.key,
  });
  @override
  State<TrackPage> createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  final MapController _mapController = MapController();
  List<LatLng> _routeList = [];
  bool _permissions = false;
  bool _activityState = false;
  LatLng? _currentPosition;
  Duration _duration = Duration();
  int _maxDistance = 0;
  double _speed = 0.0;
  double _speedAvg = 0.0;
  bool _autoCenter = true;

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    FlutterForegroundTask.stopService();
    _mapController.dispose();
    super.dispose();
  }

  void _setPermissions(bool permissions) {
    if (mounted) setState(() => _permissions = permissions);
  }

  void _centerMap() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 16);
      setState(() => _autoCenter = true);
    }
  }

  Future<bool> _startForegroundTask() async {
    String title = "Live Tracking is running";
    String description = "Tap to return to the app";
    if (mounted) {
      title = AppLocalizations.of(context)!.liveTrackingNotificationTitle;
      description = AppLocalizations.of(context)!.liveTrackingNotificationDescription;
    }
    if (!_permissions) return false;
    final granted = await _requestNotificationPermission();
    if (!granted) return false;
    try {
      await FlutterForegroundTask.startService(
        notificationTitle: title,
        notificationText: description,
        callback: startCallback,
      );
      return true;
    } catch (e) {
      debugPrint("Error starting foreground task service: $e");
      return false;
    }
  }

  Future<void> _changeActivityState(bool running) async {
    FlutterForegroundTask.sendDataToTask({'startActivity': running});
  }

  void _onReceiveTaskData(Object data) {
    if (data is Map<String, dynamic>) {
      final lat = data['lat'] as double?;
      final lng = data['lng'] as double?;
      setState(() {
        if (lat != null && lng != null) {
          _currentPosition = LatLng(lat, lng);
          _centerMap();
        }
        _maxDistance = (data['distance'] ?? _maxDistance) as int;
        _speed = (data['speed'] ?? _speed) as double;
        _speedAvg = (data['speedAvg'] ?? _speedAvg) as double;
        _duration = Duration(seconds: (data['duration'] ?? _duration.inSeconds) as int);
        final routeData = data['routeList'] as List<dynamic>? ?? [];
        _routeList = routeData
            .map((p) => LatLng(p['lat'] as double, p['lng'] as double))
            .toList();
      });
    }
  }

  Future<void> _requestLocationPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;
    bool allow = true;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      allow = false;
      if (mounted) _displaySnackbar(AppLocalizations.of(context)!.noLocationServicesMessage);
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        allow = false;
        if (mounted) _displaySnackbar(AppLocalizations.of(context)!.noLocationPermissionsMessage);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      allow = false;
      if (mounted) _displaySnackbar(AppLocalizations.of(context)!.noLocationPermissionsForeverMessage);
    }
    if (allow) {
      _setPermissions(true);
    }
  }

  Future<bool> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      final permission = await Permission.notification.request();
      if (permission.isGranted) {
        return true;
      }
      return false;
    }
    return true;
  }

  void _activityButton() async {
    setState(() {
      _activityState = !_activityState;
    });
    _changeActivityState(_activityState);
    if (!_activityState) {
      await FlutterForegroundTask.stopService();
      Map? activityContent = await _generateLocalFile();
      if (mounted) Navigator.pushNamed(context, '/results', arguments: {'Data': activityContent});
    }
    _maxDistance = 0;
    _speed = 0;
    _speedAvg = 0;
    _duration = Duration(seconds: 0);
    _routeList.clear();
  }

  void _displaySnackbar(String message) {
    var snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<Map?> _generateLocalFile() async {
    try {
      final localStorage = Provider.of<LocalStorage>(context, listen: false);

      List<Map<String, dynamic>> fixedRoute = _routeList.map((p) => {
        "coordinates": [p.latitude, p.longitude],
      }).toList();

      Map<String, dynamic> fileContent = {
        'duration': _duration.inSeconds,
        'routelist': fixedRoute,
        'distance': _maxDistance,
        'speedavg': _speedAvg
      };
      await localStorage.saveToStorage(fileContent);
      return fileContent;
    } catch (e) {
      if (mounted) _displaySnackbar(AppLocalizations.of(context)!.genericErrorMessage);
      debugPrint('$e');
    }
    return null;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void initState() {
    super.initState();
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
    _requestLocationPermissions().then((_) async {
      bool notificationPermissionGranted = await _requestNotificationPermission();
      if (_permissions && notificationPermissionGranted) {
        await _startForegroundTask();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.trackPageTitle, style: const TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: theme.appBarTheme.backgroundColor?.withValues(alpha: 0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildMap(),
          ),

          Positioned(
            right: 20,
            bottom: 300,
            child: FloatingActionButton(
              heroTag: "centerBtn",
              backgroundColor: theme.cardTheme.color,
              child: Icon(Icons.my_location, color: theme.iconTheme.color),
              onPressed: _centerMap,
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomPanel(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition ?? const LatLng(0, 0),
        initialZoom: 16,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        onPositionChanged: (pos, hasGesture) {
          if (hasGesture) {
            setState(() => _autoCenter = false);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
          userAgentPackageName: 'Pum_Project/1.0',
        ),

        PolylineLayer(
          polylines: [
            if (_routeList.isNotEmpty)
              Polyline(
                points: _routeList,
                strokeWidth: 5.0,
                color: Colors.blueAccent,
              ),
          ],
        ),


        MarkerLayer(
          markers: [
            if (_currentPosition != null)
              Marker(
                point: _currentPosition!,
                width: 60,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.circle,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomPanel(ThemeData theme) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.timeLabel.toUpperCase(),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)
                  ),
                ),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  theme,
                  Icons.straighten,
                  (_maxDistance / 1000).toStringAsFixed(2),
                  "km",
                  AppLocalizations.of(context)!.distanceLabel,
                ),
                Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.3)),
                _buildStatItem(
                  theme,
                  Icons.speed,
                  _speed.toStringAsFixed(1),
                  AppLocalizations.of(context)!.speedUnitLabel,
                  AppLocalizations.of(context)!.speedLabel,
                ),
              ],
            ),

            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _activityButton,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _activityState ? Colors.redAccent : const Color(0xff0072ff),
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_activityState ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 32),
                    const SizedBox(width: 10),
                    Text(
                      _activityState
                          ? AppLocalizations.of(context)!.stopActivityButtonLabel.toUpperCase()
                          : AppLocalizations.of(context)!.beginActivityButtonLabel.toUpperCase(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, IconData icon, String value, String unit, String label) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)
              ),
            ),
          ],
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
              fontSize: 10,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)
          ),
        ),
      ],
    );
  }
}