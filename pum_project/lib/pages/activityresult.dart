import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';

class ResultScreen extends StatelessWidget {
  ResultScreen({
    required this.duration,
    required this.route,
    required this.distance,
    required this.speedavg,
    super.key,
  });

  final int duration;
  final List<LatLng> route;
  final int distance;
  final double speedavg;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.resultPageTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 400,
              width: double.infinity,
              child: _buildMap(),
            ),
            _buildStatsText(), const SizedBox(height: 20),
            _buildTitleField(), const SizedBox(height: 16),
            _buildDescriptionField(), const SizedBox(height: 16),
            _buildSubmitButton(), const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      options:
      MapOptions(
        initialCenter: route.first,
        initialZoom: 15,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
          userAgentPackageName: 'Pum_Project/1.0',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: route,
              color: Colors.red,
              strokeWidth: 10,
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

  Widget _buildStatsText() {
    return Text(
      "TIME: $duration seconds\nDISTANCE: $distance meters\nSPEED AVERAGE: $speedavg m/s",
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: "Title",
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: "Description",
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
          onPressed: (){
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF375534),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text("SUBMIT (to be added)")
      ),
    );
  }
}