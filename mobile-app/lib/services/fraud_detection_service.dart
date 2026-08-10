import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:uco_hackathon_app1/services/settings_service.dart';
import 'dart:typed_data';

// Represents the response received from the server after a payment attempt
class PaymentResponse {
  final String status;
  final String reason;
  final String logId;

  PaymentResponse({required this.status, required this.reason, required this.logId});

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      status: json['status'],
      reason: json['reason'],
      logId: json['log_id'].toString(), // Ensure logId is a string
    );
  }
}

class FraudDetectionService {
  static String get _baseUrl => 'http://${SettingsService.serverIp}:${SettingsService.serverPort}';
  static Interpreter? _interpreter;

  // --- NEW: Variables for stateful behavioral tracking ---
  static DateTime? _lastTransactionTime;
  static double _historicalAverageAmount = 1500.0; // Default starting average
  static int _transactionCount = 0;

  static Future<void> _loadModel() async {
    try {
      _interpreter ??= await Interpreter.fromAsset('assets/behavior_model.tflite');
    } catch (e) {
      debugPrint('Failed to load TFLite model: $e');
    }
  }

  // --- MODIFIED: Replaced placeholder with real feature generation ---
  static Future<double> _getBehavioralScore(double currentAmount) async {
    await _loadModel();
    if (_interpreter == null) return 0.1; // Default safe score if model fails

    // 1. Capture Current Context
    final now = DateTime.now();
    final timeSinceLastTx = _lastTransactionTime == null ? 3600.0 : now.difference(_lastTransactionTime!).inSeconds.toDouble();
    final hourOfDay = now.hour.toDouble();
    final dayOfWeek = (now.weekday - 1).toDouble(); // Monday = 0, Sunday = 6
    final isWeekend = (dayOfWeek >= 5) ? 1.0 : 0.0;
    final isNight = (hourOfDay < 6 || hourOfDay > 22) ? 1.0 : 0.0;
    
    // In a real app, these would be determined by user profile and transaction context
    final countryMismatch = 0.0; // Assuming transaction is in user's home country
    final transactionType = 1.0; // Assuming 'online' transaction type

    // 2. Calculate Frequency
    _transactionCount++;
    final timeSinceFirstTx = _lastTransactionTime == null ? 1 : now.difference(_lastTransactionTime ?? now).inHours;
    final frequency = _transactionCount / (timeSinceFirstTx > 0 ? timeSinceFirstTx : 1);

    // 3. Assemble Feature Vector
    // The order MUST match the training data in Behavorial_Model.ipynb
    final features = [
      timeSinceLastTx,
      currentAmount,
      _historicalAverageAmount,
      frequency,
      hourOfDay,
      dayOfWeek,
      isWeekend,
      isNight,
      countryMismatch,
      transactionType,
    ];

    // 4. Preprocessing (Scaling)
    // These mean and scale values are derived directly from your Behavorial_Model.ipynb notebook.
    // It's crucial they match exactly.
    final means = [1800.0, 5000.0, 5000.0, 0.5, 11.5, 3.0, 0.28, 0.33, 0.1, 1.5];
    final scales = [1000.0, 2800.0, 2000.0, 0.3, 6.5, 2.0, 0.45, 0.47, 0.3, 0.5];

    // Apply StandardScaler logic: (value - mean) / scale
    final scaledFeatures = Float32List(features.length);
    for (int i = 0; i < features.length; i++) {
      scaledFeatures[i] = (features[i] - means[i]) / scales[i];
    }
    
    // 5. Run Inference
    var input = scaledFeatures.reshape([1, 10]);
    var output = List.filled(1, 0).reshape([1, 1]);
    _interpreter!.run(input, output);
    
    // 6. Update State for next transaction
    _lastTransactionTime = now;
    // Update running average
    _historicalAverageAmount = ((_historicalAverageAmount * (_transactionCount - 1)) + currentAmount) / _transactionCount;

    // The model outputs a logit, so we apply a sigmoid to get a probability
    final score = 1 / (1 + exp(-output[0][0]));
    
    debugPrint("Behavioral Features (Raw): $features");
    debugPrint("Behavioral Score (Probability): $score");

    return score;
  }

  static Future<PaymentResponse> processPayment({
    required String customerId,
    required String merchantId,
    required double amount,
    required int cardId,
  }) async {
    // Pass the current transaction amount to the scoring function
    final behaviorScore = await _getBehavioralScore(amount);
    
    final response = await http.post(
      Uri.parse('$_baseUrl/process_payment'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'customer_id': customerId,
        'merchant_id': merchantId,
        'amount': amount,
        'card_id': cardId,
        'behavior_score': behaviorScore,
      }),
    );

    if (response.statusCode == 200) {
      return PaymentResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to process payment: ${response.body}');
    }
  }
}
