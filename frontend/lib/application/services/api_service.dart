import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Enterprise Security: Enforce HTTPS in production
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://api.habit-tracker.enterprise.com/api'; // Mock production URL
    }
    return 'http://192.168.43.193:3000/api'; // Local dev
  }

  static Future<Map<String, String>> _getSecureHeaders() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? 'mock_jwt_token_for_dev';
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-App-Version': '1.0.0', // Helpful for backend to know app version
    };
  }

  static Future<Map<String, dynamic>?> syncData(String key, String localValue, int lastUpdated) async {
    try {
      final headers = await _getSecureHeaders();
      
      // 1. Fetch remote data first
      final getRes = await http.get(
        Uri.parse('$baseUrl/sync/$key'),
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
      }
      
      // 2. If local is newer, push local to remote
      final postRes = await http.post(
        Uri.parse('$baseUrl/sync/$key'),
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
}
