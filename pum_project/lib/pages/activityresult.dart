import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:pum_project/services/api_connection.dart';
import 'package:provider/provider.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
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

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  String _selectedActivityType = "Bieg";

  final Map<String, IconData> activityIcons = {
    "Bieg": Icons.directions_run,
    "Rower": Icons.directions_bike,
    "Spacer": Icons.directions_walk,
    "Siłownia": Icons.fitness_center,
    "Pływanie": Icons.waves,
    "Inne": Icons.sports,
  };

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveActivity() async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    final routeJson = widget.route.map((p) => [p.longitude, p.latitude]).toList();

    try {
      await apiService.saveActivity(
        durationSeconds: widget.duration,
        distanceMeters: widget.distance.toDouble(),
        averageSpeedMs: widget.speedavg,
        routeCoordinates: routeJson,
        title: _titleController.text.trim().isEmpty ? "Aktywność bez tytułu" : _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        activityType: _selectedActivityType,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aktywność zapisana!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.resultPageTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Mapa
            SizedBox(
              height: 350,
              child: widget.route.isEmpty
                  ? const Center(child: Text("Brak trasy"))
                  : FlutterMap(
                options: MapOptions(initialCenter: widget.route.first, initialZoom: 15),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
                    userAgentPackageName: 'Pum_Project/1.0',
                  ),
                  PolylineLayer(
                    polylines: [Polyline(points: widget.route, color: Colors.red, strokeWidth: 8)],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Czas: ${widget.duration}s  •  Dystans: ${widget.distance}m  •  Śr. prędkość: ${widget.speedavg.toStringAsFixed(2)} m/s",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 30),

            DropdownButtonFormField<String>(
              value: _selectedActivityType,
              decoration: const InputDecoration(
                labelText: "Rodzaj aktywności",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sports),
              ),
              items: activityIcons.keys.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(activityIcons[type]),
                      const SizedBox(width: 10),
                      Text(type),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedActivityType = value!),
            ),
            const SizedBox(height: 16),

            // Tytuł
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Tytuł aktywności",
                hintText: "np. Poranny bieg w Lesie Wolskim",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Opis
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Opis (opcjonalnie)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _saveActivity();
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF375534),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("ZAPISZ AKTYWNOŚĆ", style: TextStyle(fontSize: 20, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}