import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/settings_service.dart';
import '../services/fraud_detection_service.dart';
import '../services/behavioral_data_collector.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _serverIpController = TextEditingController();
  final TextEditingController _serverPortController = TextEditingController();
  bool _isLoading = false;
  bool _isTestingConnection = false;
  String? _connectionStatus;

  @override
  void initState() {
    super.initState();
    _loadCurrentIp();
    BehavioralDataCollector().recordScreenTransition('settings');
  }

  @override
  void dispose() {
    _serverIpController.dispose();
    _serverPortController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentIp() async {
    final currentIp = SettingsService.getServerIp();
    final currentPort = SettingsService.getServerPort();
    _serverIpController.text = currentIp;
    _serverPortController.text = currentPort;
  }

  Future<void> _saveServerIp() async {
    final ip = _serverIpController.text.trim();
    final port = _serverPortController.text.trim();
    
    if (!SettingsService.isValidIpAndPort(ip, port)) {
      _showMessage('Please enter a valid IP address and port', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      SettingsService.setServerIpAndPort(ip, port);
      _showMessage('Server IP and port saved successfully!');
    } catch (e) {
      _showMessage('Failed to save server settings: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    final ip = _serverIpController.text.trim();
    final port = _serverPortController.text.trim();
    
    if (!SettingsService.isValidIpAndPort(ip, port)) {
      _showMessage('Please enter a valid IP address and port', isError: true);
      return;
    }

    setState(() {
      _isTestingConnection = true;
      _connectionStatus = null;
    });

    try {
      // Temporarily update the URL for testing
      // FraudDetectionService.updateServerUrl(ip, port);
      final fraudService = CloudFraudDetectionService();
      final isHealthy = await fraudService.isHealthy();
      
      setState(() {
        _connectionStatus = isHealthy 
            ? 'Connection successful! ✅' 
            : 'Connection failed. Please check the IP/port and ensure the server is running. ❌';
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection error: $e ❌';
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
      
      // Restore the saved IP and port
      _loadCurrentIp();
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.red : AppColors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: AppTextStyles.headerTitle,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Server Configuration Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppSizes.smallBorderRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.dns,
                          color: AppColors.white.withOpacity(0.8),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Fraud Detection Server',
                          style: AppTextStyles.sectionTitle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Server IP Address',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _serverIpController,
                                style: const TextStyle(color: AppColors.white),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: '144.24.146.33',
                                  hintStyle: TextStyle(color: AppColors.white.withOpacity(0.5)),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: AppColors.white.withOpacity(0.3)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: AppColors.white),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.computer,
                                    color: AppColors.white.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Port',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _serverPortController,
                                style: const TextStyle(color: AppColors.white),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '8000',
                                  hintStyle: TextStyle(color: AppColors.white.withOpacity(0.5)),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: AppColors.white.withOpacity(0.3)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: AppColors.white),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.settings_ethernet,
                                    color: AppColors.white.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Connection Status
                    if (_connectionStatus != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _connectionStatus!.contains('✅') 
                              ? AppColors.green.withOpacity(0.2)
                              : AppColors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _connectionStatus!.contains('✅') 
                                ? AppColors.green
                                : AppColors.red,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _connectionStatus!,
                          style: TextStyle(
                            color: _connectionStatus!.contains('✅') 
                                ? AppColors.green
                                : AppColors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isTestingConnection ? null : _testConnection,
                            icon: _isTestingConnection
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                    ),
                                  )
                                : const Icon(Icons.wifi_find, size: 18),
                            label: Text(_isTestingConnection ? 'Testing...' : 'Test Connection'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveServerIp,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                    ),
                                  )
                                : const Icon(Icons.save, size: 18),
                            label: Text(_isLoading ? 'Saving...' : 'Save'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Info Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppSizes.smallBorderRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.white.withOpacity(0.8),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Information',
                          style: AppTextStyles.sectionTitle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '• Enter the IP address and port of your fraud detection server\n'
                      '• Default port is 8000, but you can change it if needed\n'
                      '• Make sure your device is connected to the same network\n'
                      '• Test the connection before making payments\n'
                      '• If connection fails, verify the IP address, port, and server status',
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.8),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
