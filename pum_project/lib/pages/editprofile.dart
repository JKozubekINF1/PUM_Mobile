import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_connection.dart';
import '../models/profile_data.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/auth_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late Future<ProfileData> _profileFuture;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _avatarUrlController = TextEditingController();

  String? _gender;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile().then((profile) {
      _initializeControllers(profile);
      return profile;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _avatarUrlController.dispose();
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
    _firstNameController.text = profile.firstName ?? '';
    _lastNameController.text = profile.lastName ?? '';
    _heightController.text = profile.height?.toString() ?? '';
    _weightController.text = profile.weight?.toString() ?? '';
    _avatarUrlController.text = profile.avatarUrl ?? '';
    _gender = profile.gender;
    _dateOfBirth = profile.dateOfBirth;
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {});

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final updatedProfile = ProfileData(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        height: double.tryParse(_heightController.text.trim()),
        weight: double.tryParse(_weightController.text.trim()),
        avatarUrl: _avatarUrlController.text.trim(),
        gender: _gender,
        dateOfBirth: _dateOfBirth,
      );

      await apiService.updateProfile(updatedProfile);

      if (mounted) _displaySnackbar(AppLocalizations.of(context)!.profileUpdateSuccessfulMessage);

    } catch (e) {
      if (mounted) _displaySnackbar('${AppLocalizations.of(context)!.profileUpdateFailedMessage}. ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      setState(() {
        _profileFuture = _loadProfile();
      });
    }
  }

  void _displaySnackbar(String message) {
    var snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      _displaySnackbar(AppLocalizations.of(context)!.logoutSuccessfulMessage);
      Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
    }
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
                onPressed: () {
                  _logout();
                },
              ),
              TextButton(
                child: Text(AppLocalizations.of(context)!.declineOptionLabel),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profilePageTitle),
        actions: [
          _buildLogoutButton(),
        ],
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
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email: ${snapshot.data!.email ?? 'N/A'}'),
                    const SizedBox(height: 20),
                    _buildOptionsColumn(),
                    const SizedBox(height: 30),
                    Center(
                      child: _buildSubmitButton(),
                    ),
                  ],
                ),
              ),
            );
          }
          return Center(child: Text(AppLocalizations.of(context)!.genericErrorMessage));
        },
      ),
    );
  }

  Widget _buildOptionsColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildTextField(_firstNameController, AppLocalizations.of(context)!.profileFirstNameLabel, false),
        const SizedBox(height: 10),
        _buildTextField(_lastNameController, AppLocalizations.of(context)!.profileLastNameLabel, false),
        const SizedBox(height: 10),
        _buildGenderPicker(),
        const SizedBox(height: 10),
        _buildDatePicker(context),
        const SizedBox(height: 10),
        _buildTextField(_heightController, AppLocalizations.of(context)!.profileHeightLabel, true),
        const SizedBox(height: 10),
        _buildTextField(_weightController, AppLocalizations.of(context)!.profileWeightLabel, true),
        const SizedBox(height: 10),
        _buildTextField(_avatarUrlController, AppLocalizations.of(context)!.profileAvatarLabel, false),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, bool isNumeric) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
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
    return ListTile(
      title: Text(
        style: Theme.of(context).textTheme.bodyMedium,
        _dateOfBirth == null
            ? '${AppLocalizations.of(context)!.profileDayOfBirthLabel} (${AppLocalizations.of(context)!.optionalLabel})'
            : '${AppLocalizations.of(context)!.profileDayOfBirthLabel}: ${_dateOfBirth!.toLocal().toIso8601String().split('T')[0]}',
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          _setDate(picked);
        }
      },
    );
  }

  Widget _buildGenderPicker() {
    return DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText:
            '${AppLocalizations.of(context)!.profileGenderLabel} (${AppLocalizations.of(context)!.optionalLabel})',
          border: OutlineInputBorder(),
        ),
        initialValue: _gender,
        onChanged: (String? newValue) {
          setState(() {
            _gender = newValue;
          });
        },
        items: <String>[
          AppLocalizations.of(context)!.profileGenderMaleLabel,
          AppLocalizations.of(context)!.profileGenderFemaleLabel,
          AppLocalizations.of(context)!.profileGenderOtherLabel,
        ].map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _updateProfile,
      child: Text(AppLocalizations.of(context)!.saveChangesLabel),
    );
  }

  Widget _buildLogoutButton() {
    return TextButton(
        onPressed: _logoutPopupWindow,
        child: Text('Logout')
    );
  }
}