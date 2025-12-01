import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:pum_project/main.dart';
import '../services/app_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
  });
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _language;
  String? _theme;

  @override
  void initState() {
    _getSettings();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _getSettings() async {
    try {
      final appSettings = Provider.of<AppSettings>(context, listen: false);
      final settings = await appSettings.getSettings();
      if (mounted) {
        setState(() {
          _language = settings?["language"];
          _theme = settings?["theme"];
        });
      }
    } catch (e) {
      if (mounted) _displaySnackbar(AppLocalizations.of(context)!.genericErrorMessage);
      debugPrint('$e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final appSettings = Provider.of<AppSettings>(context, listen: false);
      await appSettings.saveSettings(
        language: _language.toString(),
        theme: _theme.toString(),
      );
    } catch (e) {
      if (mounted) _displaySnackbar(AppLocalizations.of(context)!.appSettingsSaveFailedMessage);
      debugPrint('$e');
    }
  }

  void _displaySnackbar(String message) {
    var snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsPageTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _buildLanguageSetting(),
            _buildThemeSetting(),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSetting() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 100,
            child: Text(AppLocalizations.of(context)!.settingsLanguageLabel),
          ),
        ),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 100,
            child: _buildLanguageField(),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSetting() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 100,
            child: Text(AppLocalizations.of(context)!.settingsThemeLabel),
          ),
        ),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 100,
            child: _buildThemeFormField(),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageField() {
    final englishLanguage = {
      'value': 'en',
      'name': 'English',
    };

    final polishLanguage = {
      'value': 'pl',
      'name': 'Polski',
    };

    final languageList = [
      englishLanguage,
      polishLanguage,
    ];

    return DropdownButtonFormField<String>(
      initialValue: _language,
      onChanged: (String? newValue) {
        setState(() {
          _language = newValue;
          MyApp.setLocale(context, Locale(newValue.toString()));
          _saveSettings();
        });
      },
      items: languageList.map<DropdownMenuItem<String>>((lang) {
        return DropdownMenuItem<String>(
          value: lang['value'],
          child: Text(lang['name']!),
        );
      }).toList(),
    );
  }

  Widget _buildThemeFormField() {
    final lightTheme = {
      'value': 'light',
      'name': 'Light Theme',
    };

    final testTheme = {
      'value': 'test',
      'name': 'Test Theme',
    };

    final themeList = [
      lightTheme,
      testTheme,
    ];

    return DropdownButtonFormField<String>(
      initialValue: _theme,
      onChanged: (String? newValue) {
        setState(() {
          _theme = newValue;
          MyApp.setTheme(context, newValue!);
          _saveSettings();
        });
      },
      items: themeList.map<DropdownMenuItem<String>>((theme) {
        return DropdownMenuItem<String>(
          value: theme['value'],
          child: Text(theme['name']!),
        );
      }).toList(),
    );
  }
}