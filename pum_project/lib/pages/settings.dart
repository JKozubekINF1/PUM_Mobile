import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:pum_project/main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
  });
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _language;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _language ??= _getCurrentLanguage();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String? _getCurrentLanguage() {
    return MyApp.getLocale(context);
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
}