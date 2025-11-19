import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:pum_project/models/profile_data.dart';

class ApiService {
  final String baseUrl = 'https://localhost:7123'; //http://10.0.2.2:5123
  final FlutterSecureStorage _storage;
  final http.Client _client;

  ApiService({
    FlutterSecureStorage? storage,
    http.Client? client,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  Future<String?> getToken() async {
    final token = await _storage.read(key: 'token');
    debugPrint('[DEBUG AUTH] Token odczytany: ${token != null ? 'OK (długość: ${token.length})' : 'Brak'}');
    return token;
  }

  Future<void> clearAuthData() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'email');
    debugPrint('[DEBUG AUTH] Dane autoryzacyjne USUNIĘTE.');
  }

  Future<Map<String, String>> _getHeaders({bool requiresAuth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (requiresAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        throw Exception('Authorization required: No token found.');
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

      final responseBody = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Error during registration: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error during registration: $e');
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

      final responseBody = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        final token = responseBody['token'];
        if (token != null) {
          await _storage.write(key: 'token', value: token);
          await _storage.write(key: 'email', value: email);

          debugPrint('[DEBUG AUTH] Token ZAPISANY po loginie (długość: ${token.length})');
        }
        return responseBody;
      } else if (response.statusCode == 401) {
        throw Exception('Invalid credentials.');
      } else {
        throw Exception(responseBody['message'] ?? 'Login failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error during login: $e');
    }
  }

  Future<ProfileData> fetchProfile() async {
    final url = Uri.parse('$baseUrl/api/Profile');
    try {
      final response = await _client.get(
        url,
        headers: await _getHeaders(requiresAuth: true),
      );

      final responseBody = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return ProfileData.fromJson(responseBody);
      } else if (response.statusCode == 401) {
        await clearAuthData();
        throw Exception('Unauthorized. Token expired or invalid.');
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to fetch profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error during profile fetch: $e');
    }
  }

  Future<void> updateProfile(ProfileData profile) async {
    final url = Uri.parse('$baseUrl/api/Profile');
    try {
      final response = await _client.put(
        url,
        headers: await _getHeaders(requiresAuth: true),
        body: json.encode(profile.toJson()),
      );

      if (response.statusCode == 200) {
        debugPrint('[DEBUG API] Profile updated successfully.');
        return;
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        final responseBody = json.decode(utf8.decode(response.bodyBytes));
        if (response.statusCode == 401) await clearAuthData();
        throw Exception(
            responseBody['message'] ?? 'Validation or unauthorized failed.');
      } else {
        final responseBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(responseBody['message'] ??
            'Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error during profile update: $e');
    }
  }

  Future<void> logout() async {
    await clearAuthData();
  }


  Future<void> saveActivity({
    required int durationSeconds,
    required double distanceMeters,
    required double averageSpeedMs,
    double? maxSpeedMs,
    required List<List<double>> routeCoordinates,
    String title = 'Bez tytułu',
    String? description,
    String activityType = 'Running',
  }) async {
    final url = Uri.parse('$baseUrl/api/activities');

    final body = jsonEncode({
      "title": title,
      "description": description,
      "activityType": activityType,
      "durationSeconds": durationSeconds,
      "distanceMeters": distanceMeters,
      "averageSpeedMs": averageSpeedMs,
      "maxSpeedMs": maxSpeedMs,
      "route": routeCoordinates.length >= 2 ? routeCoordinates : null,
    });

    final response = await _client.post(
      url,
      headers: await _getHeaders(requiresAuth: true),
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('[API] Aktywność zapisana!');
      return;
    } else {
      final error = json.decode(utf8.decode(response.bodyBytes));
      throw Exception(error['message'] ?? 'Błąd ${response.statusCode}');
    }

  }
}