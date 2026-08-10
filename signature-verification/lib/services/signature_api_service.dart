import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/signature_models.dart';

class SignatureApiService {
  static const String baseUrl = 'http://144.24.146.33:5000'; // Change this to your FastAPI server URL
  static const String signaturesEndpoint = '/signatures';

  static Future<bool> uploadSignature(SignatureData signatureData) async {
    try {
      final url = Uri.parse('$baseUrl$signaturesEndpoint');
      
      print('Uploading to: $url');
      print('Payload size: ${jsonEncode(signatureData.toJson()).length} bytes');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(signatureData.toJson()),
      );

      print('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Upload successful');
        return true;
      } else {
        print('Upload failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Upload error: $e');
      return false;
    }
  }

  static Future<List<SignatureData>?> getSignatures() async {
    try {
      final url = Uri.parse('$baseUrl$signaturesEndpoint');
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => _signatureDataFromJson(json)).toList();
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static SignatureData _signatureDataFromJson(Map<String, dynamic> json) {
    return SignatureData(
      id: json['id'],
      strokes: (json['strokes'] as List)
          .map((strokeJson) => _signatureStrokeFromJson(strokeJson))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      canvasWidth: json['canvasWidth'].toDouble(),
      canvasHeight: json['canvasHeight'].toDouble(),
      deviceInfo: json['deviceInfo'],
      metadata: _signatureMetadataFromJson(json['metadata']),
    );
  }

  static SignatureStroke _signatureStrokeFromJson(Map<String, dynamic> json) {
    return SignatureStroke(
      points: (json['points'] as List)
          .map((pointJson) => _signaturePointFromJson(pointJson))
          .toList(),
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      averageSpeed: json['averageSpeed'].toDouble(),
      totalDistance: json['totalDistance'].toDouble(),
      averagePressure: json['averagePressure'].toDouble(),
    );
  }

  static SignaturePoint _signaturePointFromJson(Map<String, dynamic> json) {
    return SignaturePoint(
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      pressure: json['pressure'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      velocity: json['velocity']?.toDouble(),
      acceleration: json['acceleration']?.toDouble(),
    );
  }

  static SignatureMetadata _signatureMetadataFromJson(Map<String, dynamic> json) {
    return SignatureMetadata(
      totalDuration: json['totalDuration'].toDouble(),
      totalStrokes: json['totalStrokes'],
      totalPoints: json['totalPoints'],
      averageStrokeSpeed: json['averageStrokeSpeed'].toDouble(),
      averagePressure: json['averagePressure'].toDouble(),
      signatureWidth: json['signatureWidth'].toDouble(),
      signatureHeight: json['signatureHeight'].toDouble(),
      strokeDensity: json['strokeDensity'].toDouble(),
    );
  }

  static Future<bool> testConnection() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final response = await http.get(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
