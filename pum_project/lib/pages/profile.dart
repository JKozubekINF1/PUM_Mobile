import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/profile_data.dart';
import '../services/api_connection.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<ProfileData> _profileFuture;

  String? _firstName;
  String? _lastName;
  double? _height;
  double? _weight;
  String? _avatarUrl;
  String? _gender;
  DateTime? _dateOfBirth;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile().then((profile) {
      _initializeProfile(profile);
      return profile;
    });
  }

  void _initializeProfile(ProfileData profile) {
    _firstName = profile.firstName ?? '';
    _lastName = profile.lastName ?? '';
    _height = profile.height ?? 0;
    _weight = profile.weight ?? 0;
    _avatarUrl = profile.avatarUrl ?? '';
    _gender = profile.gender ?? '';
    _dateOfBirth = profile.dateOfBirth ?? DateTime(2000,1,1);
  }

  Future<ProfileData> _loadProfile() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    return apiService.fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profilePageTitle),
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
              child: Column(
                children: [
                  _buildProfileHeader(),
                  _buildProfileInfo(),
                  _buildEditButton(),
                ],
              ),
            );
          }
          return Center(child: Text(AppLocalizations.of(context)!.genericErrorMessage));
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Text(_avatarUrl!),
        Text('Name: ${_firstName!} ${_lastName!}'),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        Text('Gender: $_gender'),
        Text('Date of birth: ${_dateOfBirth!.toString()}'),
        Text('Height: ${_height!.toString()}'),
        Text('Weight: ${_weight!.toString()}'),
      ],
    );
  }

  Widget _buildEditButton() {
    return ElevatedButton(
        onPressed: () => Navigator.pushNamed(context,'/profile/edit'),
        child: Text('Edit')
    );
  }
}