import 'package:flutter/material.dart';

class BankCard {
  final String id;
  final String cardNumber;
  final String cardType;
  final String bankName;
  final double balance;
  final List<Color> gradientColors;
  final bool hasYellowAccent;
  final String expiryDate;
  final String cvv;
  final String cardHolderName;

  BankCard({
    required this.id,
    required this.cardNumber,
    required this.cardType,
    required this.bankName,
    required this.balance,
    required this.gradientColors,
    this.hasYellowAccent = false,
    required this.expiryDate,
    required this.cvv,
    required this.cardHolderName,
  });

  String get maskedCardNumber {
    if (cardNumber.length >= 4) {
      return '•••• ${cardNumber.substring(cardNumber.length - 4)}';
    }
    return '•••• ••••';
  }
}
