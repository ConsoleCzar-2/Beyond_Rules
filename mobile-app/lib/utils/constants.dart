import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF3B4CCA);
  static const Color lightBlue = Color(0xFF5A67D8);
  static const Color darkBackground = Color(0xFF1A1B2E);
  static const Color cardBackground = Color(0xFF2A2B3E);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color lightPurple = Color(0xFFA855F7);
  static const Color gold = Color(0xFFFFD700);
  static const Color white = Colors.white;
  static const Color grey = Colors.grey;
  static const Color red = Colors.red;
  static const Color green = Colors.green;
  static const Color orange = Colors.orange;
}

class AppTextStyles {
  static const TextStyle headerTitle = TextStyle(
    color: AppColors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: AppColors.white,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle cardNumber = TextStyle(
    color: AppColors.white,
    fontSize: 18,
    letterSpacing: 2,
  );

  static const TextStyle balanceAmount = TextStyle(
    color: AppColors.white,
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle transactionTitle = TextStyle(
    color: AppColors.white,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static TextStyle transactionDate = TextStyle(
    color: AppColors.white.withOpacity(0.6),
    fontSize: 12,
  );

  static const TextStyle actionButtonLabel = TextStyle(
    fontSize: 12,
  );
}

class AppSizes {
  static const double padding = 20.0;
  static const double cardHeight = 200.0;
  static const double borderRadius = 16.0;
  static const double smallBorderRadius = 12.0;
  static const double iconSize = 24.0;
  static const double smallIconSize = 20.0;
  static const double bottomNavHeight = 80.0;
}
