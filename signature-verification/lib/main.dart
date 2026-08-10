import 'package:flutter/material.dart';
import 'widgets/signature_capture_widget.dart';
import 'models/signature_models.dart';
import 'services/signature_api_service.dart';

void main() {
  runApp(const SignatureTestApp());
}

class SignatureTestApp extends StatelessWidget {
  const SignatureTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced Signature Capture',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SignatureCaptureScreen(),
    );
  }
}

class SignatureCaptureScreen extends StatefulWidget {
  const SignatureCaptureScreen({super.key});

  @override
  State<SignatureCaptureScreen> createState() => _SignatureCaptureScreenState();
}

class _SignatureCaptureScreenState extends State<SignatureCaptureScreen> {
  bool _isUploading = false;
  bool _serverConnected = false;
  String _statusMessage = '';
  List<SignatureData> _savedSignatures = [];

  @override
  void initState() {
    super.initState();
    _checkServerConnection();
    _loadSavedSignatures();
  }

  Future<void> _checkServerConnection() async {
    final isConnected = await SignatureApiService.testConnection();
    setState(() {
      _serverConnected = isConnected;
      _statusMessage = isConnected 
          ? 'Connected to server' 
          : 'Server not available - signatures will be stored locally';
    });
  }

  Future<void> _loadSavedSignatures() async {
    final signatures = await SignatureApiService.getSignatures();
    if (signatures != null) {
      setState(() {
        _savedSignatures = signatures;
      });
    }
  }

  Future<void> _onSignatureCompleted(SignatureData signatureData) async {
    setState(() {
      _isUploading = true;
      _statusMessage = 'Uploading signature...';
    });

    try {
      final success = await SignatureApiService.uploadSignature(signatureData);
      
      if (success) {
        setState(() {
          _statusMessage = 'Signature uploaded successfully!';
          _savedSignatures.insert(0, signatureData);
        });
        
        // Show success dialog
        _showSuccessDialog(signatureData);
      } else {
        setState(() {
          _statusMessage = 'Failed to upload signature';
        });
        
        // Show error dialog
        _showErrorDialog('Failed to upload signature to server');
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
      _showErrorDialog('Error uploading signature: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showSuccessDialog(SignatureData signatureData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Signature uploaded successfully!'),
            const SizedBox(height: 16),
            Text('Strokes: ${signatureData.metadata.totalStrokes}'),
            Text('Points: ${signatureData.metadata.totalPoints}'),
            Text('Duration: ${signatureData.metadata.totalDuration.toStringAsFixed(0)}ms'),
            Text('Avg Speed: ${signatureData.metadata.averageStrokeSpeed.toStringAsFixed(2)} px/s'),
            Text('Avg Pressure: ${signatureData.metadata.averagePressure.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Signature Capture'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(
              _serverConnected ? Icons.cloud_done : Icons.cloud_off,
              color: _serverConnected ? Colors.green : Colors.red,
            ),
            onPressed: _checkServerConnection,
            tooltip: _serverConnected ? 'Server Connected' : 'Server Disconnected',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _serverConnected ? Colors.green.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _serverConnected ? Colors.green : Colors.orange,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _serverConnected ? Icons.check_circle : Icons.warning,
                    color: _serverConnected ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_statusMessage)),
                  if (_isUploading) const CircularProgressIndicator(),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instructions
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• Draw your signature in the area below'),
                    Text('• The app captures stroke patterns, speed, and pressure'),
                    Text('• Each signature is analyzed for ML training features'),
                    Text('• Data is automatically sent to the FastAPI server'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Signature capture widget
            Center(
              child: AdvancedSignatureCapture(
                onSignatureCompleted: _onSignatureCompleted,
                width: MediaQuery.of(context).size.width - 32,
                height: 300,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Saved signatures section
            if (_savedSignatures.isNotEmpty) ...[
              const Text(
                'Recent Signatures:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _savedSignatures.length,
                  itemBuilder: (context, index) {
                    final signature = _savedSignatures[index];
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 8),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Signature ${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('Strokes: ${signature.metadata.totalStrokes}'),
                              Text('Points: ${signature.metadata.totalPoints}'),
                              Text('Duration: ${signature.metadata.totalDuration.toStringAsFixed(0)}ms'),
                              Text('Created: ${signature.createdAt.toString().substring(0, 16)}'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Server connection test button
            ElevatedButton.icon(
              onPressed: _checkServerConnection,
              icon: const Icon(Icons.refresh),
              label: const Text('Test Server Connection'),
            ),
          ],
        ),
      ),
    );
  }
}
