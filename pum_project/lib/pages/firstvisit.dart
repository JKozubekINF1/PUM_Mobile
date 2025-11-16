import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/profile_data.dart';
import 'package:pum_project/services/api_connection.dart';

class FirstVisitPage extends StatefulWidget {
  const FirstVisitPage({
    super.key,
  });
  @override
  State<FirstVisitPage> createState() => _FirstVisitPageState();
}

class _FirstVisitPageState extends State<FirstVisitPage> {
  Future<void> _offlineMode() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.warningLabel),
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
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Navigator.pushReplacementNamed(
                    context,
                    '/home',
                  );
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
  void initState() {
    super.initState();
  }

  bool _profileInitializationRequirement(ProfileData profile) {
    return (profile.firstName=='');
  }

  Future<void> _checkIfProfileInitialized() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final profile = await apiService.fetchProfile();
      final initialized = _profileInitializationRequirement(profile);

      if (initialized) {
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      } else {
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/profile/edit', (_) => false);
      }
    } catch (e) {
      debugPrint("$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
        builder: (context, auth, child) {
          if (!auth.isLoading && auth.showLoginSuccess) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              auth.clearLoginSuccess();
              _checkIfProfileInitialized();
            });
          }
          return Scaffold(
            body: Column(
              children: [
                Flexible(
                  flex: 1,
                  child: _buildLogo(),
                ),
                Flexible(
                  flex: 1,
                  child: _buildTextPadding(),
                ),
                Flexible(
                  flex: 2,
                  child: Container(
                    child: _buildButtonCollumn(),
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Container(
                    child: _buildOfflineModeText(),
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

  Widget _buildLogo() {
    return Align(
      alignment: Alignment.center,
      child: Text(
        "LOGO", style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildTextPadding() {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          Flexible(
            flex: 2,
            child: SizedBox(
              child: _buildWelcomeTitle(),
            ),
          ),
          Flexible(
            flex: 1,
            child: SizedBox(
              child: _buildWelcomeText(),
            ),
          ),
        ]
      ),
    );
  }

  Widget _buildButtonCollumn() {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 20,
        children: [
          Flexible(
            flex: 2,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: _buildLoginButton(),
            ),
          ),
          Flexible(
            flex: 2,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: _buildRegisterButton(),
            ),
          ),
        ]
    );
  }

  Widget _buildWelcomeTitle() {
    return Align(
      alignment: Alignment.center,
      child: Text(
        AppLocalizations.of(context)!.firstVisitPageTitle, style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Align(
      alignment: Alignment.center,
      child: Text(
        AppLocalizations.of(context)!.welcomeNewUserMessage, style: TextStyle(color: Color(0xFF375534)),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      child: Text(AppLocalizations.of(context)!.loginButtonLabel),
      onPressed: () {
        Navigator.pushNamed(
          context,
          '/login',
        );
      },
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      child: Text(AppLocalizations.of(context)!.registerButtonLabel),
      onPressed: () {
        Navigator.pushNamed(
          context,
          '/register',
        );
      },
    );
  }

  Widget _buildOfflineModeText() {
    return Align(
      alignment: Alignment.center,
      child: TextButton(
        onPressed: () {
          _offlineMode();
        },
        child: Text(
            AppLocalizations.of(context)!.offlineModeTextLabel, style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}