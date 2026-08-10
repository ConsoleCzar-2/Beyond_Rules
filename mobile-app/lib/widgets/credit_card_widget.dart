import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CreditCardWidget extends StatelessWidget {
  final List<Color> gradientColors;
  final String cardNumber;
  final String cardType;
  final bool hasYellowAccent;

  const CreditCardWidget({
    super.key,
    required this.gradientColors,
    required this.cardNumber,
    this.cardType = 'Platinum',
    this.hasYellowAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.cardHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Yellow accent if needed
          if (hasYellowAccent)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 100,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(AppSizes.borderRadius),
                    topLeft: Radius.circular(8),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppSizes.smallBorderRadius),
                      ),
                      child: Text(
                        'VISA',
                        style: TextStyle(
                          color: gradientColors[0],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      cardType,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  cardNumber,
                  style: AppTextStyles.cardNumber,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
