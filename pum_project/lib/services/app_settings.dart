import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class AppSettings {
  final FlutterSecureStorage _storage;

  AppSettings({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final Map defaultSettings = {
    "language" : "en",
    "theme" : "default",
  };

  Future<Map?> getSettings() async {
    final settings = await _storage.read(key: 'settings');
    if (settings == null) {
      return defaultSettings;
    }
    return jsonDecode(settings);
  }

  Future<void> saveSettings(
  {
    required String language,
    required String theme,
  }) async {
    String newSettings = '{"language":"$language","theme":"$theme"}';
    await _storage.write(key: 'settings', value: newSettings);
  }

  Future<void> setOfflineMode({
    required bool offline,
  }) async {
    final mode = offline ? 1 : 0;
    await _storage.write(key: 'offline_mode', value: mode.toString());
  }

  Future<bool?> checkOfflineMode() async {
    final mode = await _storage.read(key: 'offline_mode');
    if (mode == null) {
      return true;
    }
    return int.parse(mode) == 0 ? false : true;
  }
}