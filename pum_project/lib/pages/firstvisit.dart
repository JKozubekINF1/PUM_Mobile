import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:pum_project/models/profile_data.dart';
import 'package:pum_project/services/api_connection.dart';
import 'package:pum_project/services/app_settings.dart';

class FirstVisitPage extends StatefulWidget {
  const FirstVisitPage({
    super.key,
  });
  @override
  State<FirstVisitPage> createState() => _FirstVisitPageState();
}

class _FirstVisitPageState extends State<FirstVisitPage> {
  bool _loadingSettings = true;
  bool _loadingAccount = true;


  Future<void> _offlineMode() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.warningLabel,
                style: const TextStyle(color: Colors.black)),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(AppLocalizations.of(context)!.offlineModeWarningMessage),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(AppLocalizations.of(context)!.acceptOptionLabel),
                onPressed: () async {
                  await _setOfflineMode();
                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.pushReplacementNamed(
                      context,
                      '/home',
                    );
                  }
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
        });
  }

  Future<void> _setOfflineMode() async {
    try {
      final appSettings = Provider.of<AppSettings>(context, listen: false);
      await appSettings.setOfflineMode(offline: true);
    } catch (e) {
      debugPrint("$e");
    }
  }

  @override
  void initState() {
    super.initState();
    _checkOfflineMode();
    _checkIfProfileInitialized();
  }

  Future<void> _checkOfflineMode() async {
    try {
      final appSettings = Provider.of<AppSettings>(context, listen: false);
      final mode = await appSettings.checkOfflineMode();
      if (mode ?? false) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
        }
      }
    } catch (e) {
      debugPrint('$e');
    }
    if (mounted) {
      setState(() {
        _loadingSettings = false;
      });
    }
  }

  Future<bool> _profileInitializationRequirement(ProfileData profile) async {
    return (profile.firstName == '' || profile.firstName == null);
  }

  Future<void> _checkIfProfileInitialized() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final profile = await apiService.fetchProfile();
      if (profile.userName != null) {
        final notInitialized = await _profileInitializationRequirement(profile);

        if (notInitialized) {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/profile/edit', (_) => false,
                arguments: {'forcedEntry': true});
          }
        } else {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
          }
        }
      }
    } catch (e) {
      debugPrint("$e");
    }
    if (mounted) {
      setState(() {
        _loadingAccount = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_loadingAccount || _loadingSettings) {
      return Scaffold(
        backgroundColor: const Color(0xff01bafd),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Consumer<AuthProvider>(builder: (context, auth, child) {
      return Scaffold(
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  const Spacer(flex: 2),
                  _buildLogoAndTitle(),
                  const Spacer(flex: 3),
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                  _buildOfflineLink(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff00c6ff),
            Color(0xff0072ff),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.settings),
            iconSize: 32,
            color: Colors.white.withValues(alpha: 0.9),
            onPressed: () {
              Navigator.pushNamed(context, "/settings");
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoAndTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Image(
              image: AssetImage("assets/logo.png"),
              height: 100,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.firstVisitPageTitle.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              shadows: [
                Shadow(
                  offset: Offset(0, 2),
                  blurRadius: 4.0,
                  color: Color.fromRGBO(0, 0, 0, 0.25),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context)!.welcomeNewUserMessage,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xff0072ff),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.loginButtonLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white, width: 2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.registerButtonLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineLink() {
    return TextButton(
      onPressed: _offlineMode,
      child: Text(
        AppLocalizations.of(context)!.offlineModeTextLabel,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 16,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}