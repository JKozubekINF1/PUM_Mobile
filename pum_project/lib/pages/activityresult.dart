import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:pum_project/services/upload_queue.dart';
import 'package:pum_project/services/local_storage.dart';
import 'package:pum_project/services/app_settings.dart';
import 'package:provider/provider.dart';
import 'package:pum_project/models/activity.dart';
import 'package:image_picker/image_picker.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    required this.data,
    super.key,
  });

  final Map<String,dynamic> data;

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
  Map<String,String> activityLabels = {};
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
      if (widget.data['routelist']!=null) {
        routePoints = widget.data['routelist']
            .map<LatLng>((p) =>
            LatLng(
              p['coordinates'][0].toDouble(),
              p['coordinates'][1].toDouble(),
            )).toList();
      } else {
        validForUpload = false;
      }

      if (widget.data['duration']!=null) {
        duration = widget.data['duration'];
      } else {
        validForUpload = false;
      }

      if (widget.data['distance']!=null) {
        distance = widget.data['distance'].toDouble();
      } else {
        validForUpload = false;
      }

      if (widget.data['speedavg']!=null) {
        speedavg = widget.data['speedavg'];
      } else {
        validForUpload = false;
      }

      if (widget.data['title']!=null) {
        _titleController.value = TextEditingValue(text: widget.data['title']);
      }

      if (widget.data['description']!=null) {
        _descriptionController.value = TextEditingValue(text: widget.data['description']);
      }

      if (widget.data['type']!=null ) {
        if (activityIcons.containsKey(widget.data['type'])) {
          activityType = widget.data['type'];
        }
      }

      if (widget.data['filename']!=null) {
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
    activityLabels = {
      "run": AppLocalizations.of(context)!.runActivityTypeLabel,
      "bike": AppLocalizations.of(context)!.bikeActivityTypeLabel,
      "walk": AppLocalizations.of(context)!.walkActivityTypeLabel,
      "gym": AppLocalizations.of(context)!.gymActivityTypeLabel,
      "swim": AppLocalizations.of(context)!.swimActivityTypeLabel,
      "other": AppLocalizations.of(context)!.otherActivityTypeLabel,
    };
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

  Future<void> _saveActivity() async {
    _processing = true;
    final queue = Provider.of<UploadQueue>(context, listen: false);
    final storage = Provider.of<LocalStorage>(context, listen: false);

    try {
      Activity activity = Activity(
        duration: duration,
        distance: distance,
        avgSpeed: speedavg,
        routelist: routePoints,
        title: _titleController.text.trim().isEmpty ? "No Title" : _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        activityType: activityType,
        filename: filename,
      );

      final result = await queue.addActivity(activity);
      await storage.deleteFile(filename);
      _processing = false;

      if (result) {
        if (mounted) _displaySnackbar(AppLocalizations.of(context)!.activitySentMessage);
      } else {
        if (mounted) _displaySnackbar(AppLocalizations.of(context)!.noConnectionMessage);
      }

    } catch (e) {
      if (mounted) _displaySnackbar(AppLocalizations.of(context)!.genericErrorMessage);
      debugPrint("$e");
      _processing = false;
    }
  }

  Future<void> _saveLocally() async {
    try {
      _processing = true;
      final localStorage = Provider.of<LocalStorage>(context, listen: false);
      final Map<String,dynamic> values = {
        "title": _titleController.text,
        "description": _descriptionController.text,
        "type": activityType,
      };
      if (widget.data['filename']!=null) {
        await localStorage.overwriteFile(widget.data['filename'],values);
      } else {
        debugPrint('File name is missing from json');
      }
      _processing = false;
    } catch (e) {
      debugPrint('$e');
      _processing = false;
    }
  }

  Future<void> _deleteActivity() async {
    try {
      _processing = true;
      final localStorage = Provider.of<LocalStorage>(context, listen: false);
      if (widget.data['filename']!=null) {
        await localStorage.deleteFile(widget.data['filename']);
      } else {
        debugPrint('File name is missing from json');
      }
    } catch (e) {
      debugPrint('$e');
      _processing = false;
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
            title: Text(AppLocalizations.of(context)!.warningLabel,style:TextStyle(color:Colors.black)),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(AppLocalizations.of(context)!.unsavedChangesWarningMessage),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(AppLocalizations.of(context)!.acceptOptionLabel),
                onPressed: () {
                  Navigator.pop(context,true);
                  Navigator.pop(context,true);
                },
              ),
              TextButton(
                child: Text(AppLocalizations.of(context)!.declineOptionLabel),
                onPressed: () {
                  Navigator.pop(context,false);
                },
              ),
            ],
          );
        }
    );
  }

  Future<void> _deletePopup() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.warningLabel,style:TextStyle(color:Colors.black)),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(AppLocalizations.of(context)!.activityDeletionMessage),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(AppLocalizations.of(context)!.acceptOptionLabel),
                onPressed: () {
                  _deleteActivity();
                  Navigator.pushNamedAndRemoveUntil(context,"/home", (_) => false);
                },
              ),
              TextButton(
                child: Text(AppLocalizations.of(context)!.declineOptionLabel),
                onPressed: () {
                  Navigator.pop(context,false);
                },
              ),
            ],
          );
        }
    );
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
      if (mounted) _displaySnackbar(AppLocalizations.of(context)!.genericErrorMessage);
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
        title: Text(AppLocalizations.of(context)!.resultPageTitle),
        actions: [
          _buildSaveLocallyButton(),
        ],
      ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildMap(),
              const SizedBox(height: 20),
              _buildStats(),
              const SizedBox(height: 30),
              _buildTypeField(),
              const SizedBox(height: 16),
              _buildTitleField(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 30),
              _buildUploadPictureRow(),
              const SizedBox(height: 45),
              _buildControlRow(),
            ],
          ),
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

  Widget _buildTypeField() {
    return DropdownButtonFormField<String>(
      initialValue: activityType,
      dropdownColor: Theme.of(context).cardTheme.color,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.activityTypeLabel,
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.sports,color: Theme.of(context).iconTheme.color),
      ),
      items: activityIcons.keys.map((key) {
        return DropdownMenuItem(
          value: key,
          child: Row(
            children: [
              Icon(activityIcons[key]),
              const SizedBox(width: 10),
              Text(activityLabels[key] ?? key,style:TextStyle(color:Theme.of(context).inputDecorationTheme.hintStyle!.color)),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        _hasUnsavedChanges = true;
        setState(() => activityType = value!);
      },
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      onChanged: (_) => _hasUnsavedChanges = true,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.titleLabel,
        hintText: AppLocalizations.of(context)!.exampleTitleHintLabel,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      onChanged: (_) => _hasUnsavedChanges = true,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: "${AppLocalizations.of(context)!.descriptionLabel} (${AppLocalizations.of(context)!.optionalLabel})",
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildPicturePicker() {
    return ElevatedButton(
      onPressed: () async {
        XFile? newImage = await picker.pickImage(source: ImageSource.gallery);
        if (newImage!=null) {
          image = newImage;
          _hasUnsavedChanges = true;
          setState(() {
            imageName = image?.name;
          });
        }
      },
      child: Text(AppLocalizations.of(context)!.uploadPictureButtonLabel),
    );
  }

  Widget _buildUploadPictureRow() {
    return Row(
      children: [
        Expanded(flex:2,child: _buildPicturePicker()),
        SizedBox(width:20),
        Expanded(child:Text(imageName==null ? "" : imageName!, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildSaveLocallyButton() {
    return IconButton(
      onPressed: () async {
        if (!_processing) {
          await _saveLocally();
          if (mounted) Navigator.pop(context);
        }
      },
      iconSize: 32,
      icon: Icon(Icons.save),
    );
  }

  Widget _buildDeleteButton() {
    return IconButton(
      onPressed: () async {
        if (!_processing) _deletePopup();
      },
      iconSize: 32,
      icon: Icon(Icons.delete_rounded),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: () async {
        if (offlineMode) {
          _displaySnackbar(AppLocalizations.of(context)!.offlineModePageBlockedMessage);
        } else {
          if (!_processing) {
            await _saveActivity();
            if (mounted) Navigator.pop(context);
          }
        }
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(AppLocalizations.of(context)!.submitLabel),
    );
  }

  Widget _buildControlRow() {
    return Row(
      children: [
        Expanded(
          child: _buildDeleteButton(),
        ),
        Expanded(
          flex: 2,
          child: SizedBox(),
        ),
        Expanded(
          flex: 2,
          child: _buildSubmitButton(),
        ),
      ],
    );
  }
}