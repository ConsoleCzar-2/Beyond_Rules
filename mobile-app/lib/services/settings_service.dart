import 'package:shared_preferences/shared_preferences.dart';

/// Manages application settings, such as server configuration.
///
/// This service persists settings using SharedPreferences and provides
/// static access to configuration values throughout the app.
class SettingsService {
  static const String _ipKey = 'server_ip';
  static const String _portKey = 'server_port';

  static const String _defaultServerIp = '<YOUR_SERVER_IP>';
  static const String _defaultServerPort = '8000';

  static String _currentServerIp = _defaultServerIp;
  static String _currentServerPort = _defaultServerPort;

  /// The currently configured server IP address.
  static String get serverIp => _currentServerIp;

  /// The currently configured server port.
  static String get serverPort => _currentServerPort;

  /// Initializes the service by loading settings from storage.
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentServerIp = prefs.getString(_ipKey) ?? _defaultServerIp;
    _currentServerPort = prefs.getString(_portKey) ?? _defaultServerPort;
  }

  /// Updates the server IP and port and persists them to storage.
  static Future<void> setServerIpAndPort(String ip, String port) async {
    if (isValidIp(ip) && isValidPort(port)) {
      _currentServerIp = ip;
      _currentServerPort = port;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ipKey, ip);
      await prefs.setString(_portKey, port);
    }
  }

  /// Validates an IP address format.
  static bool isValidIp(String ip) {
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipRegex.hasMatch(ip)) return false;
    return ip.split('.').every((part) => int.tryParse(part) != null && int.parse(part) <= 255);
  }

  /// Validates a port number format and range.
  static bool isValidPort(String port) {
    final portNum = int.tryParse(port);
    return portNum != null && portNum > 0 && portNum <= 65535;
  }

  static bool isValidIpAndPort(String ip, String port) {
    return isValidIp(ip) && isValidPort(port);
  }

  static getServerIp() {}

  static getServerPort() {}
}
