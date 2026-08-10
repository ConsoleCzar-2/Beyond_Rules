import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import '../services/fraud_detection_service.dart';
import '../services/banking_data_service.dart';
import '../services/settings_service.dart';
import '../services/behavioral_data_collector.dart';

class FraudDetectionPaymentPage extends StatefulWidget {
  final VoidCallback? onBackPressed;
  final VoidCallback? onPaymentComplete;

  const FraudDetectionPaymentPage({
    super.key,
    this.onBackPressed,
    this.onPaymentComplete,
  });

  @override
  State<FraudDetectionPaymentPage> createState() => _FraudDetectionPaymentPageState();
}

class _FraudDetectionPaymentPageState extends State<FraudDetectionPaymentPage> {
  final BankingDataService _dataService = BankingDataService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  String _selectedTransactionType = 'payment';
  bool _isLoading = false;
  bool _serverHealthy = false;
  
  final List<String> _transactionTypes = ['payment', 'transfer', 'withdrawal'];
  
  @override
  void initState() {
    super.initState();
    _checkServerHealth();
    BehavioralDataCollector().recordScreenTransition('payment');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _checkServerHealth() async {
    // Ensure server IP is initialized before health check
    final isHealthy = await FraudDetectionService.isServerHealthy();
    if (mounted) {
      setState(() {
        _serverHealthy = isHealthy;
      });
    }
  }

  Future<void> _processPayment() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final merchantId = _merchantController.text.trim();
      final description = _descriptionController.text.trim();
      final customerId = _dataService.primaryCard.cardHolderName;

      // Call fraud detection service
      final fraudResponse = await FraudDetectionService.detectFraud(
        amount: amount,
        merchantId: merchantId,
        customerId: customerId,
      );

      // Show fraud detection results
      await _showFraudDetectionDialog(fraudResponse, amount, description);

    } catch (e) {
      _showErrorDialog('Error processing payment: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _validateForm() {
    if (_amountController.text.isEmpty) {
      _showErrorDialog('Please enter an amount');
      return false;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showErrorDialog('Please enter a valid amount');
      return false;
    }

    if (_merchantController.text.trim().isEmpty) {
      _showErrorDialog('Please enter a merchant name');
      return false;
    }

    if (amount > _dataService.primaryCard.balance) {
      _showErrorDialog('Insufficient balance');
      return false;
    }

    return true;
  }

  Future<void> _showFraudDetectionDialog(
    UnifiedFraudResponse fraudResponse,
    double amount,
    String description,
  ) async {
    final Color riskColor = _getRiskColor(fraudResponse.riskLevel);
    final IconData riskIcon = _getRiskIcon(fraudResponse.recommendedAction);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Row(
            children: [
              Icon(riskIcon, color: riskColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Fraud Detection Result',
                style: TextStyle(color: AppColors.white, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildResultItem('Amount', '₹${amount.toStringAsFixed(2)}'),
                _buildResultItem('Risk Level', fraudResponse.riskLevel.toUpperCase()),
                _buildResultItem('Confidence', '${fraudResponse.confidence.toStringAsFixed(1)}%'),
                _buildResultItem('Status', fraudResponse.isFraud ? 'POTENTIAL FRAUD' : 'SAFE'),
                const SizedBox(height: 16),
                Text(
                  'Analysis:',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.darkBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    fraudResponse.reason,
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: riskColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    _getActionMessage(fraudResponse.recommendedAction),
                    style: TextStyle(
                      color: riskColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (fraudResponse.recommendedAction == 'decline') ...[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel Transaction', style: TextStyle(color: AppColors.white)),
              ),
            ] else ...[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel', style: TextStyle(color: AppColors.white)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: fraudResponse.recommendedAction == 'approve' 
                      ? AppColors.green 
                      : AppColors.orange,
                  foregroundColor: AppColors.white,
                ),
                child: Text(
                  fraudResponse.recommendedAction == 'approve' 
                      ? 'Proceed with Payment' 
                      : 'Proceed with Caution',
                ),
              ),
            ],
          ],
        );
      },
    );

    if (result == true) {
      await _executePayment(amount, description);
    }
  }

  Future<void> _executePayment(double amount, String description) async {
    try {
      _dataService.sendMoney(amount, description.isNotEmpty ? description : _merchantController.text);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment of ₹${amount.toStringAsFixed(2)} completed successfully'),
          backgroundColor: AppColors.green,
        ),
      );

