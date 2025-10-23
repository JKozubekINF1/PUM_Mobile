import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final String baseUrl = 'https://localhost:7123';
  final FlutterSecureStorage _storage;
  final http.Client _client;

  ApiService({
    FlutterSecureStorage? storage,
    http.Client? client,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders({bool requiresAuth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (requiresAuth) {
      final token = await _storage.read(key: 'token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        throw Exception('No token error');
      }
    }
    return headers;
  }

  Future<Map<String, dynamic>> register(
      String email, String password, String confirmPassword) async {
    final url = Uri.parse('$baseUrl/api/Auth/register');
    try {
      final response = await _client.post(
        url,
        headers: await _getHeaders(),
        body: json.encode({
          'Email': email,
          'Password': password,
          'ConfirmPassword': confirmPassword,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorBody['message'] ?? 'Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/Auth/login');
    try {
      final response = await _client.post(
        url,
        headers: await _getHeaders(),
        body: json.encode({
          'Email': email,
          'Password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(utf8.decode(response.bodyBytes));
        final token = responseBody['token'];
        if (token != null) {
          await _storage.write(key: 'token', value: token);
          await _storage.write(key: 'email', value: email);
        }
        return responseBody;
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorBody['message'] ?? '${response.statusCode}');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<String?> getUsername() async {
    return await _storage.read(key: 'email');
  }
}