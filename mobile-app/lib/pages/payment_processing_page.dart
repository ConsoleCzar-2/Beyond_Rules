// lib/pages/payment_processing_page.dart
import 'package:flutter/material.dart';
import 'package:uco_hackathon_app1/pages/payment_status_page.dart';
import 'package:uco_hackathon_app1/services/fraud_detection_service.dart';
import 'dart:async';

class PaymentProcessingPage extends StatefulWidget {
  final Future<PaymentResponse> paymentFuture;
  final double amount;
  final String merchantId;

  const PaymentProcessingPage({
    super.key,
    required this.paymentFuture,
    required this.amount,
    required this.merchantId,
  });

  @override
  _PaymentProcessingPageState createState() => _PaymentProcessingPageState();
}

class _PaymentProcessingPageState extends State<PaymentProcessingPage> {
  @override
  void initState() {
    super.initState();
    widget.paymentFuture.then((response) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentStatusPage(
            response: response,
            amount: widget.amount,
            merchantId: widget.merchantId,
          ),
        ),
      );
    }).catchError((error) {
      if (!mounted) return;
      final errorResponse = PaymentResponse(status: 'failed', reason: 'Error: ${error.toString()}', logId: 'N/A');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentStatusPage(
            response: errorResponse,
            amount: widget.amount,
            merchantId: widget.merchantId,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text('Processing Payment to\n${widget.merchantId}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('₹${widget.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}