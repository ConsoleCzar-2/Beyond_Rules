import 'package:flutter/material.dart';

class BehavioralDataCollector {
  // Session metrics
  List<double> tapDurations = [];
  List<double> tapIntervals = [];
  List<double> swipeSpeeds = [];
  List<double> swipeAngles = [];
  List<double> tapXPositions = [];
  List<double> swipeXDirections = [];
  Map<String, double> screenDwellTimes = {};
  List<double> typingLatencies = [];
  
  // Timing variables
  DateTime? _sessionStartTime;
  DateTime? _lastTapTime;
  DateTime? _lastScreenTransition;
  String _currentScreen = '';
  int _screenTransitions = 0;
  
  // Singleton pattern
  static final BehavioralDataCollector _instance = BehavioralDataCollector._internal();
  factory BehavioralDataCollector() => _instance;
  BehavioralDataCollector._internal() {
    _sessionStartTime = DateTime.now();
  }

  void startSession() {
    _sessionStartTime = DateTime.now();
    _lastScreenTransition = _sessionStartTime;
    _currentScreen = 'login';
    _screenTransitions = 0;
    
    // Reset all metrics
    tapDurations = [];
    tapIntervals = [];
    swipeSpeeds = [];
    swipeAngles = [];
    tapXPositions = [];
    swipeXDirections = [];
    screenDwellTimes = {};
    typingLatencies = [];
    
    print('BEHAVIORAL: Started new behavioral tracking session at ${_sessionStartTime!.toString()}');
    print('BEHAVIORAL: All metrics reset to initial values');
  }

  void recordTap(Offset position, Duration duration) {
    final now = DateTime.now();
    
    // Record tap duration
    tapDurations.add(duration.inMilliseconds.toDouble());
    
    // Record tap position
    tapXPositions.add(position.dx);
    
    // Record tap interval if not first tap
    if (_lastTapTime != null) {
      final interval = now.difference(_lastTapTime!).inMilliseconds;
      tapIntervals.add(interval.toDouble());
      print('BEHAVIORAL: Tap recorded - Duration: ${duration.inMilliseconds}ms, Position: (${position.dx.toStringAsFixed(1)}, ${position.dy.toStringAsFixed(1)}), Interval: ${interval}ms');
    } else {
      print('BEHAVIORAL: First tap recorded - Duration: ${duration.inMilliseconds}ms, Position: (${position.dx.toStringAsFixed(1)}, ${position.dy.toStringAsFixed(1)})');
    }
    
    _lastTapTime = now;
  }
  
  void recordSwipe(Offset start, Offset end, Duration duration) {
    // Calculate swipe speed (pixels per millisecond)
    final distance = (end - start).distance;
    final speed = distance / duration.inMilliseconds;
    swipeSpeeds.add(speed);
    
    // Calculate swipe angle
    final angle = _calculateAngle(start, end);
    swipeAngles.add(angle);
    
    // Record swipe X direction (positive = right, negative = left)
    final xDirection = end.dx - start.dx;
    swipeXDirections.add(xDirection);
    
    print('BEHAVIORAL: Swipe recorded - ' 
      'Start: (${start.dx.toStringAsFixed(1)}, ${start.dy.toStringAsFixed(1)}), ' 
      'End: (${end.dx.toStringAsFixed(1)}, ${end.dy.toStringAsFixed(1)}), ' 
      'Speed: ${speed.toStringAsFixed(3)} px/ms, ' 
      'Angle: ${angle.toStringAsFixed(2)}, ' 
      'Direction: ${xDirection > 0 ? 'right' : 'left'} (${xDirection.toStringAsFixed(1)})');
  }
  
  void recordScreenTransition(String screenName) {
    final now = DateTime.now();
    
    // Record dwell time for previous screen
    if (_lastScreenTransition != null && _currentScreen.isNotEmpty) {
      final dwellTime = now.difference(_lastScreenTransition!).inSeconds.toDouble();
      
      if (screenDwellTimes.containsKey(_currentScreen)) {
        screenDwellTimes[_currentScreen] = screenDwellTimes[_currentScreen]! + dwellTime;
      } else {
        screenDwellTimes[_currentScreen] = dwellTime;
      }
      
      print('BEHAVIORAL: Screen transition from $_currentScreen to $screenName - Dwell time: ${dwellTime.toStringAsFixed(1)}s');
      print('BEHAVIORAL: Total screen transitions: ${_screenTransitions + 1}');
    } else {
      print('BEHAVIORAL: First screen recorded: $screenName');
    }
    
    _currentScreen = screenName;
    _lastScreenTransition = now;
    _screenTransitions++;
  }
  
