import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  String? _username;
  bool _isLoading = true;

  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;
  String? get token => _token;
  String? get username => _username;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('admin_token');
    _username = prefs.getString('admin_username');
    _isLoading = false;
    notifyListeners();
  }

  /// Returns null on success, or an error message string.
  Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'username=${Uri.encodeComponent(username)}&password=${Uri.encodeComponent(password)}',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access_token'] as String;
        _username = username;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('admin_token', _token!);
        await prefs.setString('admin_username', username);
        notifyListeners();
        return null;
      }
      try {
        final detail = jsonDecode(response.body)['detail'];
        return detail?.toString() ?? 'Σφάλμα σύνδεσης (${response.statusCode})';
      } catch (_) {
        return 'Σφάλμα σύνδεσης (${response.statusCode})';
      }
    } catch (e) {
      return 'Αδύνατη η σύνδεση: $e';
    }
  }

  Future<void> logout() async {
    _token = null;
    _username = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_token');
    await prefs.remove('admin_username');
    notifyListeners();
  }
}
