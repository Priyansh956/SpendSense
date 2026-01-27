import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spendsense/screens/add_transaction_page_updated.dart';
import 'package:spendsense/screens/home_page.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../providers/transaction_provider.dart';
import '../constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseSummaryPage extends StatefulWidget {
  const ExpenseSummaryPage({super.key});

  @override
  State<ExpenseSummaryPage> createState() => _ExpenseSummaryPageState();
}

class _ExpenseSummaryPageState extends State<ExpenseSummaryPage> {
  String _selectedPeriod = 'Weekly';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(user),
            _buildPeriodSelector(),
            Expanded(
              child: Consumer<TransactionProvider>(
                builder: (context, provider, child) {
                  final dateRange = _getDateRange();
                  final total = provider.getTotalForDateRange(
                    dateRange['start']!,
                    dateRange['end']!,
                    type: TransactionType.expense,
                  );
                  final breakdown = provider.getCategoryBreakdown(
                    dateRange['start']!,
                    dateRange['end']!,
                  );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTotalSpending(total),
                        const SizedBox(height: 24),
                        _buildCategoryBreakdown(breakdown, total),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(User? user) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.neonGreen,
            child: Text(
              user?.email?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(
                color: AppColors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
          const Text(
            'Summary',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildPeriodButton('Weekly'),
              const SizedBox(width: 12),
              _buildPeriodButton('Monthly'),
              const SizedBox(width: 12),
              _buildPeriodButton('Yearly'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = _selectedPeriod == period;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neonGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.neonGreen : AppColors.mediumGrey,
            width: 1.5,
          ),
        ),
        child: Text(
          period,
          style: TextStyle(
            color: isSelected ? AppColors.black : AppColors.white,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTotalSpending(double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This $_selectedPeriod you spent',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '₹ ${total.toStringAsFixed(0)}',
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(Map<String, double> breakdown, double total) {
    if (breakdown.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 80,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'No expenses this $_selectedPeriod',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sortedEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedEntries.map((entry) {
        final category = DefaultCategories.all.firstWhere(
          (c) => c.id == entry.key,
          orElse: () => DefaultCategories.all.last,
        );
        final percentage = (entry.value / total * 100).round();
        
        return _buildCategoryCard(
          category: category,
          amount: entry.value,
          percentage: percentage,
        );
      }).toList(),
    );
  }

  Widget _buildCategoryCard({
    required Category category,
    required double amount,
    required int percentage,
  }) {
    final isRent = category.id == 'rent';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isRent ? AppColors.blue : AppColors.lightGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.neonGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              category.icon,
              color: AppColors.black,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹ ${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$percentage%',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, DateTime> _getDateRange() {
    final now = DateTime.now();
    
    switch (_selectedPeriod) {
      case 'Weekly':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return {
          'start': DateTime(weekStart.year, weekStart.month, weekStart.day),
          'end': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
      case 'Monthly':
        return {
          'start': DateTime(now.year, now.month, 1),
          'end': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
      case 'Yearly':
        return {
          'start': DateTime(now.year, 1, 1),
          'end': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
      default:
        return {
          'start': DateTime(now.year, now.month, 1),
          'end': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
    }
  }
}