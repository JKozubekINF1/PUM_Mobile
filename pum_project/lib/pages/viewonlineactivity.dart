import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class ViewOnlineActivityScreen extends StatefulWidget {
  const ViewOnlineActivityScreen({
    required this.data,
    super.key,
  });

  final Map<String,dynamic> data;

  @override
  State<ViewOnlineActivityScreen> createState() => _ViewOnlineActivityScreenState();
}

class _ViewOnlineActivityScreenState extends State<ViewOnlineActivityScreen> {
  List<LatLng> routePoints = <LatLng>[];
  int duration = 0;
  double distance = 0;
  double speedavg = 0;
  String activityType = "";
  String title = "";
  String description = "";
  String date = "";

  void initiateData() {
    try {
      if (widget.data['routeGeoJson']!=null) {
        Map<String, dynamic> geoJsonMap = jsonDecode(widget.data['routeGeoJson']);
        List<dynamic> coordinates = geoJsonMap['coordinates'];
        routePoints = coordinates
            .map<LatLng>((p) => LatLng(p[1].toDouble(), p[0].toDouble()))
            .toList();
      }

      if (widget.data['durationSeconds']!=null) {
        duration = widget.data['durationSeconds'];
      }

      if (widget.data['distanceMeters']!=null) {
        distance = (widget.data['distanceMeters'] as num).toDouble();
      }

      if (widget.data['averageSpeedMs']!=null) {
        speedavg = (widget.data['averageSpeedMs'] as num).toDouble();
      }

      if (widget.data['title']!=null) {
        title = widget.data['title'];
      }

      if (widget.data['description']!=null) {
        description = widget.data['description'];
      }

      if (widget.data['activityType']!=null) {
        activityType = widget.data['activityType'];
      }

      if (widget.data['startedAt']!=null) {
        DateTime dateTime = DateTime.parse(widget.data['startedAt']);
        date = DateFormat('HH:mm dd.MM.yyyy').format(dateTime);
      }

    } catch (e) {
      debugPrint('$e');
    }
  }

  String _getActivityName() {
    switch (activityType) {
      case "run": return AppLocalizations.of(context)!.runActivityTypeLabel;
      case "bike": return AppLocalizations.of(context)!.bikeActivityTypeLabel;
      case "walk": return AppLocalizations.of(context)!.walkActivityTypeLabel;
      case "gym": return AppLocalizations.of(context)!.gymActivityTypeLabel;
      case "swim": return AppLocalizations.of(context)!.swimActivityTypeLabel;
      case "other": return AppLocalizations.of(context)!.otherActivityTypeLabel;
    }
    return "";
  }

  @override
  void initState() {
    super.initState();
    initiateData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.viewActivityPageTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTitle(),
            _buildTypeText(),
            const SizedBox(height: 10),
            _buildDescription(),
            const SizedBox(height: 20),
            _buildDate(),
            const SizedBox(height: 10),
            _buildMap(),
            const SizedBox(height: 10),
            _buildStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return SizedBox(
      height: 350,
      child: routePoints.isEmpty || routePoints.length == 1
          ? Center(child: Text(AppLocalizations.of(context)!.missingRouteMessage))
          : FlutterMap(
        options: MapOptions(initialCenter: routePoints.first, initialZoom: 15),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
            userAgentPackageName: 'Pum_Project/1.0',
          ),
          PolylineLayer(
            polylines: [Polyline(points: routePoints, color: Colors.red, strokeWidth: 8)],
          ),
        ],
      ),
    );
  }

  Widget _buildDate() {
    return Text(
      date,
      style: TextStyle(fontSize: 18),
    );
  }

  Widget _buildTitle() {
    return Text(
      title,
      style: TextStyle(fontSize: 30),
    );
  }

  Widget _buildDescription() {
    return Text(
      description,
    );
  }

  Widget _buildTypeText() {
    return Text(
      _getActivityName(),
      style: TextStyle(fontSize: 12),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(child:_buildTimeDisplay()),
        Expanded(child:_buildDistanceDisplay()),
        Expanded(child:_buildAvgSpeedDisplay()),
      ],
    );
  }

  Widget _buildTimeDisplay() {
    return Card(
      child: Text(
        "${AppLocalizations.of(context)!.timeLabel}:\n$duration\n${AppLocalizations.of(context)!.timeUnitLabel}",
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDistanceDisplay() {
    return Card(
      child: Text(
        "${AppLocalizations.of(context)!.distanceLabel}\n${distance.toStringAsFixed(2)}\n${AppLocalizations.of(context)!.distanceUnitLabel}",
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAvgSpeedDisplay() {
    return Card(
      child: Text(
        "${AppLocalizations.of(context)!.avgSpeedLabel}:\n${speedavg.toStringAsFixed(2)}\n${AppLocalizations.of(context)!.speedUnitLabel}",
        textAlign: TextAlign.center,
      ),
    );
  }
}