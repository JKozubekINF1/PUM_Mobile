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
            title: Text(AppLocalizations.of(context)!.warningLabel,style:TextStyle(color:Colors.black)),
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
        }
    );
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    return (profile.firstName=='' || profile.firstName==null);
  }

  Future<void> _checkIfProfileInitialized() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final profile = await apiService.fetchProfile();
      if (profile.userName!=null) {
        final notInitialized = await _profileInitializationRequirement(profile);

        if (notInitialized) {
          if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/profile/edit', (_) => false, arguments: {'forcedEntry':true});
        } else {
          if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
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
          child: Image.asset("assets/logo.png"),
        ),
      );
    }

    return Consumer<AuthProvider>(
        builder: (context, auth, child) {
          return Scaffold(
            appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                actions: [
                  _buildSettingsIcon(),
                ],
            ),
            backgroundColor: const Color(0xff01bafd),
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
                  flex: 1,
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
      child: Image(
        image: AssetImage("assets/logo.png"),
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
        AppLocalizations.of(context)!.firstVisitPageTitle, style: TextStyle(color: Color(0xFFFFFFFF), fontSize:72),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Align(
      alignment: Alignment.center,
      child: Text(
        AppLocalizations.of(context)!.welcomeNewUserMessage, style: TextStyle(color: Color(0xFFFFFFFF)),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey,
      ),
      child: Text(AppLocalizations.of(context)!.loginButtonLabel, style: TextStyle(color: Color(0xFFFFFFFF))),
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
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey,
      ),
      child: Text(AppLocalizations.of(context)!.registerButtonLabel, style: TextStyle(color: Color(0xFFFFFFFF))),
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
            AppLocalizations.of(context)!.offlineModeTextLabel, style: TextStyle(color: Color(0xFFFFFFFF), fontSize:24),
        ),
      ),
    );
  }

  Widget _buildSettingsIcon() {
    return IconButton(
      icon: Icon(Icons.settings),
      iconSize: 45,
      color: Colors.white,
      onPressed: () {
        Navigator.pushNamed(context,"/settings");
      },
    );
  }
}