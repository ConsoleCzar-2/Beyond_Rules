import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/constants.dart';
import '../services/banking_data_service.dart';
import '../services/behavioral_data_collector.dart';

class StatisticsPage extends StatefulWidget {
  final VoidCallback? onBackPressed;
  final VoidCallback? onLogout;
  const StatisticsPage({super.key, this.onBackPressed, this.onLogout});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final BankingDataService _dataService = BankingDataService();

  @override
  void initState() {
    super.initState();
    BehavioralDataCollector().recordScreenTransition('statistics');
  }

  @override
  Widget build(BuildContext context) {
    final categoryTotals = _dataService.getCategoryTotals();
    final totalSpending = _dataService.getTotalSpendings();
    
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
                  'Statistics',
                  style: AppTextStyles.headerTitle,
                ),
                Spacer(),
                if (widget.onLogout != null)
                  IconButton(
                    icon: const Icon(Icons.logout, color: AppColors.red),
                    tooltip: 'Logout',
                    onPressed: widget.onLogout,
                  ),
              ],
            ),
            const SizedBox(height: 25),

            // Pie Chart with percentage
            Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(),
                        centerSpaceRadius: 0,
                        sectionsSpace: 2,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${totalSpending > 0 ? ((categoryTotals['Shopping'] ?? 0) / totalSpending * 100).toStringAsFixed(0) : '0'}%',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'of 100%',
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Chart Legend
            const Text(
              'You spent most on Shopping',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Categories List
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              ),
              child: Column(
                children: categoryTotals.entries.map((entry) {
                  return _buildCategoryItem(
                    entry.key,
                    '₹${entry.value.toStringAsFixed(2)}',
                    _getCategoryColor(entry.key),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 30),

            // Spending Summary
            Container(
              padding: const EdgeInsets.all(AppSizes.padding),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Summary',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Spending',
                        style: TextStyle(color: AppColors.grey, fontSize: 14),
                      ),
                      Text(
                        '₹${totalSpending.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Earnings',
                        style: TextStyle(color: AppColors.grey, fontSize: 14),
                      ),
                      Text(
                        '₹${_dataService.getTotalEarnings().toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.grey),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Net Income',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${(_dataService.getTotalEarnings() - totalSpending).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: (_dataService.getTotalEarnings() - totalSpending) >= 0
                              ? AppColors.green
                              : AppColors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
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
          title: '',
          radius: 60,
        ),
      ];
    }

    final colors = {
      'Shopping': AppColors.primaryBlue,
      'Health': AppColors.purple,
      'Food': AppColors.red,
      'Transfer': AppColors.green,
      'Topup': AppColors.orange,
      'Payment': AppColors.lightBlue,
    };

    return categoryTotals.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        value: percentage,
        color: colors[entry.key] ?? AppColors.grey,
        title: '',
        radius: 60,
      );
    }).toList();
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'shopping':
        return AppColors.primaryBlue;
      case 'health':
        return AppColors.purple;
      case 'food':
        return AppColors.red;
      case 'transfer':
        return AppColors.green;
      case 'topup':
        return AppColors.orange;
      case 'payment':
        return AppColors.lightBlue;
      default:
        return AppColors.grey;
    }
  }

  Widget _buildCategoryItem(String category, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              category,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
