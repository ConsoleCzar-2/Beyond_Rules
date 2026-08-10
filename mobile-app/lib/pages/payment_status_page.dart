// lib/pages/payment_status_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uco_hackathon_app1/services/banking_data_service.dart';
import 'package:uco_hackathon_app1/services/fraud_detection_service.dart';

class PaymentStatusPage extends StatelessWidget {
  final PaymentResponse response;
  final double amount;
  final String merchantId;

  const PaymentStatusPage({
    super.key,
    required this.response,
    required this.amount,
    required this.merchantId,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSuccess = response.status.toLowerCase() == 'paid';
    final bool isPending = response.status.toLowerCase() == 'pending';
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BankingDataService>(context, listen: false).fetchTransactionLogs();
    });

    IconData getIcon() {
      if (isSuccess) return Icons.check_circle_rounded;
      if (isPending) return Icons.hourglass_empty_rounded;
      return Icons.cancel_rounded;
    }

    Color getColor() {
      if (isSuccess) return Colors.green.shade600;
      if (isPending) return Colors.orange.shade700;
      return Colors.red.shade700;
    }

    String getTitle() {
      if (isSuccess) return 'Payment Successful';
      if (isPending) return 'Payment Pending';
      return 'Payment Failed';
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(getIcon(), color: getColor(), size: 100),
              const SizedBox(height: 20),
              Text(getTitle(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(response.reason, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 30),
              Card(
                elevation: 2,
                child: ListTile(
                  title: Text('Amount: ₹${amount.toStringAsFixed(2)}'),
                  subtitle: Text('To: $merchantId'),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}