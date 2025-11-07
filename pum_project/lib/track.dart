import 'package:flutter/material.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class TrackPage extends StatefulWidget {
  const TrackPage({
    super.key,
  });
  @override
  State<TrackPage> createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = LatLng(0, 0);
  bool _permissions = false;
  String _message = "";

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

  @override
  void initState() {
    super.initState();
    _updateLocation();
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
      _currentPosition.latitude.toString() +", "+_currentPosition.longitude.toString(),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessageText() {
    return Text(
      _message,
      textAlign: TextAlign.center,
    );
  }
}