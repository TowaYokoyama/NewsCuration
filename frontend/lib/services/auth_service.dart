import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = kIsWeb ? 'http://localhost:8001' : 'http://10.0.2.2:8001';
  static const String _tokenKey = 'jwt_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/login'),
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'username': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      await saveToken(data['access_token']);
      return true;
    } else {
      // エラーレスポンスのボディをログに出力
      debugPrint('Login failed: ${response.statusCode} - ${response.body}');
      return false;
    }
  }

  static Future<bool> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/register'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      // エラーレスポンスのボディをログに出力
      debugPrint('Registration failed: ${response.statusCode} - ${response.body}');
      return false;
    }
  }

  static Future<void> addFavorite(int articleId) async {
    final token = await getToken();
    if (token == null) return;

    final response = await http.post(
      Uri.parse('$_baseUrl/api/articles/$articleId/favorite'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      debugPrint('Failed to add favorite: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> removeFavorite(int articleId) async {
    final token = await getToken();
    if (token == null) return;

    final response = await http.delete(
      Uri.parse('$_baseUrl/api/articles/$articleId/favorite'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      debugPrint('Failed to remove favorite: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<Set<int>> getFavoriteIds() async {
    final token = await getToken();
    if (token == null) return {};

    final response = await http.get(
      Uri.parse('$_baseUrl/api/articles/me/favorites'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
      return body.map<int>((dynamic item) => item['id'] as int).toSet();
    } else {
      debugPrint('Failed to get favorites: ${response.statusCode} - ${response.body}');
      return {};
    }
  }
}
