import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_connection.dart';
import '../models/profile_data.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/auth_provider.dart';

class EditProfilePage extends StatefulWidget {
  final bool forcedEntry;
  const EditProfilePage({super.key, this.forcedEntry = false});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late Future<ProfileData> _profileFuture;
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final ImagePicker picker = ImagePicker();
  XFile? image;
  String? filename = "";
  String? _gender;
  DateTime? _dateOfBirth;
  bool _hasUnsavedChanges = false;
  late bool _forcedEntry;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _forcedEntry = widget.forcedEntry;
    _profileFuture = _loadProfile().then((profile) {
      _initializeControllers(profile);
      return profile;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['forcedEntry'] == true) {
        setState(() {
          _forcedEntry = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _setDate(DateTime date) {
    if (mounted) {
      setState(() {
        _dateOfBirth = date;
      });
    }
  }

  Future<ProfileData> _loadProfile() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    return apiService.fetchProfile();
  }

  void _initializeControllers(ProfileData profile) {
    _userNameController.text = profile.userName ?? '';
    _firstNameController.text = profile.firstName ?? '';
    _lastNameController.text = profile.lastName ?? '';
    _heightController.text = profile.height?.toString() ?? '';
    _weightController.text = profile.weight?.toString() ?? '';
    _currentAvatarUrl = profile.avatarUrl;

    const validGenders = {'Male', 'Female', 'Other'};
    _gender = validGenders.contains(profile.gender) ? profile.gender : null;

    _dateOfBirth = profile.dateOfBirth;
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final updatedProfile = ProfileData(
        userName: _userNameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        height: double.tryParse(_heightController.text.trim()),
        weight: double.tryParse(_weightController.text.trim()),
        gender: _gender,
        dateOfBirth: _dateOfBirth,
      );

      await apiService.updateProfile(updatedProfile);

      if (mounted) {
        _displaySnackbar(AppLocalizations.of(context)!.profileUpdateSuccessfulMessage);
        Navigator.pushNamedAndRemoveUntil(context, "/home", (_) => false);
        Navigator.pushNamed(context, "/profile");
      }
    } catch (e) {
      if (mounted) {
        _displaySnackbar(
            '${AppLocalizations.of(context)!.profileUpdateFailedMessage}. ${_formatError(e.toString())}');
      }
    } finally {
      setState(() {
        _profileFuture = _loadProfile();
      });
    }
  }

  Future<void> uploadProfilePicture() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      await apiService.uploadAvatar(imageFile: image!);
    } catch (e) {
      debugPrint("$e");
    }
  }

  String _formatError(String raw) {
    final msg = raw.replaceFirst('Exception: ', '').toLowerCase();
    if (msg.contains('nick jest już zajęty')) {
      return AppLocalizations.of(context)!.nicknameTakenMessage;
    } else if (msg.contains('timeout')) {
      return AppLocalizations.of(context)!.noConnectionMessage;
    } else {
      return AppLocalizations.of(context)!.genericErrorMessage;
    }
  }

