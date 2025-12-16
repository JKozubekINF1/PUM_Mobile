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
  String _height = "-";
  String _weight = "-";
  String _avatarUrl = "";
  String _gender = "-";
  String _dateOfBirth = "-";

  double _totalDistance = 0.0;
  int _totalActivities = 0;
  double _totalDuration = 0.0;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile().then((profile) {
      _initializeProfile(profile);
      return profile;
    });
  }

  void _initializeProfile(ProfileData profile) {
    _userName = profile.userName ?? "";
    _firstName = profile.firstName ?? "";
    _lastName = profile.lastName ?? "";
    _height = profile.height?.toString() ?? "-";
    _weight = profile.weight?.toString() ?? "-";
    _avatarUrl = profile.avatarUrl ?? "";
    _gender = profile.gender ?? "-";

    if (profile.dateOfBirth != null) {
      _dateOfBirth = DateFormat('dd/MM/yyyy').format(profile.dateOfBirth!);
    }

    _totalDistance = profile.totalDistanceKm;
    _totalActivities = profile.totalActivities;
    _totalDuration = profile.totalDurationSeconds;
  }

  String _formatDuration(double seconds) {
    int totalSeconds = seconds.toInt();
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  String _getLocalizedGender(BuildContext context, String rawGender) {
    final loc = AppLocalizations.of(context);
    if (loc == null) return rawGender;

    switch (rawGender) {
      case "Male":
        return loc.profileGenderMaleLabel;
      case "Female":
        return loc.profileGenderFemaleLabel;
      case "Other":
        return loc.profileGenderOtherLabel;
      default:
        return rawGender == "-" ? rawGender : rawGender;
    }
  }

  Future<ProfileData> _loadProfile() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    return apiService.fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profilePageTitle),
        elevation: 0,
        actions: [
          _buildEditButton(theme),
        ],
      ),
      body: FutureBuilder<ProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.noConnectionMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor),
              ),
            );
          }
          if (snapshot.hasData) {
            return SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildHeaderSection(context, theme, textColor),
                      const SizedBox(height: 30),
                      _buildStatisticsSection(context, theme, textColor),
                      const SizedBox(height: 30),
                      _buildDetailsSection(context, theme, textColor),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          }
          return Center(
            child: Text(
              AppLocalizations.of(context)!.genericErrorMessage,
              style: TextStyle(color: textColor),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(
      BuildContext context, ThemeData theme, Color textColor) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color:
                    theme.appBarTheme.backgroundColor ?? theme.primaryColor,
                    width: 3),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: ClipOval(
                child: _avatarUrl.isNotEmpty
                    ? Image.network(
                  _avatarUrl,
                  width: 140,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _buildPlaceholderAvatar(theme),
                )
                    : _buildPlaceholderAvatar(theme),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_userName.isNotEmpty)
          Text(
            _userName,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 32),
          ),
        if (_firstName.isNotEmpty || _lastName.isNotEmpty)
          Text(
            "$_firstName $_lastName".trim(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 20,
              color: textColor.withOpacity(0.8),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholderAvatar(ThemeData theme) {
    return Container(
      width: 140,
      height: 140,
      color: theme.cardTheme.color ?? Colors.grey,
      child: Icon(Icons.person, size: 80, color: theme.iconTheme.color),
    );
  }

  Widget _buildStatisticsSection(
      BuildContext context, ThemeData theme, Color textColor) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            theme: theme,
            icon: Icons.directions_run,
            value: "${_totalDistance.toStringAsFixed(1)} km",
            label: loc.profileStatsDistance,
            textColor: textColor,
          ),
          _buildVerticalDivider(textColor),
          _buildStatItem(
            context,
            theme: theme,
            icon: Icons.timer,
            value: _formatDuration(_totalDuration),
            label: loc.profileStatsTime,
            textColor: textColor,
          ),
          _buildVerticalDivider(textColor),
          _buildStatItem(
            context,
            theme: theme,
            icon: Icons.local_fire_department,
            value: "$_totalActivities",
            label: loc.profileStatsActivities,
            textColor: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(Color color) {
    return Container(height: 40, width: 1, color: color.withOpacity(0.3));
  }

  Widget _buildStatItem(
      BuildContext context, {
        required ThemeData theme,
        required IconData icon,
        required String value,
        required String label,
        required Color textColor,
      }) {
    final iconColor = theme.iconTheme.color ?? textColor;

    return Column(
      children: [
        Icon(icon, color: iconColor, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(
      BuildContext context, ThemeData theme, Color textColor) {
    final loc = AppLocalizations.of(context)!;

    final tileBackgroundColor = theme.scaffoldBackgroundColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 10),
          child: Text(
            loc.profileDetailsLabel,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
          ),
        ),
        Card(
          elevation: 4,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              _buildDetailTile(theme, Icons.wc, loc.profileGenderLabel,
                  _getLocalizedGender(context, _gender), textColor, tileBackgroundColor),
              _buildDivider(textColor),
              _buildDetailTile(theme, Icons.cake, loc.profileDayOfBirthLabel,
                  _dateOfBirth, textColor, tileBackgroundColor),
              _buildDivider(textColor),
              _buildDetailTile(theme, Icons.height, loc.profileHeightLabel,
                  "$_height cm", textColor, tileBackgroundColor),
              _buildDivider(textColor),
              _buildDetailTile(theme, Icons.monitor_weight,
                  loc.profileWeightLabel, "$_weight kg", textColor, tileBackgroundColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailTile(ThemeData theme, IconData icon, String title,
      String value, Color textColor, Color backgroundColor) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.iconTheme.color),
      ),
      title: Text(title,
          style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7))),
      trailing: Text(value,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
    );
  }

  Widget _buildDivider(Color color) {
    return Divider(
        height: 1, indent: 70, endIndent: 20, color: color.withOpacity(0.2));
  }

  Widget _buildEditButton(ThemeData theme) {
    return IconButton(
      icon: const Icon(Icons.edit),
      onPressed: () => Navigator.pushNamed(context, '/profile/edit'),
    );
  }
}