import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:ui';
import '../services/local_storage.dart';
import 'package:provider/provider.dart';

class TrackPage extends StatefulWidget {
  const TrackPage({
    super.key,
  });
  @override
  State<TrackPage> createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  final MapController _mapController = MapController();
  final List<LatLng> _routeList = [];
  final Distance distance = const Distance();
  final List<double> _speedList = [];

  LatLng? _currentPosition;
  LatLng? _lastPosition;

  bool _permissions = false;
  bool _activityState = false;
  bool _autoCenter = true;
  Duration _duration = const Duration();
  Timer? _timer;

  int _gainedDistance = 0;
  int _maxDistance = 0;

  double _speed = 0.0;
  double _speedAvg = 0.0;

  @override
  void dispose() {
    _mapController.dispose();
    _timer?.cancel();
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

  void _setActivityState(bool state) {
    if (mounted) setState(() => _activityState = state);
  }

  Future<void> _requestPermissions() async {
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
    if (allow) _setPermissions(true);
  }

  void _getPosition() async {
    final LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
    try {
      if (_permissions) {
        Position position = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          if (_autoCenter) {
            _mapController.move(_currentPosition!, _mapController.camera.zoom);
          }
        });
      }
    } catch (e) {
      setState(() => _currentPosition = null);
    }
  }

  void _updateLocation() async {
    _getPosition();
  }

  void _addToRouteList() async {
    if (_currentPosition != null) {
      setState(() {
        _routeList.add(_currentPosition!);
      });
    }
  }

  void _activity() async {
    setState(() {
      _duration = Duration(seconds: _duration.inSeconds + 1);
    });
    if (_duration.inSeconds % 5 == 0) {
      _addToRouteList();
      _calculateDistance();
      _calculateSpeed();
      _getSpeedAverage();
    }
    _updateLocation();
  }

  void _startTimer() async {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _activity());
  }

  void _stopTimer() async {
    setState(() => _timer?.cancel());
  }

  void _calculateDistance() async {
    if (_currentPosition != null && _lastPosition != null) {
      _gainedDistance = distance(_lastPosition!, _currentPosition!).toInt();
      if (_gainedDistance > 2) {
        _maxDistance += _gainedDistance;
      }
      _lastPosition = _currentPosition!;
    }
    _lastPosition = _currentPosition;
  }

  void _calculateSpeed() async {
    if (_gainedDistance > 0) {
      _speed = _gainedDistance / 5.0;
    } else {
      _speed = 0.0;
    }
    _speedList.add(_speed);
  }

  void _getSpeedAverage() async {
    if (_speedList.isEmpty) {
      _speedAvg = 0.0;
      return;
    }
    double sum = _speedList.fold(0, (p, c) => p + c);
    _speedAvg = sum / _speedList.length;
  }

  void _resetStats() async {
    setState(() {
      _routeList.clear();
      _speedList.clear();
      _duration = const Duration(seconds: 0);
      _gainedDistance = 0;
      _maxDistance = 0;
      _speed = 0;
      _speedAvg = 0;
      _getPosition();
    });
  }

  void _activityButton() async {
    _setActivityState(!_activityState);
    if (_activityState) {
      _duration = const Duration(seconds: 0);
      if (_currentPosition != null) {
        _routeList.add(_currentPosition!);
        _lastPosition = _currentPosition!;
      }
      _startTimer();
    } else {
      _stopTimer();
      _getSpeedAverage();
      Map? activityContent = await _generateLocalFile();
      _resetStats();
      if (mounted) {
        await Navigator.pushNamed(context, '/results', arguments: {
          'Data': activityContent,
        });
      }
    }
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
    _requestPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getPosition();
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