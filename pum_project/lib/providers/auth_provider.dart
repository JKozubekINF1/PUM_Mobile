import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _token;
  bool _isLoading = true;
  bool _showLoginSuccess = false;

  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  bool get showLoginSuccess => _showLoginSuccess;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'token');

    debugPrint('[DEBUG AUTH PROVIDER] Token wczytany przy starcie: ${_token != null ? 'TAK' : 'NIE'}');

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveToken(String token) async {
    _token = token;
    notifyListeners();
  }

  void markLoginSuccess() {
    _showLoginSuccess = true;
    notifyListeners();
  }

  void clearLoginSuccess() {
    _showLoginSuccess = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'email');
    _token = null;
    notifyListeners();
  }
}