// lib/services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uco_hackathon_app1/services/settings_service.dart';
import 'package:uco_hackathon_app1/models/user.dart';

class AuthService with ChangeNotifier {
  User? _user;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;

  String get _baseUrl => 'http://${SettingsService.serverIp}:${SettingsService.serverPort}';

  Future<bool> login(String customerId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'customer_id': customerId}),
      );

      if (response.statusCode == 200) {
        _user = User.fromJson(jsonDecode(response.body));
        _isAuthenticated = true;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user!.toJson()));
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Login failed: $e");
      return false;
    }
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('user')) return;
    final extractedUserData = jsonDecode(prefs.getString('user')!) as Map<String, dynamic>;
    _user = User.fromJson(extractedUserData);
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _isAuthenticated = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    notifyListeners();
  }
}