      // Clear form
      _amountController.clear();
      _merchantController.clear();
      _locationController.clear();
      _descriptionController.clear();
      
      widget.onPaymentComplete?.call();
      
    } catch (e) {
      _showErrorDialog('Payment failed: $e');
    }
  }

  Widget _buildResultItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return AppColors.red;
      case 'medium':
        return AppColors.orange;
      case 'low':
      default:
        return AppColors.green;
    }
  }

  IconData _getRiskIcon(String action) {
    switch (action.toLowerCase()) {
      case 'decline':
        return Icons.dangerous;
      case 'review':
        return Icons.warning;
      case 'approve':
      default:
        return Icons.check_circle;
    }
  }

  String _getActionMessage(String action) {
    switch (action.toLowerCase()) {
      case 'decline':
        return 'TRANSACTION BLOCKED - High fraud risk detected. This transaction has been automatically declined for your security.';
      case 'review':
        return 'MANUAL REVIEW REQUIRED - Moderate risk detected. Please verify transaction details before proceeding.';
      case 'approve':
      default:
        return 'TRANSACTION APPROVED - Low risk detected. Safe to proceed with this transaction.';
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Error', style: TextStyle(color: AppColors.white)),
          content: Text(message, style: const TextStyle(color: AppColors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: AppColors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onBackPressed ?? () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.white,
                        size: AppSizes.smallIconSize,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Secure Payment',
                      style: AppTextStyles.headerTitle,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.security,
                      color: _serverHealthy ? AppColors.green : AppColors.red,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Server Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppSizes.smallBorderRadius),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _serverHealthy ? Icons.verified_user : Icons.warning,
                        color: _serverHealthy ? AppColors.green : AppColors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _serverHealthy 
                              ? 'Fraud Detection System Active' 
                              : 'Fraud Detection Offline - Transactions will be reviewed manually',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Amount
                _buildTextField(
                  controller: _amountController,
                  label: 'Amount',
                  hint: '0.00',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.currency_rupee_outlined,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),
                const SizedBox(height: 16),

                // Merchant Name
                _buildTextField(
                  controller: _merchantController,
                  label: 'Merchant/Recipient',
                  hint: 'Enter merchant or recipient name',
                  prefixIcon: Icons.store,
                ),
                const SizedBox(height: 16),

                // Transaction Type
                _buildDropdownField(),
                const SizedBox(height: 16),

                // Location (Optional)
                _buildTextField(
                  controller: _locationController,
                  label: 'Location (Optional)',
                  hint: 'Enter transaction location',
                  prefixIcon: Icons.location_on,
                ),
                const SizedBox(height: 16),

                // Description (Optional)
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description (Optional)',
                  hint: 'Enter payment description',
                  prefixIcon: Icons.description,
                  maxLines: 3,
                ),
                const SizedBox(height: 30),

                // Account Balance Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppSizes.smallBorderRadius),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available Balance',
                        style: TextStyle(color: AppColors.grey, fontSize: 14),
                      ),
                      Text(
                        '₹${_dataService.primaryCard.balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Pay Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.smallBorderRadius),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Text(
                            'Analyze & Pay',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Security Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.smallBorderRadius),
                    border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your transaction will be analyzed by our AI-powered fraud detection system for your security.',
                          style: TextStyle(
                            color: AppColors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    IconData? prefixIcon,
    int? maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines ?? 1,
          style: const TextStyle(color: AppColors.white),
          onChanged: (value) {
            BehavioralDataCollector().recordTypingLatency(Duration(milliseconds: 150));
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.white.withOpacity(0.5)),
            prefixIcon: prefixIcon != null 
                ? Icon(prefixIcon, color: AppColors.white.withOpacity(0.7))
                : null,
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.smallBorderRadius),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaction Type',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.smallBorderRadius),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTransactionType,
              isExpanded: true,
              dropdownColor: AppColors.cardBackground,
              style: const TextStyle(color: AppColors.white),
              icon: Icon(
                Icons.arrow_drop_down,
                color: AppColors.white.withOpacity(0.7),
              ),
              items: _transactionTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Row(
                    children: [
                      Icon(
                        _getTransactionIcon(type),
                        color: AppColors.white.withOpacity(0.7),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        type.toUpperCase(),
                        style: const TextStyle(color: AppColors.white),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedTransactionType = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'payment':
        return Icons.payment;
      case 'transfer':
        return Icons.swap_horiz;
      case 'withdrawal':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }
}
