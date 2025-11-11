import 'package:flutter/material.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

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
  final Distance distance = Distance();
  final List<double> _speedList = [];
  LatLng _currentPosition = LatLng(0, 0);
  LatLng _lastPosition = LatLng(0,0);
  bool _permissions = false;
  String _message = "";
  bool _activityState = false;
  Duration _duration = Duration();
  Timer? _timer;
  int _gainedDistance = 0;
  int _maxDistance = 0;
  double _speed = 0.0;
  double _speedAvg = 0.0;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _setPermissions(bool permissions) {
    if (mounted) {
      setState(() {
        _permissions = permissions;
      });
    }
  }

  void _setMessage(String text) {
    if (mounted) {
      setState(() {
        _message = text;
      });
    }
  }

  void _resetMap() {
    if (mounted) {
      setState(() {
        _mapController.move(_currentPosition,16);
      });
    }
  }

  void _setActivityState(bool state) {
    if (mounted) {
      setState(() {
        _activityState = state;
      });
    }
  }

  Future<void> _requestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _setMessage(AppLocalizations.of(context)!.noLocationServicesMessage);
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _setMessage(AppLocalizations.of(context)!.noLocationPermissionsMessage);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _setMessage(AppLocalizations.of(context)!.noLocationPermissionsForeverMessage);
    }
    _setPermissions(true);
  }

  void _getPosition() async {
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );
    try {
      await _requestPermissions();
      if (_permissions) {
        Position position = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _resetMap();
        });
      }
    } catch (e) {
      setState(() {
        _currentPosition = LatLng(0, 0);
      });
    }
  }

  void _updateLocation() async {
    _getPosition();
    _resetMap();
  }

  void _addToRouteList() async {
    _routeList.add(_currentPosition);
  }

  void _activity() async {
    setState((){
      _duration = Duration(seconds: _duration.inSeconds + 1);
    });
    if (_duration.inSeconds % 10 == 0) {
      _addToRouteList();
      _calculateDistance();
      _calculateSpeed();
      _getSpeedAverage();
    }
    _updateLocation();
  }

  void _startTimer() async {
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _activity());
  }

  void _stopTimer() async {
    setState((){
      _timer?.cancel();
    });
  }

  void _calculateDistance() async {
    _gainedDistance = distance(
      _lastPosition,
      _currentPosition
    ).toInt();
    _maxDistance += _gainedDistance;
    _lastPosition = _currentPosition;
  }

  void _calculateSpeed() async {
    _speed = _gainedDistance / 10;
    _speedList.add(_speed);
  }

  void _getSpeedAverage() async {
    int x = 0;
    double sum = 0.0;
    for(x;x<=_speedList.length;x++) {
      sum += _speedList[x];
    }
    _speedAvg = sum / _speedList.length;
  }

  void _resetStats() async {
    setState((){
      _routeList.clear();
      _speedList.clear();
      _duration = Duration(seconds: 0);
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
      _duration = Duration(seconds: 0);
      _routeList.add(_currentPosition);
      _lastPosition = _currentPosition;
      _startTimer();
    } else {
      _stopTimer();
      _getSpeedAverage();
      await Navigator.pushNamed(context, '/results', arguments: {
        'Duration': _duration.inSeconds,
        'RouteList': _routeList,
        "Distance": _maxDistance,
        "Speed": _speed,
        "SpeedAvg": _speedAvg
      });
      _resetStats();
    }
  }

  @override
  void initState() {
    super.initState();
    _getPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
            children: <Widget>[
              Text(AppLocalizations.of(context)!.trackPageTitle), const SizedBox(height: 10),
              SizedBox(
                height: 400,
                width: double.infinity,
                child: _buildMap(),
              ),
              _buildCoordinatesText(), const SizedBox(height: 24),
              _buildMessageText(), const SizedBox(height: 24),
              _buildStartStopButton(), const SizedBox(height: 20),
              _buildStopwatch(), const SizedBox(height: 3),
              _buildDistanceMeter(), const SizedBox(height: 3),
              _buildSpeedMeter(), const SizedBox(height: 3),
              _buildSpeedAvgMeter(), const SizedBox(height: 3),
            ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options:
        MapOptions(
          initialCenter: _currentPosition,
          initialZoom: 16,
          interactionOptions: InteractionOptions(
              flags: InteractiveFlag.none,
          ),
        ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
          userAgentPackageName: 'Pum_Project/1.0',
        ),
        SimpleAttributionWidget(
          source: Text('OpenStreetMap contributors'),
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _currentPosition,
              width: 50,
              height: 80,
              child: Icon(
                Icons.location_on,
                color: Colors.red,
                size: 50.0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoordinatesText() {
    // Temp text, delete later
    return Text(
      "${_currentPosition.latitude}, ${_currentPosition.longitude}",
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessageText() {
    return Text(
      _message,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStartStopButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
          onPressed: (){
            _activityButton();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _activityState? const Color(0xFFE91E63) : const Color(0xFF375534),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _activityState ? Text(AppLocalizations.of(context)!.stopActivityButtonLabel) : Text(AppLocalizations.of(context)!.beginActivityButtonLabel),
      ),
    );
  }

  Widget _buildStopwatch() {
    return Text(
      "TIME: ${_duration.inSeconds} seconds",
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDistanceMeter() {
    return Text(
      "DISTANCE: $_maxDistance meters",
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSpeedMeter() {
    return Text(
      "SPEED: $_speed m/s",
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSpeedAvgMeter() {
    return Text(
      "SPEED AVG: $_speedAvg m/s",
      textAlign: TextAlign.center,
    );
  }
}