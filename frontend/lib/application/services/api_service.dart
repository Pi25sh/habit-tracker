import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static String? _cachedBaseUrl;

  // Configurable base URL - can be set via SharedPreferences or defaults
  static Future<String> get baseUrl async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;

    final prefs = await SharedPreferences.getInstance();
    String? customUrl = prefs.getString('api_base_url');

    if (customUrl != null && customUrl.isNotEmpty) {
      _cachedBaseUrl = customUrl;
      return _cachedBaseUrl!;
    }

    // Default URLs based on platform
    if (kReleaseMode) {
      _cachedBaseUrl = 'https://api.habit-tracker.example.com/api/v1';
    } else {
      if (defaultTargetPlatform == TargetPlatform.android) {
        _cachedBaseUrl = 'http://10.0.2.2:8010/api/v1';
      } else {
        _cachedBaseUrl = 'http://127.0.0.1:8010/api/v1';
      }
    }
    return _cachedBaseUrl!;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
    _cachedBaseUrl = url;
  }

  // --- Auth ---
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  static Future<Map<String, String>> _getAuthHeaders() async {
    String? accessToken = await getAccessToken();

    // Try to refresh if no access token
    accessToken ??= await _refreshAccessToken();

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${accessToken ?? ''}',
      'X-App-Version': '1.0.0',
    };
  }

  static Future<String?> _refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return null;

      final res = await http.post(
        Uri.parse('${await ApiService.baseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final newAccess = data['access_token'] as String;
        final newRefresh = data['refresh_token'] as String;
        await saveTokens(newAccess, newRefresh);
        return newAccess;
      } else {
        // Refresh failed, clear tokens
        await clearTokens();
        return null;
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      await clearTokens();
      return null;
    }
  }

  // --- Sync (for offline-first data) ---
  // Note: Frontend uses custom keys like 'habits', 'tasks', 'journal_entries', etc.
  // These are stored as JSON strings in the backend sync store.

  static Future<Map<String, dynamic>?> syncData(String key, String localValue, int lastUpdated) async {
    try {
      final headers = await _getAuthHeaders();

      // 1. Fetch remote data first
      final getRes = await http.get(
        Uri.parse('${await ApiService.baseUrl}/sync/$key'),
        headers: headers,
      ).timeout(const Duration(seconds: 5));

      if (getRes.statusCode == 200) {
        final remoteData = jsonDecode(getRes.body);
        final remoteUpdated = remoteData['updated_at'] as int;

        if (remoteUpdated > lastUpdated) {
          // Server has newer data, return it so the app can update its local storage
          return {
            'value': remoteData['value'],
            'updated_at': remoteUpdated,
          };
        }
      } else if (getRes.statusCode == 404) {
        // No remote data yet
      }

      // 2. If local is newer, push local to remote
      final postRes = await http.post(
        Uri.parse('${await ApiService.baseUrl}/sync/$key'),
        headers: headers,
        body: jsonEncode({
          'value': localValue,
          'updated_at': lastUpdated,
        }),
      ).timeout(const Duration(seconds: 5));

      if (kDebugMode) {
        print('Sync response for $key: ${postRes.body}');
      }
      return null; // indicates local is already up to date
    } catch (e) {
      if (kDebugMode) {
        print('Sync error for $key: $e');
      }
      return null; // Fail gracefully if offline
    }
  }

  // --- Habits API ---
  static Future<List<dynamic>> getHabits() async {
    try {
      final headers = await _getAuthHeaders();
      final res = await http.get(
        Uri.parse('${await ApiService.baseUrl}/habits'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('Get habits failed: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createHabit(Map<String, dynamic> habit) async {
    try {
      final headers = await _getAuthHeaders();
      final res = await http.post(
        Uri.parse('${await ApiService.baseUrl}/habits'),
        headers: headers,
        body: jsonEncode(habit),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 201 || res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Create habit failed: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateHabit(String habitId, Map<String, dynamic> habit) async {
    try {
      final headers = await _getAuthHeaders();
      final res = await http.put(
        Uri.parse('${await ApiService.baseUrl}/habits/$habitId'),
        headers: headers,
        body: jsonEncode(habit),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Update habit failed: $e');
      return null;
    }
  }

  static Future<bool> deleteHabit(String habitId) async {
    try {
      final headers = await _getAuthHeaders();
      final res = await http.delete(
        Uri.parse('${await ApiService.baseUrl}/habits/$habitId'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      return res.statusCode == 204;
    } catch (e) {
      debugPrint('Delete habit failed: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> logHabit(String habitId, DateTime date, {String status = 'completed', int value = 1, String? note}) async {
    try {
      final headers = await _getAuthHeaders();
      final res = await http.post(
        Uri.parse('${await ApiService.baseUrl}/habit-log'),
        headers: headers,
        body: jsonEncode({
          'habit_id': habitId,
          'log_date': date.toIso8601String().split('T')[0],
          'status': status,
          'value': value,
          'note': note,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 201 || res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Log habit failed: $e');
      return null;
    }
  }

  static Future<List<dynamic>> getHabitHistory({String? habitId, DateTime? from, DateTime? to}) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{};
      if (habitId != null) queryParams['habit_id'] = habitId;
      if (from != null) queryParams['date_from'] = from.toIso8601String().split('T')[0];
      if (to != null) queryParams['date_to'] = to.toIso8601String().split('T')[0];

      final uri = Uri.parse('${await ApiService.baseUrl}/habit-history').replace(queryParameters: queryParams);
      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('Get habit history failed: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getHabitStats(String habitId) async {
    try {
      final headers = await _getAuthHeaders();
      final res = await http.get(
        Uri.parse('${await ApiService.baseUrl}/habits/$habitId/stats'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Get habit stats failed: $e');
      return null;
    }
  }

  // --- Categories ---
  static Future<List<dynamic>> getCategories() async {
    try {
      final headers = await _getAuthHeaders();
      final res = await http.get(
        Uri.parse('${await ApiService.baseUrl}/categories'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('Get categories failed: $e');
      return [];
    }
  }

  // --- Auth ---
  static Future<Map<String, dynamic>?> login(String email, String password, {Map<String, dynamic>? device}) async {
    try {
      final res = await http.post(
        Uri.parse('${await ApiService.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'device': device,
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        await saveTokens(data['access_token'] as String, data['refresh_token'] as String);
        return data;
      } else {
        final error = jsonDecode(res.body);
        throw Exception(error['detail'] ?? 'Login failed');
      }
    } catch (e) {
      debugPrint('Login failed: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> register(String email, String password, String fullName, {Map<String, dynamic>? device}) async {
    try {
      final res = await http.post(
        Uri.parse('${await ApiService.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'full_name': fullName,
          'device': device,
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 201 || res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(res.body);
        throw Exception(error['detail'] ?? 'Registration failed');
      }
    } catch (e) {
      debugPrint('Register failed: $e');
      rethrow;
    }
  }

  static Future<void> logout() async {
    try {
      final headers = await _getAuthHeaders();
      await http.post(
        Uri.parse('${await ApiService.baseUrl}/auth/logout'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Logout failed: $e');
    } finally {
      await clearTokens();
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final headers = await _getAuthHeaders();
      final res = await http.get(
        Uri.parse('${await ApiService.baseUrl}/auth/me'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Get current user failed: $e');
      return null;
    }
  }

  // --- Health check ---
  static Future<bool> isBackendReachable() async {
    try {
      final res = await http.get(
        Uri.parse('${await ApiService.baseUrl}/../health'),
      ).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}