  void _displaySnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      _displaySnackbar(AppLocalizations.of(context)!.logoutSuccessfulMessage);
      Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
    }
  }

  Future<void> _leavePopup() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.warningLabel),
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
                  Navigator.pop(context, true);
                  Navigator.pop(context, true);
                },
              ),
              TextButton(
                child: Text(AppLocalizations.of(context)!.declineOptionLabel),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
            ],
          );
        });
  }

  Future<void> _logoutPopupWindow() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.warningLabel),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(AppLocalizations.of(context)!.logoutWarningMessage),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.acceptOptionLabel),
              onPressed: () => _logout(),
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.declineOptionLabel),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
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
          title: Text(AppLocalizations.of(context)!.editProfilePageTitle),
          actions: [if (_forcedEntry) _buildLogoutButton()],
        ),
        body: FutureBuilder<ProfileData>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            if (snapshot.hasData) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAvatarSection(context),
                      const SizedBox(height: 30),
                      Text(
                        AppLocalizations.of(context)!.profileDetailsLabel,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).iconTheme.color,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildOptionsColumn(),
                      const SizedBox(height: 40),
                      _buildSubmitButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            }
            return Center(child: Text(AppLocalizations.of(context)!.genericErrorMessage));
          },
        ),
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context) {
    ImageProvider? avatarImage;
    if (image != null) {
      avatarImage = FileImage(File(image!.path));
    } else if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty) {
      avatarImage = NetworkImage(_currentAvatarUrl!);
    }
    final borderColor = Theme.of(context).iconTheme.color ?? Theme.of(context).primaryColor;
    final buttonColor = Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor;

    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor.withOpacity(0.8),
                width: 3,
              ),
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).cardTheme.color ?? Colors.grey[200],
              backgroundImage: avatarImage,
              child: avatarImage == null
                  ? Icon(Icons.person, size: 60, color: Theme.of(context).iconTheme.color)
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 4,
            child: Material(
              color: buttonColor,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () async {
                  XFile? newImage = await picker.pickImage(source: ImageSource.gallery);
                  if (newImage != null) {
                    setState(() {
                      image = newImage;
                      filename = image?.name;
                      _hasUnsavedChanges = true;
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.camera_alt,
                      color: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
                      size: 20
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsColumn() {
    return Column(
      children: <Widget>[
        _buildTextField(_userNameController, AppLocalizations.of(context)!.profileNickNameLabel, false, Icons.person_outline),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField(_firstNameController, AppLocalizations.of(context)!.profileFirstNameLabel, false, Icons.badge_outlined)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField(_lastNameController, AppLocalizations.of(context)!.profileLastNameLabel, false, Icons.badge_outlined)),
          ],
        ),
        const SizedBox(height: 16),
        _buildGenderPicker(),
        const SizedBox(height: 16),
        _buildDatePicker(context),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField(_heightController, AppLocalizations.of(context)!.profileHeightLabel, true, Icons.height)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField(_weightController, AppLocalizations.of(context)!.profileWeightLabel, true, Icons.monitor_weight_outlined)),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, bool isNumeric, IconData icon) {
    return TextFormField(
      controller: controller,
      onChanged: (_) => _hasUnsavedChanges = true,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).iconTheme.color),
        filled: true,
        fillColor: Theme.of(context).cardTheme.color?.withOpacity(0.5),
      ),
      validator: (value) {
        if (isNumeric && value!.isNotEmpty && double.tryParse(value) == null) {
          return AppLocalizations.of(context)!.enterValidNumberMessage;
        }
        return null;
      },
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          _setDate(picked);
          _hasUnsavedChanges = true;
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '${AppLocalizations.of(context)!.profileDayOfBirthLabel} (${AppLocalizations.of(context)!.optionalLabel})',
          prefixIcon: Icon(Icons.calendar_today_outlined, color: Theme.of(context).iconTheme.color),
          filled: true,
          fillColor: Theme.of(context).cardTheme.color?.withOpacity(0.5),
        ),
        child: Text(
          _dateOfBirth == null
              ? ''
              : _dateOfBirth!.toLocal().toIso8601String().split('T')[0],
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildGenderPicker() {
    final l10n = AppLocalizations.of(context)!;
    final Map<String, String> genderOptions = {
      'Male': l10n.profileGenderMaleLabel,
      'Female': l10n.profileGenderFemaleLabel,
      'Other': l10n.profileGenderOtherLabel,
    };

    return DropdownButtonFormField<String>(
      initialValue: _gender,
      dropdownColor: Theme.of(context).cardTheme.color,
      icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).iconTheme.color),
      decoration: InputDecoration(
        labelText: '${l10n.profileGenderLabel} (${l10n.optionalLabel})',
        prefixIcon: Icon(Icons.wc, color: Theme.of(context).iconTheme.color),
        filled: true,
        fillColor: Theme.of(context).cardTheme.color?.withOpacity(0.5),
      ),
      onChanged: (String? newValue) {
        _hasUnsavedChanges = true;
        setState(() {
          _gender = newValue;
        });
      },
      items: genderOptions.entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.key,
          child: Text(entry.value, style: Theme.of(context).textTheme.bodyMedium),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (image != null) uploadProfilePicture();
          _updateProfile();
        },
        child: Text(
          AppLocalizations.of(context)!.saveChangesLabel,
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: AppLocalizations.of(context)!.logoutButtonLabel,
      onPressed: _logoutPopupWindow,
    );
  }
}