  void recordTypingLatency(Duration latency) {
    typingLatencies.add(latency.inMilliseconds.toDouble());
    print('BEHAVIORAL: Typing latency recorded: ${latency.inMilliseconds}ms (total recordings: ${typingLatencies.length})');
  }
  
  double _calculateAngle(Offset start, Offset end) {
    return (end.dx - start.dx != 0) 
        ? (end.dy - start.dy).abs() / (end.dx - start.dx).abs()
        : 90.0;
  }
  
  List<double> getBehavioralFeatures() {
    // Calculate aggregated features
    final tapDurationAvg = _average(tapDurations);
    final tapIntervalAvg = _average(tapIntervals);
    final swipeSpeedAvg = _average(swipeSpeeds);
    final swipeAngleVar = _variance(swipeAngles);
    final tapXMean = _average(tapXPositions);
    final swipeXDirAvg = _average(swipeXDirections);
    
    // Get dwell times for specific screens
    final dwellTimeHome = screenDwellTimes['home'] ?? 0.0;
    final dwellTimePayment = screenDwellTimes['payment'] ?? 0.0;
    
    // Calculate screen transition rate (transitions per minute)
    final sessionDuration = DateTime.now().difference(_sessionStartTime ?? DateTime.now()).inMinutes;
    final screenTransitionRate = (sessionDuration > 0) 
        ? _screenTransitions / sessionDuration.toDouble()
        : 0.0;
    
    final typingLatencyAvg = _average(typingLatencies);
    
    // Print detailed debug information about all features
    print('\n==== BEHAVIORAL FEATURE DETAILS ====');
    print('Session duration: ${sessionDuration}m, Screen transitions: $_screenTransitions');
    print('Tap count: ${tapDurations.length}, Swipe count: ${swipeSpeeds.length}, Typing events: ${typingLatencies.length}');
    
    print('\n-- Raw Data Statistics --');
    print('Tap durations: ${_formatList(tapDurations)}');
    print('Tap intervals: ${_formatList(tapIntervals)}');
    print('Swipe speeds: ${_formatList(swipeSpeeds)}');
    print('Swipe angles: ${_formatList(swipeAngles)}');
    print('Tap X positions: ${_formatList(tapXPositions)}');
    print('Swipe X directions: ${_formatList(swipeXDirections)}');
    print('Screen dwell times: ${screenDwellTimes.entries.map((e) => "${e.key}: ${e.value.toStringAsFixed(1)}s").join(', ')}');
    print('Typing latencies: ${_formatList(typingLatencies)}');
    
    print('\n-- Feature Vector (in order) --');
    print('1. Tap Duration Avg: ${tapDurationAvg.toStringAsFixed(2)}ms');
    print('2. Tap Interval Avg: ${tapIntervalAvg.toStringAsFixed(2)}ms');
    print('3. Swipe Speed Avg: ${swipeSpeedAvg.toStringAsFixed(3)} px/ms');
    print('4. Swipe Angle Variance: ${swipeAngleVar.toStringAsFixed(2)}');
    print('5. Tap X Position Mean: ${tapXMean.toStringAsFixed(2)}px');
    print('6. Swipe X Direction Avg: ${swipeXDirAvg.toStringAsFixed(2)}px');
    print('7. Home Screen Dwell Time: ${dwellTimeHome.toStringAsFixed(2)}s');
    print('8. Payment Screen Dwell Time: ${dwellTimePayment.toStringAsFixed(2)}s');
    print('9. Screen Transition Rate: ${screenTransitionRate.toStringAsFixed(2)}/min');
    print('10. Typing Latency Avg: ${typingLatencyAvg.toStringAsFixed(2)}ms');
    print('==============================\n');
    
    // Return features in the same order as training data
    return [
      tapDurationAvg,
      tapIntervalAvg,
      swipeSpeedAvg,
      swipeAngleVar,
      tapXMean,
      swipeXDirAvg,
      dwellTimeHome,
      dwellTimePayment,
      screenTransitionRate,
      typingLatencyAvg
    ];
  }
  
  // Helper method to format lists for debug output
  String _formatList(List<double> list) {
    if (list.isEmpty) return "[]";
    if (list.length <= 5) {
      return "[${list.map((v) => v.toStringAsFixed(2)).join(', ')}]";
    }
    // Show first 3 and last 2 elements for longer lists
    return "[${list[0].toStringAsFixed(2)}, ${list[1].toStringAsFixed(2)}, ${list[2].toStringAsFixed(2)}, ..., ${list[list.length-2].toStringAsFixed(2)}, ${list[list.length-1].toStringAsFixed(2)}] (${list.length} items)";
  }
  
  double _average(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }
  
  double _variance(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = _average(values);
    final squares = values.map((v) => (v - mean) * (v - mean));
    return _average(squares.toList());
  }
}
