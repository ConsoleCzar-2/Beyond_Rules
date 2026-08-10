// lib/services/banking_data_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uco_hackathon_app1/models/transaction_log.dart';
import 'package:uco_hackathon_app1/services/settings_service.dart';
import 'package:uco_hackathon_app1/services/auth_service.dart';
import 'package:uuid/uuid.dart';

class BankingDataService with ChangeNotifier {
  final AuthService? authService;
  List<TransactionLog> _logs = [];
  bool _isLoading = false;
  String _error = '';

  BankingDataService(this.authService) {
    if (authService?.isAuthenticated ?? false) {
      fetchTransactionLogs();
    }
  }

  List<TransactionLog> get logs => _logs;
  bool get isLoading => _isLoading;
  String get error => _error;

  String get _baseUrl => 'http://${SettingsService.serverIp}:${SettingsService.serverPort}';

  Future<void> fetchTransactionLogs() async {
    final customerId = authService?.user?.customerId;
    if (customerId == null) return;

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$_baseUrl/transactions/logs/$customerId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _logs = data.map((json) => TransactionLog.fromJson(json)).toList();
      } else {
        _error = 'Failed to load transaction history.';
      }
    } catch (e) {
      _error = 'Could not connect to the server.';
      debugPrint("Error fetching logs: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> respondToTransaction(UuidValue logId, String action) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/transactions/user_action'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'log_id': logId.toString(), 'action': action}),
      );
      if (response.statusCode == 200) {
        await fetchTransactionLogs();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error responding to transaction: $e");
      return false;
    }
  }
}