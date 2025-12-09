import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:pum_project/main.dart';
import '../services/app_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _language;
  String? _theme;
  bool _isLoading = true;

  final List<Map<String, String>> _themeList = [
    {'value': 'default', 'name': 'Default'},
    {'value': 'dark', 'name': 'Midnight'},
    {'value': 'christmas', 'name': 'Jolly'},
    {'value': 'halloween', 'name': 'Spooky'},
  ];

  final List<Map<String, String>> _languageList = [
    {'value': 'en', 'name': 'English'},
    {'value': 'pl', 'name': 'Polski'},
  ];

  @override
  void initState() {
    super.initState();
    _getSettings();
  }

  Future<void> _getSettings() async {
    try {
      final appSettings = Provider.of<AppSettings>(context, listen: false);
      final settings = await appSettings.getSettings();

      if (mounted) {
        setState(() {
          _language = settings?["language"];
          _theme = settings?["theme"];

          final isThemeValid = _themeList.any((t) => t['value'] == _theme);
          if (!isThemeValid) {
            _theme = 'default';
          }

          final isLangValid = _languageList.any((l) => l['value'] == _language);
          if (!isLangValid) {
            _language = 'en';
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _displaySnackbar(AppLocalizations.of(context)!.genericErrorMessage);
        setState(() => _isLoading = false);
      }
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
      if (mounted) {
        _displaySnackbar(AppLocalizations.of(context)!.appSettingsSaveFailedMessage);
      }
      debugPrint('$e');
    }
  }

  void _displaySnackbar(String message) {
    var snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.settingsPageTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsPageTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            _buildSettingsCard(
              title: AppLocalizations.of(context)!.settingsLanguageLabel,
              icon: Icons.language,
              child: _buildLanguageField(),
            ),
            const SizedBox(height: 16),
            _buildSettingsCard(
              title: AppLocalizations.of(context)!.settingsThemeLabel,
              icon: Icons.palette,
              child: _buildThemeFormField(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required String title, required IconData icon, required Widget child}) {
    return Card(
      elevation: 4,
      color: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).iconTheme.color, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageField() {
    return DropdownButtonFormField<String>(
      value: _language,
      decoration: const InputDecoration(),
      dropdownColor: Theme.of(context).cardTheme.color,
      icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).iconTheme.color),
      style: Theme.of(context).textTheme.bodyMedium,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _language = newValue;
            MyApp.setLocale(context, Locale(newValue));
            _saveSettings();
          });
        }
      },
      items: _languageList.map<DropdownMenuItem<String>>((lang) {
        return DropdownMenuItem<String>(
          value: lang['value'],
          child: Text(
            lang['name']!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildThemeFormField() {
    return DropdownButtonFormField<String>(
      value: _theme,
      decoration: const InputDecoration(),
      dropdownColor: Theme.of(context).cardTheme.color,
      icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).iconTheme.color),
      style: Theme.of(context).textTheme.bodyMedium,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _theme = newValue;
            MyApp.setTheme(context, newValue);
            _saveSettings();
          });
        }
      },
      items: _themeList.map<DropdownMenuItem<String>>((theme) {
        return DropdownMenuItem<String>(
          value: theme['value'],
          child: Text(
            theme['name']!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }).toList(),
    );
  }
}