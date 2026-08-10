class SignatureStroke {
  final List<SignaturePoint> points;
  final DateTime startTime;
  final DateTime endTime;
  final double averageSpeed;
  final double totalDistance;
  final double averagePressure;

  SignatureStroke({
    required this.points,
    required this.startTime,
    required this.endTime,
    required this.averageSpeed,
    required this.totalDistance,
    required this.averagePressure,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => p.toJson()).toList(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'averageSpeed': averageSpeed,
      'totalDistance': totalDistance,
      'averagePressure': averagePressure,
      'duration': endTime.difference(startTime).inMilliseconds,
    };
  }
}

class SignaturePoint {
  final double x;
  final double y;
  final double pressure;
  final DateTime timestamp;
  final double? velocity;
  final double? acceleration;

  SignaturePoint({
    required this.x,
    required this.y,
    required this.pressure,
    required this.timestamp,
    this.velocity,
    this.acceleration,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'pressure': pressure,
      'timestamp': timestamp.toIso8601String(),
      'velocity': velocity,
      'acceleration': acceleration,
    };
  }
}

class SignatureData {
  final String id;
  final List<SignatureStroke> strokes;
  final DateTime createdAt;
  final double canvasWidth;
  final double canvasHeight;
  final Map<String, dynamic> deviceInfo;
  final SignatureMetadata metadata;

  SignatureData({
    required this.id,
    required this.strokes,
    required this.createdAt,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.deviceInfo,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'strokes': strokes.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'canvasWidth': canvasWidth,
      'canvasHeight': canvasHeight,
      'deviceInfo': deviceInfo,
      'metadata': metadata.toJson(),
    };
  }
}

class SignatureMetadata {
  final double totalDuration;
  final int totalStrokes;
  final int totalPoints;
  final double averageStrokeSpeed;
  final double averagePressure;
  final double signatureWidth;
  final double signatureHeight;
  final double strokeDensity;

  SignatureMetadata({
    required this.totalDuration,
    required this.totalStrokes,
    required this.totalPoints,
    required this.averageStrokeSpeed,
    required this.averagePressure,
    required this.signatureWidth,
    required this.signatureHeight,
    required this.strokeDensity,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalDuration': totalDuration,
      'totalStrokes': totalStrokes,
      'totalPoints': totalPoints,
      'averageStrokeSpeed': averageStrokeSpeed,
      'averagePressure': averagePressure,
      'signatureWidth': signatureWidth,
      'signatureHeight': signatureHeight,
      'strokeDensity': strokeDensity,
    };
  }
}
