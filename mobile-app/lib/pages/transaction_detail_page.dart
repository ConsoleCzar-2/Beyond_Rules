// lib/pages/transaction_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uco_hackathon_app1/models/transaction_log.dart';
import 'package:uco_hackathon_app1/services/banking_data_service.dart';
import 'package:intl/intl.dart';

extension StringExtension on String {
    String capitalize() {
      return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
    }
}

class TransactionDetailPage extends StatelessWidget {
  final TransactionLog transactionLog;
  const TransactionDetailPage({super.key, required this.transactionLog});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Icon(transactionLog.icon, color: transactionLog.color, size: 80),
                  const SizedBox(height: 16),
                  Text('₹${transactionLog.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('To: ${transactionLog.merchantId}', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(DateFormat.yMMMMd('en_IN').add_jm().format(transactionLog.timestamp), style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const Divider(height: 40),
            _buildDetailRow('Status:', transactionLog.status.toString().split('.').last.capitalize(), transactionLog.color),
            _buildDetailRow('Transaction Log ID:', '#${transactionLog.logId.toString().substring(0,8)}...'),
            _buildDetailRow('Reason:', transactionLog.reason),
            if (transactionLog.status == LogStatus.awaitingUserConfirmation)
              _buildUserActionCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildUserActionCard(BuildContext context) {
    return Card(
      color: Colors.blue[50],
      margin: const EdgeInsets.only(top: 24),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Complete this transaction?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 8),
            const Text('This payment was reviewed and approved. Please confirm if you still wish to proceed.', textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    bool success = await Provider.of<BankingDataService>(context, listen: false).respondToTransaction(transactionLog.logId, 'confirm');
                    if (success && context.mounted) Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Yes, Complete'),
                ),
                TextButton(
                  onPressed: () async {
                     bool success = await Provider.of<BankingDataService>(context, listen: false).respondToTransaction(transactionLog.logId, 'cancel');
                     if (success && context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('No, Cancel', style: TextStyle(color: Colors.red)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}