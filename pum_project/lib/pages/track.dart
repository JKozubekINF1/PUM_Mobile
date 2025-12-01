import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
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
  final Distance distance = Distance();
  final List<double> _speedList = [];
  LatLng? _currentPosition;
  LatLng? _lastPosition;
  bool _permissions = false;
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

  void _resetMap() {
    if (_currentPosition!=null) {
      if (mounted) {
        setState(() {
          _mapController.move(_currentPosition!,16);
        });
      }
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
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
    try {
      if (_permissions) {
        Position position = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _resetMap();
        });
      }
    } catch (e) {
      setState(() {
        _currentPosition = null;
      });
    }
  }

  void _updateLocation() async {
    _getPosition();
    _resetMap();
  }

  void _addToRouteList() async {
    if (_currentPosition!=null) {
      _routeList.add(_currentPosition!);
    }
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
    if (_currentPosition!=null || _lastPosition!=null) {
      _gainedDistance = distance(
          _lastPosition!,
          _currentPosition!
      ).toInt();
      _maxDistance += _gainedDistance;
      _lastPosition = _currentPosition!;
    }
    _lastPosition = _currentPosition;
  }

  void _calculateSpeed() async {
    _speed = _gainedDistance / 10;
    _speedList.add(_speed);
  }

  void _getSpeedAverage() async {
    if (_speedList.isEmpty) {
      _speedAvg = 0.0;
      return;
    }
    int x = 0;
    double sum = 0.0;
    for(x;x<_speedList.length;x++) {
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
      if (_currentPosition!=null) {
        _routeList.add(_currentPosition!);
        _lastPosition = _currentPosition!;
      }
      _startTimer();
    } else {
      _stopTimer();
      _getSpeedAverage();
      Map? activityContent = await _generateLocalFile();
      _resetStats();
      await Navigator.pushNamed(context, '/results', arguments: {
        'Data': activityContent,
      });
    }
  }

  void _displaySnackbar(String message) {
    var snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<Map?> _generateLocalFile() async {
    try {
      final localStorage = Provider.of<LocalStorage>(context, listen: false);
      Map<String,dynamic> fileContent = {
        'duration': _duration.inSeconds,
        'routelist': _routeList,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.trackPageTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                flex: 3,
                child: SizedBox(
                  width: double.infinity,
                  child: _buildMap(),
                ),
              ),
              Expanded(
                child: SizedBox(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStopwatch(),
                      ),
                      Expanded(
                        child: _buildSpeedMeter(),
                      ),
                      Expanded(
                        child: _buildDistanceMeter(),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _buildStartStopButton(),
              ),
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
        initialCenter: _currentPosition ?? LatLng(0,0),
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
        MarkerLayer(
          markers: [
            Marker(
              point: _currentPosition ?? LatLng(0,0),
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
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStartStopButton() {
    return Flexible(
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (){
            _activityButton();
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _activityState ? Text(AppLocalizations.of(context)!.stopActivityButtonLabel) : Text(AppLocalizations.of(context)!.beginActivityButtonLabel),
        ),
      ),
    );
  }

  Widget _buildStopwatch() {
    return Card(
      child: Text(
        "${AppLocalizations.of(context)!.timeLabel}:\n${_duration.inSeconds}\n${AppLocalizations.of(context)!.timeUnitLabel}",
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDistanceMeter() {
    return Card(
      child: Text(
        "${AppLocalizations.of(context)!.distanceLabel}\n$_maxDistance\n${AppLocalizations.of(context)!.distanceUnitLabel}",
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSpeedMeter() {
    return Card(
      child: Text(
        "${AppLocalizations.of(context)!.speedLabel}:\n$_speed\n${AppLocalizations.of(context)!.speedUnitLabel}",
        textAlign: TextAlign.center,
      ),
    );
  }
}