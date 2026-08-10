import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/signature_models.dart';

class AdvancedSignaturePainter extends CustomPainter {
  final List<SignatureStroke> strokes;
  final SignatureStroke? currentStroke;
  final bool isVisible;

  AdvancedSignaturePainter({
    required this.strokes, 
    this.currentStroke,
    this.isVisible = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isVisible) return; // Don't paint anything if not visible
    
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Draw completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }

    // Draw current stroke
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!, paint);
    }
  }

  void _drawStroke(Canvas canvas, SignatureStroke stroke, Paint paint) {
    if (stroke.points.length < 2) return;

    final path = Path();
    
    for (int i = 0; i < stroke.points.length; i++) {
      final point = stroke.points[i];
      
      // Vary stroke width based on pressure
      paint.strokeWidth = _calculateStrokeWidth(point.pressure);
      paint.color = _calculateStrokeColor(point.pressure, point.velocity);
      
      if (i == 0) {
        path.moveTo(point.x, point.y);
      } else {
        final prevPoint = stroke.points[i - 1];
        
        // Use quadratic bezier curves for smooth lines
        final controlPointX = (prevPoint.x + point.x) / 2;
        final controlPointY = (prevPoint.y + point.y) / 2;
        
        if (i == 1) {
          path.lineTo(controlPointX, controlPointY);
        } else {
          path.quadraticBezierTo(prevPoint.x, prevPoint.y, controlPointX, controlPointY);
        }
      }
    }

    canvas.drawPath(path, paint);
  }

  double _calculateStrokeWidth(double pressure) {
    // Base width of 2.0, scaled by pressure (0.0 to 1.0)
    return 2.0 + (pressure * 4.0);
  }

  Color _calculateStrokeColor(double pressure, double? velocity) {
    // Vary opacity based on pressure and velocity
    final baseOpacity = 0.7 + (pressure * 0.3);
    final velocityFactor = velocity != null ? (1.0 - (velocity / 1000).clamp(0.0, 0.3)) : 1.0;
    
    return Colors.black.withValues(alpha: (baseOpacity * velocityFactor).clamp(0.1, 1.0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AdvancedSignatureCapture extends StatefulWidget {
  final Function(SignatureData) onSignatureCompleted;
  final double width;
  final double height;

  const AdvancedSignatureCapture({
    super.key,
    required this.onSignatureCompleted,
    this.width = 300,
    this.height = 200,
  });

  @override
  State<AdvancedSignatureCapture> createState() => _AdvancedSignatureCaptureState();
}

class _AdvancedSignatureCaptureState extends State<AdvancedSignatureCapture> {
  final List<SignatureStroke> _strokes = [];
  SignatureStroke? _currentStroke;
  List<SignaturePoint> _currentPoints = [];
  DateTime? _strokeStartTime;
  DateTime? _signatureStartTime;
  SignaturePoint? _lastPoint;
  bool _isStrokeVisible = true; // Add visibility toggle state

  void _onPanStart(DragStartDetails details) {
    _strokeStartTime = DateTime.now();
    _signatureStartTime ??= _strokeStartTime;
    _currentPoints = [];
    
    final point = _createSignaturePoint(details.localPosition, 0.5);
    _currentPoints.add(point);
    _lastPoint = point;

    setState(() {
      _currentStroke = SignatureStroke(
        points: List.from(_currentPoints),
        startTime: _strokeStartTime!,
        endTime: _strokeStartTime!,
        averageSpeed: 0.0,
        totalDistance: 0.0,
        averagePressure: 0.5,
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_strokeStartTime == null) return;

    final now = DateTime.now();
    var point = _createSignaturePoint(details.localPosition, 0.7);
    
    // Calculate velocity and acceleration
    if (_lastPoint != null) {
      final distance = _calculateDistance(_lastPoint!, point);
      final timeDiff = now.difference(_lastPoint!.timestamp).inMilliseconds;
      final velocity = timeDiff > 0 ? (distance / timeDiff) * 1000 : 0.0; // pixels per second
      
      point = SignaturePoint(
        x: point.x,
        y: point.y,
        pressure: point.pressure,
        timestamp: point.timestamp,
        velocity: velocity,
        acceleration: _calculateAcceleration(point, _lastPoint!),
      );
    }

    _currentPoints.add(point);
    _lastPoint = point;

    // Update current stroke
    final strokeMetrics = _calculateStrokeMetrics(_currentPoints);
    
    setState(() {
      _currentStroke = SignatureStroke(
        points: List.from(_currentPoints),
        startTime: _strokeStartTime!,
        endTime: now,
        averageSpeed: strokeMetrics['averageSpeed'] ?? 0.0,
        totalDistance: strokeMetrics['totalDistance'] ?? 0.0,
        averagePressure: strokeMetrics['averagePressure'] ?? 0.0,
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke != null) {
      _strokes.add(_currentStroke!);
      _currentStroke = null;
      _currentPoints = [];
      _strokeStartTime = null;
      _lastPoint = null;
      setState(() {});
    }
  }

  SignaturePoint _createSignaturePoint(Offset position, double pressure) {
    return SignaturePoint(
      x: position.dx,
      y: position.dy,
      pressure: pressure,
      timestamp: DateTime.now(),
    );
  }

  double _calculateDistance(SignaturePoint p1, SignaturePoint p2) {
    return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2));
  }

  double? _calculateAcceleration(SignaturePoint current, SignaturePoint previous) {
    if (current.velocity == null || previous.velocity == null) return null;
    
    final timeDiff = current.timestamp.difference(previous.timestamp).inMilliseconds;
    if (timeDiff <= 0) return null;
    
    return ((current.velocity! - previous.velocity!) / timeDiff) * 1000;
  }

  Map<String, double> _calculateStrokeMetrics(List<SignaturePoint> points) {
    if (points.length < 2) {
      return {
        'averageSpeed': 0.0,
        'totalDistance': 0.0,
        'averagePressure': points.isNotEmpty ? points.first.pressure : 0.0,
      };
    }

    double totalDistance = 0.0;
    double totalPressure = 0.0;
    double totalVelocity = 0.0;
    int velocityCount = 0;

    for (int i = 1; i < points.length; i++) {
      totalDistance += _calculateDistance(points[i - 1], points[i]);
      totalPressure += points[i].pressure;
      
      if (points[i].velocity != null) {
        totalVelocity += points[i].velocity!;
        velocityCount++;
      }
    }

    return {
      'averageSpeed': velocityCount > 0 ? totalVelocity / velocityCount : 0.0,
      'totalDistance': totalDistance,
      'averagePressure': totalPressure / points.length,
    };
  }

  void _clearSignature() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
      _currentPoints.clear();
      _strokeStartTime = null;
      _signatureStartTime = null;
      _lastPoint = null;
    });
    
    // Force a rebuild to ensure gesture detection is reset
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _saveSignature() {
    if (_strokes.isEmpty) return;

    final signatureData = _createSignatureData();
    widget.onSignatureCompleted(signatureData);
    
    // Clear the signature after saving
    _clearSignature();
  }

  SignatureData _createSignatureData() {
    final metadata = _calculateSignatureMetadata();
    
    return SignatureData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      strokes: _strokes,
      createdAt: _signatureStartTime ?? DateTime.now(),
      canvasWidth: widget.width,
      canvasHeight: widget.height,
      deviceInfo: _getDeviceInfo(),
      metadata: metadata,
    );
  }

  SignatureMetadata _calculateSignatureMetadata() {
    if (_strokes.isEmpty) {
      return SignatureMetadata(
        totalDuration: 0,
        totalStrokes: 0,
        totalPoints: 0,
        averageStrokeSpeed: 0,
        averagePressure: 0,
        signatureWidth: 0,
        signatureHeight: 0,
        strokeDensity: 0,
      );
    }

    final allPoints = _strokes.expand((stroke) => stroke.points).toList();
    final minX = allPoints.map((p) => p.x).reduce(min);
    final maxX = allPoints.map((p) => p.x).reduce(max);
    final minY = allPoints.map((p) => p.y).reduce(min);
    final maxY = allPoints.map((p) => p.y).reduce(max);

    final totalDuration = _strokes.isNotEmpty 
        ? _strokes.last.endTime.difference(_strokes.first.startTime).inMilliseconds.toDouble()
        : 0.0;

    final totalDistance = _strokes.fold(0.0, (sum, stroke) => sum + stroke.totalDistance);
    final averageSpeed = _strokes.isNotEmpty 
        ? _strokes.map((s) => s.averageSpeed).reduce((a, b) => a + b) / _strokes.length
        : 0.0;

    final averagePressure = allPoints.isNotEmpty
        ? allPoints.map((p) => p.pressure).reduce((a, b) => a + b) / allPoints.length
        : 0.0;

    final signatureArea = (maxX - minX) * (maxY - minY);
    final strokeDensity = signatureArea > 0 ? totalDistance / signatureArea : 0.0;

    return SignatureMetadata(
      totalDuration: totalDuration,
      totalStrokes: _strokes.length,
      totalPoints: allPoints.length,
      averageStrokeSpeed: averageSpeed,
      averagePressure: averagePressure,
      signatureWidth: maxX - minX,
      signatureHeight: maxY - minY,
      strokeDensity: strokeDensity,
    );
  }

  Map<String, dynamic> _getDeviceInfo() {
    return {
      'platform': 'flutter',
      'timestamp': DateTime.now().toIso8601String(),
      'canvasSize': {
        'width': widget.width,
        'height': widget.height,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: RawGestureDetector(
            gestures: <Type, GestureRecognizerFactory>{
              PanGestureRecognizer: GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                () => PanGestureRecognizer(),
                (PanGestureRecognizer instance) {
                  instance
                    ..onStart = _onPanStart
                    ..onUpdate = _onPanUpdate
                    ..onEnd = _onPanEnd
                    // This is important to prevent parent scroll conflicts
                    ..gestureSettings = const DeviceGestureSettings(touchSlop: 0.0);
                },
              ),
            },
            behavior: HitTestBehavior.opaque,
            child: CustomPaint(
              painter: AdvancedSignaturePainter(
                strokes: _strokes,
                currentStroke: _currentStroke,
                isVisible: _isStrokeVisible,
              ),
              size: Size(widget.width, widget.height),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Visibility toggle checkbox
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Checkbox(
              value: _isStrokeVisible,
              onChanged: (bool? value) {
                setState(() {
                  _isStrokeVisible = value ?? true;
                });
              },
            ),
            const Text('Show strokes while drawing'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _clearSignature,
              child: const Text('Clear'),
            ),
            ElevatedButton(
              onPressed: _strokes.isNotEmpty ? _saveSignature : null,
              child: const Text('Save Signature'),
            ),
          ],
        ),
        if (_strokes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Strokes: ${_strokes.length}'),
          Text('Total Points: ${_strokes.fold(0, (sum, stroke) => sum + stroke.points.length)}'),
        ],
      ],
    );
  }
}
