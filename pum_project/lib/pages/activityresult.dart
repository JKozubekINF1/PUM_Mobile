import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:pum_project/services/upload_queue.dart';
import 'package:pum_project/services/local_storage.dart';
import 'package:pum_project/services/app_settings.dart';
import 'package:pum_project/services/api_connection.dart';
import 'package:provider/provider.dart';
import 'package:pum_project/models/activity.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    required this.data,
    super.key,
  });

  final Map<String, dynamic> data;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final ImagePicker picker = ImagePicker();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  List<LatLng> routePoints = <LatLng>[];
  int duration = 0;
  double distance = 0;
  double speedavg = 0;
  String activityType = "run";
  bool validForUpload = true;
  bool _hasUnsavedChanges = false;
  Map<String, String> activityLabels = {};
  bool offlineMode = true;
  String filename = "";
  XFile? image;
  String? imageName;
  bool _processing = false;

  final Map<String, IconData> activityIcons = {
    "run": Icons.directions_run,
    "bike": Icons.directions_bike,
    "walk": Icons.directions_walk,
    "gym": Icons.fitness_center,
    "swim": Icons.waves,
    "other": Icons.sports,
  };

  void initiateData() {
    final storage = Provider.of<LocalStorage>(context, listen: false);
    try {
      if (widget.data['routelist'] != null) {
        routePoints = widget.data['routelist']
            .map<LatLng>((p) => LatLng(
          p['coordinates'][0].toDouble(),
          p['coordinates'][1].toDouble(),
        ))
            .toList();
      } else {
        validForUpload = false;
      }

      if (widget.data['duration'] != null) {
        duration = widget.data['duration'];
      } else {
        validForUpload = false;
      }

      if (widget.data['distance'] != null) {
        distance = widget.data['distance'].toDouble();
      } else {
        validForUpload = false;
      }

      if (widget.data['speedavg'] != null) {
        speedavg = widget.data['speedavg'];
      } else {
        validForUpload = false;
      }

      if (widget.data['title'] != null) {
        _titleController.value = TextEditingValue(text: widget.data['title']);
      }

      if (widget.data['description'] != null) {
        _descriptionController.value =
            TextEditingValue(text: widget.data['description']);
      }

      if (widget.data['type'] != null) {
        if (activityIcons.containsKey(widget.data['type'])) {
          activityType = widget.data['type'];
        }
      }

      if (widget.data['filename'] != null) {
        filename = widget.data['filename'];
      } else {
        filename = storage.generateFileName();
      }
    } catch (e) {
      debugPrint('$e');
      validForUpload = false;
    }
  }

  void initiateDropdownMenu() {
    final loc = AppLocalizations.of(context);
    if (loc != null) {
      activityLabels = {
        "run": loc.runActivityTypeLabel,
        "bike": loc.bikeActivityTypeLabel,
        "walk": loc.walkActivityTypeLabel,
        "gym": loc.gymActivityTypeLabel,
        "swim": loc.swimActivityTypeLabel,
        "other": loc.otherActivityTypeLabel,
      };
    } else {
      activityLabels = {
        "run": "Run",
        "bike": "Bike",
        "walk": "Walk",
        "gym": "Gym",
        "swim": "Swim",
        "other": "Other"
      };
    }
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    initiateData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initiateDropdownMenu();
    _checkOfflineMode();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? newImage = await picker.pickImage(source: source);
      if (newImage != null) {
        setState(() {
          image = newImage;
          imageName = image?.name;
          _hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library,
                    color: Theme.of(context).iconTheme.color),
                title: Text(
                  AppLocalizations.of(context)?.galleryOptionLabel ?? "Gallery",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera,
                    color: Theme.of(context).iconTheme.color),
                title: Text(
                  AppLocalizations.of(context)?.cameraOptionLabel ?? "Camera",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveActivity() async {
    setState(() => _processing = true);

    final queue = Provider.of<UploadQueue>(context, listen: false);
    final storage = Provider.of<LocalStorage>(context, listen: false);
    final api = Provider.of<ApiService>(context, listen: false);

    try {
      Activity activity = Activity(
        duration: duration,
        distance: distance,
        avgSpeed: speedavg,
        routelist: routePoints,
        title: _titleController.text.trim().isEmpty
            ? "No Title"
            : _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        activityType: activityType,
        filename: filename,
        image: image,
      );

      bool saveSuccess = false;

      if (offlineMode) {
        await queue.addActivity(activity);
        await storage.deleteFile(filename);
        if (mounted) {
          _displaySnackbar(AppLocalizations.of(context)?.noConnectionMessage ?? "Saved offline");
          Navigator.pushReplacementNamed(context,'/home');
        }
      } else {
        String? newActivityId = await api.saveActivity(
          durationSeconds: duration,
          distanceMeters: distance,
          averageSpeedMs: speedavg,
          routeCoordinates:
          routePoints.map((p) => [p.latitude, p.longitude]).toList(),
          title: _titleController.text,
          description: _descriptionController.text,
          activityType: activityType,
        );

        if (newActivityId != null) {
          saveSuccess = true;
          await storage.deleteFile(filename);

          final img = image;
          if (img != null) {
            try {
              await api.uploadActivityPhoto(id: newActivityId, imageFile: img);
              if (mounted) {
                _displaySnackbar("Activity and photo saved!");
              }
            } catch (e) {
              debugPrint("Photo upload error: $e");
              if (mounted) {
                _displaySnackbar("Activity saved, but photo failed.");
              }
            }
          } else {
            if (mounted) {
              _displaySnackbar(
                  AppLocalizations.of(context)?.activitySentMessage ??
                      "Activity Sent");
            }
          }
        }
      }

      setState(() => _processing = false);

      if (saveSuccess && mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _displaySnackbar(
            AppLocalizations.of(context)?.genericErrorMessage ?? "Error");
      }
      debugPrint("Save error: $e");
      setState(() => _processing = false);
    }
  }

  Future<void> _saveLocally() async {
    try {
      setState(() => _processing = true);
      final localStorage = Provider.of<LocalStorage>(context, listen: false);
      final Map<String, dynamic> values = {
        "title": _titleController.text,
        "description": _descriptionController.text,
        "type": activityType,
      };
      if (widget.data['filename'] != null) {
        await localStorage.overwriteFile(widget.data['filename'], values);
      } else {
        debugPrint('File name is missing from json');
      }
      setState(() => _processing = false);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('$e');
      setState(() => _processing = false);
    }
  }

  Future<void> _deleteActivity() async {
    try {
      setState(() => _processing = true);
      final localStorage = Provider.of<LocalStorage>(context, listen: false);
      if (widget.data['filename'] != null) {
        await localStorage.deleteFile(widget.data['filename']);
      } else {
        debugPrint('File name is missing from json');
      }
    } catch (e) {
      debugPrint('$e');
      setState(() => _processing = false);
    }
  }

  void _displaySnackbar(String message) {
    var snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _leavePopup() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)?.warningLabel ?? "Warning"),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(AppLocalizations.of(context)
                      ?.unsavedChangesWarningMessage ??
                      "Unsaved changes"),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                    AppLocalizations.of(context)?.acceptOptionLabel ?? "Yes"),
                onPressed: () {
                  Navigator.pop(context, true);
                  Navigator.pop(context, true);
                },
              ),
              TextButton(
                child: Text(
                    AppLocalizations.of(context)?.declineOptionLabel ?? "No"),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
            ],
          );
        });
  }

  Future<void> _deletePopup() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)?.warningLabel ?? "Warning"),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(AppLocalizations.of(context)?.activityDeletionMessage ??
                      "Delete activity?"),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                    AppLocalizations.of(context)?.acceptOptionLabel ?? "Yes"),
                onPressed: () {
                  _deleteActivity();
                  Navigator.pushNamedAndRemoveUntil(
                      context, "/home", (_) => false);
                },
              ),
              TextButton(
                child: Text(
                    AppLocalizations.of(context)?.declineOptionLabel ?? "No"),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
            ],
          );
        });
  }

  Future<void> _checkOfflineMode() async {
    try {
      final appSettings = Provider.of<AppSettings>(context, listen: false);
      final mode = await appSettings.checkOfflineMode();
      if (mounted) {
        setState(() {
          offlineMode = mode ?? true;
        });
      }
    } catch (e) {
      if (mounted) {
        _displaySnackbar(
            AppLocalizations.of(context)?.genericErrorMessage ?? "Error");
      }
      debugPrint('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!_hasUnsavedChanges) {
          Navigator.pop(context);
          return;
        }
        await _leavePopup();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)?.resultPageTitle ?? "Results"),
          actions: [
            _buildSaveLocallyButton(),
          ],
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
              _buildTypeField(),
              const SizedBox(height: 20),
              _buildTitleField(),
              const SizedBox(height: 20),
              _buildDescriptionField(),
              const SizedBox(height: 30),
              _buildUploadPictureRow(),
              const SizedBox(height: 50),
              _buildControlRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    final theme = Theme.of(context);
    final trailColor = theme.colorScheme.primary;
    return Container(
      height: 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                  AppLocalizations.of(context)?.missingRouteMessage ??
                      "No route")),
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
                    color: trailColor,
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.timer, duration.toString(),
              AppLocalizations.of(context)?.timeUnitLabel ?? "s"),
          Container(
              height: 40,
              width: 1,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          _buildStatItem(Icons.straighten, distance.toStringAsFixed(2),
              AppLocalizations.of(context)?.distanceUnitLabel ?? "m"),
          Container(
              height: 40,
              width: 1,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          _buildStatItem(Icons.speed, speedavg.toStringAsFixed(2),
              AppLocalizations.of(context)?.speedUnitLabel ?? "m/s"),
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
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        Text(
          unit,
          style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color),
        ),
      ],
    );
  }

  Widget _buildTypeField() {
    return DropdownButtonFormField<String>(
      initialValue: activityType,
      dropdownColor: Theme.of(context).cardTheme.color,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: _inputDecoration(
          AppLocalizations.of(context)?.activityTypeLabel ?? "Type",
          Icons.sports),
      items: activityIcons.keys.map((key) {
        return DropdownMenuItem(
          value: key,
          child: Row(
            children: [
              Icon(activityIcons[key],
                  size: 24, color: Theme.of(context).iconTheme.color),
              const SizedBox(width: 10),
              Text(activityLabels[key] ?? key,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        _hasUnsavedChanges = true;
        if (value != null) {
          setState(() => activityType = value);
        }
      },
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      onChanged: (_) => _hasUnsavedChanges = true,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: _inputDecoration(
          AppLocalizations.of(context)?.titleLabel ?? "Title", Icons.title),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      onChanged: (_) => _hasUnsavedChanges = true,
      maxLines: 4,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: _inputDecoration(
        "${AppLocalizations.of(context)?.descriptionLabel ?? "Description"} (${AppLocalizations.of(context)?.optionalLabel ?? "optional"})",
        Icons.description_outlined,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
    );
  }

  Widget _buildUploadPictureRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                _showImageSourceOptions();
              },
              icon: const Icon(Icons.add_a_photo),
              label: Text(
                  AppLocalizations.of(context)?.uploadPictureButtonLabel ??
                      "Add Picture",
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center),
              style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(0, 50)),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (image != null)
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(File(image!.path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Text(
                  imageName ?? "No image selected",
                  style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: imageName == null
                          ? Theme.of(context).disabledColor
                          : Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveLocallyButton() {
    return IconButton(
      onPressed: () async {
        if (!_processing) {
          await _saveLocally();
        }
      },
      iconSize: 28,
      tooltip: "Save Locally",
      icon: const Icon(Icons.save_outlined),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      height: 60,
      child: OutlinedButton(
        onPressed: () async {
          if (!_processing) {
            _deletePopup();
          }
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.red.shade400, width: 2),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          foregroundColor: Colors.red.shade400,
        ),
        child: const Icon(Icons.delete_outline, size: 30),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: () async {
        if (!_processing) {
          await _saveActivity();
        }
      },
      child: _processing
          ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2))
          : Text(
        AppLocalizations.of(context)?.submitLabel.toUpperCase() ??
            "SUBMIT",
      ),
    );
  }

  Widget _buildControlRow() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildDeleteButton(),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: _buildSubmitButton(),
        ),
      ],
    );
  }
}