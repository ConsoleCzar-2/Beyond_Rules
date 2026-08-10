import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/credit_card_widget.dart';
import '../services/banking_data_service.dart';
import '../services/settings_service.dart';
import '../pages/fraud_detection_payment_page.dart';
import '../pages/settings_page.dart';
import '../services/behavioral_data_collector.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BankingDataService _dataService = BankingDataService();

  @override
  void initState() {
    super.initState();
    _initializeSettings();
    BehavioralDataCollector().recordScreenTransition('home');
  }

  void _initializeSettings() {
  }

  @override
  Widget build(BuildContext context) {
    final primaryCard = _dataService.primaryCard;
    final recentTransactions = _dataService.transactions.take(6).toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'UCO BANK',
                  style: AppTextStyles.headerTitle,
                ),
                GestureDetector(
                  onTap: () => _openSettings(),
                  child: Icon(
                    Icons.settings,
                    color: AppColors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Your Card Section
            const Text(
              'Your Card',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 15),

            // Credit Card
            CreditCardWidget(
              gradientColors: primaryCard.gradientColors,
              cardNumber: primaryCard.maskedCardNumber,
              cardType: primaryCard.cardType,
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () => _showSendMoneyDialog(),
                  child: _buildActionButton(Icons.arrow_upward, 'Send', AppColors.red),
                ),
                GestureDetector(
                  onTap: () => _showReceiveMoneyDialog(),
                  child: _buildActionButton(Icons.arrow_downward, 'Receive', AppColors.green),
                ),
                GestureDetector(
                  onTap: () => _showTopupDialog(),
                  child: _buildActionButton(Icons.add, 'Topup', Colors.blue),
                ),
                GestureDetector(
                  onTap: () => _showPaymentDialog(),
                  child: _buildActionButton(Icons.swap_horiz, 'Payment', AppColors.orange),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Recent Activities
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activities',
                  style: AppTextStyles.sectionTitle,
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.white.withOpacity(0.6),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Transaction List
            Expanded(
              child: ListView.builder(
                itemCount: recentTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = recentTransactions[index];
                  return _buildTransactionItem(
                    transaction.icon,
                    transaction.title,
                    transaction.formattedDate,
                    transaction.formattedAmount,
                    transaction.color,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.smallBorderRadius),
          ),
          child: Icon(
            icon,
            color: color,
            size: AppSizes.iconSize,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.actionButtonLabel.copyWith(
            color: AppColors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    IconData icon,
    String title,
    String date,
    String amount,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.smallBorderRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: AppSizes.smallIconSize,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.transactionTitle,
                ),
                Text(
                  date,
                  style: AppTextStyles.transactionDate,
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: amount.startsWith('+') ? AppColors.green : AppColors.red,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showSendMoneyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController amountController = TextEditingController();
        final TextEditingController titleController = TextEditingController();
        
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Send Money',
            style: TextStyle(color: AppColors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Recipient',
                  labelStyle: TextStyle(color: AppColors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  labelStyle: TextStyle(color: AppColors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.white),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                final title = titleController.text;
                if (amount != null && amount > 0 && title.isNotEmpty) {
                  _dataService.sendMoney(amount, 'Send to $title');
                  Navigator.of(context).pop();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sent ₹${amount.toStringAsFixed(2)} to $title'),
                      backgroundColor: AppColors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  void _showReceiveMoneyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController amountController = TextEditingController();
        final TextEditingController titleController = TextEditingController();
        
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Receive Money',
            style: TextStyle(color: AppColors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'From',
                  labelStyle: TextStyle(color: AppColors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  labelStyle: TextStyle(color: AppColors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.white),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                final title = titleController.text;
                if (amount != null && amount > 0 && title.isNotEmpty) {
                  _dataService.receiveMoney(amount, 'Received from $title');
                  Navigator.of(context).pop();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Received ₹${amount.toStringAsFixed(2)} from $title'),
                      backgroundColor: AppColors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Receive'),
            ),
          ],
        );
      },
    );
  }

  void _showTopupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController amountController = TextEditingController();
        
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Top Up',
            style: TextStyle(color: AppColors.white),
          ),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.white),
            decoration: const InputDecoration(
              labelText: 'Amount (₹)',
              labelStyle: TextStyle(color: AppColors.white),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.white),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.white),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  _dataService.receiveMoney(amount, 'Account Top Up');
                  Navigator.of(context).pop();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Topped up ₹${amount.toStringAsFixed(2)}'),
                      backgroundColor: AppColors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Top Up'),
            ),
          ],
        );
      },
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  void _showPaymentDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FraudDetectionPaymentPage(
          onBackPressed: () => Navigator.of(context).pop(),
          onPaymentComplete: () {
            Navigator.of(context).pop();
            setState(() {}); // Refresh the home page
          },
        ),
      ),
    );
  }
}
