import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/constants.dart';
import '../widgets/credit_card_widget.dart';
import '../widgets/chart_painter.dart';
import '../services/banking_data_service.dart';
import '../services/behavioral_data_collector.dart';

class CardPage extends StatefulWidget {
  final VoidCallback? onBackPressed;
  
  const CardPage({super.key, this.onBackPressed});

  @override
  State<CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  final BankingDataService _dataService = BankingDataService();

  @override
  void initState() {
    super.initState();
    BehavioralDataCollector().recordScreenTransition('card');
  }

  @override
  Widget build(BuildContext context) {
    final cards = _dataService.cards;
    final totalBalance = _dataService.getTotalBalance();
    final earnings = _dataService.getTotalEarnings();
    final spendings = _dataService.getTotalSpendings();
    
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
                  'Card Information',
                  style: AppTextStyles.headerTitle,
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Card List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Card List',
                  style: AppTextStyles.sectionTitle,
                ),
                Text(
                  'You have ${cards.length} active card${cards.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Primary Card
            CreditCardWidget(
              gradientColors: _dataService.primaryCard.gradientColors,
              cardNumber: _dataService.primaryCard.maskedCardNumber,
              cardType: _dataService.primaryCard.cardType,
              hasYellowAccent: true,
            ),
            const SizedBox(height: 20),

            // Other Cards (if any)
            if (cards.length > 1) ...[
              const Text(
                'Other Cards',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: cards.length - 1,
                  itemBuilder: (context, index) {
                    final card = cards[index + 1]; // Skip the primary card
                    return Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: CreditCardWidget(
                        gradientColors: card.gradientColors,
                        cardNumber: card.maskedCardNumber,
                        cardType: card.cardType,
                        hasYellowAccent: card.hasYellowAccent,
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 30),

            // Total Balance
            const Text(
              'Total Balance',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '₹ ${totalBalance.toStringAsFixed(2)}',
                  style: AppTextStyles.balanceAmount,
                ),
                const SizedBox(width: 12),
                Text(
                  '${totalBalance > 50000 ? 20 : 5}% ${totalBalance > 50000 ? '↑' : '↓'}',
                  style: TextStyle(
                    color: totalBalance > 50000 ? AppColors.green : AppColors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Earn and Spend
            Row(
              children: [
                Expanded(
                  child: _buildEarnSpendCard(
                    'Earn',
                    '₹ ${earnings.toStringAsFixed(2)}',
                    AppColors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEarnSpendCard(
                    'Spend',
                    '₹ ${spendings.toStringAsFixed(2)}',
                    AppColors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Statistics Section
            const Text(
              'Statistics',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 15),

            // Pie Chart
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: Row(
                  children: [
                      // Pie Chart
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: PieChart(
                          PieChartData(
                            sections: _buildPieChartSections(),
                            centerSpaceRadius: 20,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Legend
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem('Shopping', AppColors.primaryBlue),
                            const SizedBox(height: 8),
                            _buildLegendItem('Health', AppColors.purple),
                            const SizedBox(height: 8),
                            _buildLegendItem('Food', AppColors.red),
                            const SizedBox(height: 8),
                            _buildLegendItem('Other', AppColors.orange),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final categoryTotals = _dataService.getCategoryTotals();
    final total = categoryTotals.values.fold(0.0, (sum, value) => sum + value);
    
    if (total == 0) {
      return [
        PieChartSectionData(
          value: 100,
          color: AppColors.grey,
          title: 'No data',
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
          radius: 50,
        ),
      ];
    }

    final colors = [
      AppColors.primaryBlue,
      AppColors.purple,
      AppColors.red,
      AppColors.orange,
      AppColors.green,
    ];

    return categoryTotals.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final categoryEntry = entry.value;
      final percentage = (categoryEntry.value / total) * 100;
      
      return PieChartSectionData(
        value: percentage,
        color: colors[index % colors.length],
        title: '${percentage.toStringAsFixed(0)}%',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        radius: 50,
      );
    }).toList();
  }

  Widget _buildEarnSpendCard(String title, String amount, Color chartColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.smallBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Chart simulation
          SizedBox(
            height: 40,
            child: CustomPaint(
              painter: ChartPainter(chartColor),
              size: const Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
