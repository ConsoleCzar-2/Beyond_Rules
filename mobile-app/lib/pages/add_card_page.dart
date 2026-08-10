import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import '../widgets/credit_card_widget.dart';
import '../services/banking_data_service.dart';
import '../models/bank_card.dart';
import '../services/behavioral_data_collector.dart';

class AddCardPage extends StatefulWidget {
  final VoidCallback? onBackPressed;
  final VoidCallback? onCardAdded;
  
  const AddCardPage({super.key, this.onBackPressed, this.onCardAdded});

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final BankingDataService _dataService = BankingDataService();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardTypeController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  
  List<Color> _selectedGradient = [AppColors.purple, AppColors.lightPurple];
  int _selectedColorIndex = 0;

  final List<List<Color>> _colorOptions = [
    [AppColors.purple, AppColors.lightPurple],
    [AppColors.primaryBlue, AppColors.lightBlue],
    [AppColors.green, const Color(0xFF4CAF50)],
    [AppColors.orange, const Color(0xFFFF9800)],
    [AppColors.red, const Color(0xFFE57373)],
  ];

  @override
  void initState() {
    super.initState();
    BehavioralDataCollector().recordScreenTransition('add_card');
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardTypeController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                  'Add new card',
                  style: AppTextStyles.headerTitle,
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Card Preview
            CreditCardWidget(
              gradientColors: _selectedGradient,
              cardNumber: _cardNumberController.text.isNotEmpty 
                  ? _formatCardNumber(_cardNumberController.text)
                  : '•••• •••• •••• ••••',
              cardType: _cardTypeController.text.isNotEmpty 
                  ? _cardTypeController.text
                  : 'Card Type',
            ),
            const SizedBox(height: 25),

            // Color Selection
            const Text(
              'Color',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 15),
            Row(
              children: _colorOptions.asMap().entries.map((entry) {
                int index = entry.key;
                List<Color> colors = entry.value;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColorIndex = index;
                      _selectedGradient = colors;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: _buildColorOption(colors.first, _selectedColorIndex == index),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),

            // Card Details Form
            const Text(
              'Card Details',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 15),

            // Card Number
            _buildTextField(
              controller: _cardNumberController,
              label: 'Card Number',
              hint: '1234 5678 9012 3456',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
                _CardNumberFormatter(),
              ],
            ),
            const SizedBox(height: 16),

            // Expiry and CVV Row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _expiryController,
                    label: 'Expiry Date',
                    hint: 'MM/YY',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      _ExpiryDateFormatter(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _cvvController,
                    label: 'CVV',
                    hint: '123',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card Type
            _buildTextField(
              controller: _cardTypeController,
              label: 'Card Type',
              hint: 'Platinum, Gold, Silver',
            ),
            const SizedBox(height: 16),

            // Initial Balance
            _buildTextField(
              controller: _balanceController,
              label: 'Initial Balance',
              hint: '0.00',
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 30),

            // Add Card Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _addCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.smallBorderRadius),
                  ),
                ),
                child: const Text(
                  'Add Card',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption(Color color, bool isSelected) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? Border.all(color: AppColors.white, width: 3) : null,
      ),
      child: isSelected
          ? const Icon(
              Icons.check,
              color: AppColors.white,
              size: 20,
            )
          : null,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
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
          style: const TextStyle(color: AppColors.white),
          onChanged: (value) {
            setState(() {}); // Trigger rebuild to update card preview
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.white.withOpacity(0.5)),
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

  String _formatCardNumber(String cardNumber) {
    if (cardNumber.length <= 4) return cardNumber;
    
    String formatted = '';
    for (int i = 0; i < cardNumber.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += cardNumber[i];
    }
    return formatted;
  }

  void _addCard() {
    if (_cardNumberController.text.length < 16 ||
        _expiryController.text.length < 4 ||
        _cvvController.text.length < 3 ||
        _cardTypeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final balance = double.tryParse(_balanceController.text) ?? 0.0;
    
    final newCard = BankCard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cardNumber: _cardNumberController.text,
      cardType: _cardTypeController.text,
      cardHolderName: 'John Doe', // Placeholder, can be replaced with actual input
      bankName: 'UCO Bank',
      balance: balance,
      gradientColors: _selectedGradient,
      hasYellowAccent: false,
      expiryDate: _expiryController.text,
      cvv: _cvvController.text,
    );

    _dataService.addCard(newCard);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Card added successfully!'),
        backgroundColor: AppColors.green,
      ),
    );

    // Notify parent to refresh
    widget.onCardAdded?.call();

    // Clear form
    _cardNumberController.clear();
    _expiryController.clear();
    _cvvController.clear();
    _cardTypeController.clear();
    _balanceController.clear();
    setState(() {
      _selectedColorIndex = 0;
      _selectedGradient = _colorOptions[0];
    });
  }
}

// Card number formatter
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    if (text.length <= 4) {
      return newValue;
    }
    
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      final nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

// Expiry date formatter
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    if (text.length <= 2) {
      return newValue;
    }
    
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1) {
        buffer.write('/');
      }
    }
    
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
