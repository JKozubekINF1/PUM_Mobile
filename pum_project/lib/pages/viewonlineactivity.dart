import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../services/api_connection.dart';
import '../providers/auth_provider.dart';

class ViewOnlineActivityScreen extends StatefulWidget {
  const ViewOnlineActivityScreen({
    required this.data,
    super.key,
  });

  final Map<String, dynamic> data;

  @override
  State<ViewOnlineActivityScreen> createState() =>
      _ViewOnlineActivityScreenState();
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
  String? photoUrl;
  bool _isDownloading = false;

  void initiateData() {
    try {
      if (widget.data['routeGeoJson'] != null) {
        Map<String, dynamic> geoJsonMap =
        jsonDecode(widget.data['routeGeoJson']);
        List<dynamic> coordinates = geoJsonMap['coordinates'];
        routePoints = coordinates
            .map<LatLng>((p) => LatLng(p[1].toDouble(), p[0].toDouble()))
            .toList();
      }

      if (widget.data['durationSeconds'] != null) {
        duration = widget.data['durationSeconds'];
      }

      if (widget.data['distanceMeters'] != null) {
        distance = (widget.data['distanceMeters'] as num).toDouble();
      }

      if (widget.data['averageSpeedMs'] != null) {
        speedavg = (widget.data['averageSpeedMs'] as num).toDouble();
      }

      if (widget.data['title'] != null) {
        title = widget.data['title'];
      }

      if (widget.data['description'] != null) {
        description = widget.data['description'];
      }

      if (widget.data['activityType'] != null) {
        activityType = widget.data['activityType'];
      }

      if (widget.data['photoUrl'] != null) {
        photoUrl = widget.data['photoUrl'];
      }

      if (widget.data['startedAt'] != null) {
        DateTime dateTime = DateTime.parse(widget.data['startedAt']);
        date = DateFormat('HH:mm dd.MM.yyyy').format(dateTime);
      }
    } catch (e) {
      // Ignored
    }
  }

