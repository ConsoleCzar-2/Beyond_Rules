// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uco_hackathon_app1/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _customerIdController = TextEditingController(text: 'C_ID_1');
  bool _isLoading = false;

  Future<void> _login() async {
    if (_customerIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Customer ID.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    bool success = await authService.login(_customerIdController.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Failed. Please check the Customer ID.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security_rounded, size: 80, color: Colors.indigo),
              const SizedBox(height: 20),
              const Text('Secure Bank', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextFormField(
                controller: _customerIdController,
                decoration: const InputDecoration(labelText: 'Customer ID', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Customer ID cannot be empty' : null,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15)),
                      child: const Text('Login'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}