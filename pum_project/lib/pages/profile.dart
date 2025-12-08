import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/profile_data.dart';
import '../services/api_connection.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<ProfileData> _profileFuture;

  String _userName = "";
  String _firstName = "";
  String _lastName = "";
  String _height = "";
  String _weight = "";
  String _avatarUrl = "";
  String _gender = "";
  String _dateOfBirth = "";

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _initializeProfile(ProfileData profile) {
    if (profile.userName != null) {
      _userName = profile.userName!;
    }
    if (profile.firstName != null) {
      _firstName = profile.firstName!;
    }
    if (profile.lastName != null) {
      _lastName = profile.lastName!;
    }
    if (profile.height != null) {
      _height = (profile.height!).toString();
    }
    if (profile.weight != null) {
      _weight = (profile.weight!).toString();
    }
    if (profile.avatarUrl != null) {
      _avatarUrl = profile.avatarUrl!;
    }
    if (profile.gender != null) {
      switch (profile.gender) {
        case "Male":
          _gender = AppLocalizations.of(context)!.profileGenderMaleLabel;
          break;
        case "Female":
          _gender = AppLocalizations.of(context)!.profileGenderFemaleLabel;
          break;
        case "Other":
          _gender = AppLocalizations.of(context)!.profileGenderOtherLabel;
          break;
        default:
          _gender = profile.gender!;
          break;
      }
    }
    if (profile.dateOfBirth != null) {
      _dateOfBirth = DateFormat('dd/MM/yyyy').format(profile.dateOfBirth!);
    }
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
        actions: [
          _buildEditButton(),
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
            return Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 450,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).appBarTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 35),
                      _buildProfileHeader(),
                      const SizedBox(height: 20),
                      _buildProfileInfo(),
                      const SizedBox(height: 35),
                    ],
                  ),
                ),
              ),
            );
          }
          return Center(child: Text(AppLocalizations.of(context)!.genericErrorMessage));
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Text(
          _userName,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 38,
            color: Theme.of(context).appBarTheme.foregroundColor as Color,
          ),
        ),
        const SizedBox(height: 10),
        _buildProfilePicture(),
        const SizedBox(height: 10),
        Text(
          _firstName,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 32,
            color: Theme.of(context).appBarTheme.foregroundColor as Color,
          ),
        ),
        Text(
          _lastName,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 32,
            color: Theme.of(context).appBarTheme.foregroundColor as Color,
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePicture() {
    if (_avatarUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          _avatarUrl,
          width: 200,
          height: 200,
          fit: BoxFit.cover,

          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox(
              width: 200,
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          },

          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.account_circle_rounded,
              size: 200,
              color: Colors.grey,
            );
          },
        ),
      );
    }

    return const Icon(
      Icons.account_circle_rounded,
      size: 200,
      color: Colors.grey,
    );
  }

  Widget _buildProfileInfo() {
    return Card(
      color: Theme.of(context).cardTheme.color,
      shape: BeveledRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(AppLocalizations.of(context)!.profileDetailsLabel,
                style: const TextStyle(fontSize: 42)),
            const SizedBox(height: 14),
            Text('${AppLocalizations.of(context)!.profileGenderLabel}: $_gender'),
            Text('${AppLocalizations.of(context)!.profileDayOfBirthLabel}: $_dateOfBirth'),
            Text('${AppLocalizations.of(context)!.profileHeightLabel}: $_height'),
            Text('${AppLocalizations.of(context)!.profileWeightLabel}: $_weight'),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton() {
    return IconButton(
      icon: const Icon(Icons.edit),
      iconSize: 35,
      onPressed: () => Navigator.pushNamed(context, '/profile/edit'),
    );
  }
}