  Future<void> _downloadGpx() async {
    if (widget.data['id'] == null) {
      _displaySnackbar("Error: Missing Activity ID");
      return;
    }

    setState(() => _isDownloading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);

      if (authProvider.token == null || authProvider.token!.isEmpty) {
        _displaySnackbar("Error: Not authenticated");
        return;
      }

      String baseUrl = apiService.baseUrl;
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      final urlString = '$baseUrl/api/Activities/${widget.data['id']}/gpx';

      final response = await http.get(
        Uri.parse(urlString),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        String fileName = "activity_${widget.data['id']}.gpx";

        final contentDisposition = response.headers['content-disposition'];
        if (contentDisposition != null && contentDisposition.contains('filename=')) {
          final match = RegExp(r'filename="?([^";]+)"?').firstMatch(contentDisposition);
          if (match != null && match.group(1) != null) {
            fileName = match.group(1)!;
          }
        } else if (widget.data['activityType'] != null) {
          String dateTimePart = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());

          if(widget.data['startedAt'] != null) {
            try {
              DateTime startDate = DateTime.parse(widget.data['startedAt']);
              dateTimePart = DateFormat('yyyy-MM-dd_HH-mm').format(startDate);
            } catch(e) {}
          }
          fileName = "${widget.data['activityType']}_$dateTimePart.gpx";
        }

        Directory? saveDir;

        if (Platform.isAndroid) {
          saveDir = Directory('/storage/emulated/0/Download');
          if (!await saveDir.exists()) {
            saveDir = await getExternalStorageDirectory();
          }
        }

        if (saveDir == null) {
          throw Exception("Could not find save directory.");
        }

        String filePath = '${saveDir.path}/$fileName';
        int counter = 1;
        while (await File(filePath).exists()) {
          String nameWithoutExt = fileName.replaceAll('.gpx', '');
          String newName = '$nameWithoutExt($counter).gpx';
          filePath = '${saveDir.path}/$newName';
          counter++;
        }

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (Platform.isAndroid) {
          _displaySnackbar("Saved to Downloads: ${filePath.split('/').last}");
        }

      } else {
        if (response.statusCode == 404) {
          _displaySnackbar("Error 404: Activity not found.");
        } else {
          _displaySnackbar("Download failed: ${response.statusCode}");
        }
      }

    } catch (e) {
      _displaySnackbar("Error: $e");
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _displaySnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _getActivityName() {
    switch (activityType.toLowerCase()) {
      case "run":
        return AppLocalizations.of(context)!.runActivityTypeLabel;
      case "bike":
      case "cycling":
        return AppLocalizations.of(context)!.bikeActivityTypeLabel;
      case "walk":
        return AppLocalizations.of(context)!.walkActivityTypeLabel;
      case "gym":
        return AppLocalizations.of(context)!.gymActivityTypeLabel;
      case "swim":
      case "swimming":
        return AppLocalizations.of(context)!.swimActivityTypeLabel;
      case "other":
        return AppLocalizations.of(context)!.otherActivityTypeLabel;
      default:
        return activityType;
    }
  }

  IconData _getActivityIcon() {
    switch (activityType.toLowerCase()) {
      case "run":
        return Icons.directions_run;
      case "bike":
      case "cycling":
        return Icons.directions_bike;
      case "walk":
        return Icons.directions_walk;
      case "gym":
        return Icons.fitness_center;
      case "swim":
      case "swimming":
        return Icons.waves;
      default:
        return Icons.sports;
    }
  }

  void _openFullScreenImage() {
    if (photoUrl == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImage(imageUrl: photoUrl!),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    initiateData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.viewActivityPageTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMap(),
            const SizedBox(height: 24),
            _buildStats(),
            const SizedBox(height: 30),
            _buildHeaderInfo(),

            if (photoUrl != null && photoUrl!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildPhotoSection(),
            ],

            if (description.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildDescriptionSection(),
            ],

            const SizedBox(height: 40),
            _buildDownloadButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    if (routePoints.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 60,
      child: ElevatedButton.icon(
        onPressed: _isDownloading ? null : _downloadGpx,
        icon: _isDownloading
            ? Container(
            width: 24,
            height: 24,
            padding: const EdgeInsets.all(2),
            child: const CircularProgressIndicator(strokeWidth: 3)
        )
            : Icon(Icons.download, color: Theme.of(context).elevatedButtonTheme.style?.foregroundColor?.resolve({})),
        label: Text(
          _isDownloading ? "Downloading..." : "Download GPX",
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: routePoints.isEmpty || routePoints.length == 1
            ? Container(
          color: Theme.of(context).cardTheme.color,
          child: Center(
              child: Text(
                  AppLocalizations.of(context)!.missingRouteMessage,
                  style: Theme.of(context).textTheme.bodyMedium)),
        )
            : FlutterMap(
          options: MapOptions(
              initialCenter: routePoints.first, initialZoom: 15),
          children: [
            TileLayer(
              urlTemplate:
              'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
              userAgentPackageName: 'Pum_Project/1.0',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                    points: routePoints,
                    color: Theme.of(context).iconTheme.color ?? Colors.blue,
                    strokeWidth: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.timer, duration.toString(),
              AppLocalizations.of(context)!.timeUnitLabel),
          Container(
              height: 40,
              width: 1,
              color: Theme.of(context).dividerColor.withOpacity(0.5)),
          _buildStatItem(Icons.straighten, distance.toStringAsFixed(2),
              AppLocalizations.of(context)!.distanceUnitLabel),
          Container(
              height: 40,
              width: 1,
              color: Theme.of(context).dividerColor.withOpacity(0.5)),
          _buildStatItem(Icons.speed, speedavg.toStringAsFixed(2),
              AppLocalizations.of(context)!.speedUnitLabel),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String unit) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).iconTheme.color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20
          ),
        ),
        Text(
          unit,
          style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color ?? Theme.of(context).textTheme.bodyMedium?.color),
        ),
      ],
    );
  }

  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 28
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: Theme.of(context).iconTheme.color),
                  const SizedBox(width: 6),
                  Text(
                    date,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color?.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor)
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getActivityIcon(),
                  color: Theme.of(context).iconTheme.color, size: 24),
              const SizedBox(width: 8),
              Text(
                _getActivityName().toUpperCase(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    fontSize: 18
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: _openFullScreenImage,
      child: Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Hero(
            tag: photoUrl!,
            child: Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Theme.of(context).cardTheme.color,
                  child: Center(
                    child: Icon(Icons.broken_image, size: 50, color: Theme.of(context).iconTheme.color),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Theme.of(context).cardTheme.color,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).iconTheme.color,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined,
                  size: 24,
                  color: Theme.of(context).iconTheme.color),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.descriptionLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: Hero(
          tag: imageUrl,
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4,
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }
}