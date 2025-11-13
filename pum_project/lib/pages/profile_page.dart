import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_connection.dart';
import '../models/profile_data.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
    _profileFuture = _loadProfile();
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil zaktualizowany pomyślnie!')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd aktualizacji: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      setState(() {
        _profileFuture = _loadProfile();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mój Profil'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<ProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Wystąpił błąd: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            if (_firstNameController.text.isEmpty && _gender == null) {
              _initializeControllers(snapshot.data!);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email: ${snapshot.data!.email ?? 'N/A'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    _buildTextField(_firstNameController, 'Imię', false),
                    _buildTextField(_lastNameController, 'Nazwisko', false),
                    _buildGenderPicker(),
                    _buildDatePicker(context),
                    _buildTextField(_heightController, 'Wzrost (cm)', true),
                    _buildTextField(_weightController, 'Waga (kg)', true),
                    _buildTextField(_avatarUrlController, 'URL Awatara', false),

                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        child: const Text('Zapisz zmiany'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const Center(child: Text('Brak danych profilu.'));
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, bool isNumeric) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (isNumeric && value!.isNotEmpty && double.tryParse(value) == null) {
            return 'Wprowadź prawidłową liczbę.';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(
          _dateOfBirth == null
              ? 'Data Urodzenia (opcjonalnie)'
              : 'Data Urodzenia: ${_dateOfBirth!.toLocal().toIso8601String().split('T')[0]}',
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
            setState(() {
              _dateOfBirth = picked;
            });
          }
        },
      ),
    );
  }

  Widget _buildGenderPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Płeć (opcjonalnie)',
          border: OutlineInputBorder(),
        ),
        value: _gender,
        onChanged: (String? newValue) {
          setState(() {
            _gender = newValue;
          });
        },
        items: <String>['Male', 'Female', 'Other']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }
}