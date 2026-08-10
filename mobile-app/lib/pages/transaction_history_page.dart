// lib/pages/transaction_history_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uco_hackathon_app1/models/transaction_log.dart';
import 'package:uco_hackathon_app1/services/banking_data_service.dart';
import 'package:uco_hackathon_app1/pages/transaction_detail_page.dart';
import 'package:intl/intl.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});
  @override
  _TransactionHistoryPageState createState() => _TransactionHistoryPageState();
}
class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BankingDataService>(context, listen: false).fetchTransactionLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: Consumer<BankingDataService>(
        builder: (context, bankingService, child) {
          if (bankingService.isLoading && bankingService.logs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (bankingService.error.isNotEmpty) {
            return Center(child: Text(bankingService.error));
          }
          if (bankingService.logs.isEmpty) {
            return const Center(child: Text('No transaction history found.'));
          }
          return RefreshIndicator(
            onRefresh: () => bankingService.fetchTransactionLogs(),
            child: ListView.builder(
              itemCount: bankingService.logs.length,
              itemBuilder: (context, index) {
                final log = bankingService.logs[index];
                return _buildTransactionTile(context, log);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, TransactionLog log) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: log.color.withOpacity(0.1),
          child: Icon(log.icon, color: log.color),
        ),
        title: Text(log.merchantId, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(DateFormat.yMMMd().add_jm().format(log.timestamp)),
        trailing: Text(
          '₹${log.amount.toStringAsFixed(2)}',
          style: TextStyle(fontWeight: FontWeight.bold, color: log.color, fontSize: 16),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionDetailPage(transactionLog: log),
            ),
          ).then((_) => Provider.of<BankingDataService>(context, listen: false).fetchTransactionLogs()); // Refresh on return
        },
      ),
    );
  }
}