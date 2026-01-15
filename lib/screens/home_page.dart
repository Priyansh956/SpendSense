import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../providers/transaction_provider.dart';
import '../constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    Provider.of<TransactionProvider>(context, listen: false).listenToTransactions();
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    final now = DateTime.now();
    
    switch (_selectedFilter) {
      case 'Today':
        return transactions.where((t) {
          return t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day;
        }).toList();
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return transactions.where((t) => t.date.isAfter(weekStart)).toList();
      case 'This Month':
        return transactions.where((t) {
          return t.date.year == now.year && t.date.month == now.month;
        }).toList();
      default:
        return transactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(user),
            _buildFilterChips(),
            Expanded(
              child: Consumer<TransactionProvider>(
                builder: (context, provider, child) {
                  final filteredTransactions = 
                      _getFilteredTransactions(provider.transactions);
                  
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.neonGreen,
                      ),
                    );
                  }

                  if (filteredTransactions.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildTransactionList(filteredTransactions);
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
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
            child: CircleAvatar(
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
          ),
          const Spacer(),
          const Text(
            'Your',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Spendings',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Today', 'This Week', 'This Month'];
    
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: AppColors.lightGrey,
              selectedColor: AppColors.neonGreen,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.black : AppColors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionList(List<Transaction> transactions) {
    final groupedTransactions = _groupTransactionsByDate(transactions);
    
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final date = groupedTransactions.keys.elementAt(index);
        final dayTransactions = groupedTransactions[date]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 12),
              child: Text(
                _formatDate(date),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ...dayTransactions.map((transaction) => 
                _buildTransactionCard(transaction)),
          ],
        );
      },
    );
  }

  Map<String, List<Transaction>> _groupTransactionsByDate(
      List<Transaction> transactions) {
    final Map<String, List<Transaction>> grouped = {};
    
    for (var transaction in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(transaction);
    }
    
    return grouped;
  }

  String _formatDate(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    
    if (date.year == now.year && 
        date.month == now.month && 
        date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year && 
               date.month == now.month && 
               date.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return DateFormat('dd MMM, yyyy').format(date);
    }
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final category = DefaultCategories.all.firstWhere(
      (c) => c.id == transaction.category,
      orElse: () => DefaultCategories.all.last,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              category.icon,
              color: category.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category.name,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${transaction.type == TransactionType.expense ? '-' : '+'} ₹${transaction.amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: transaction.type == TransactionType.expense 
                  ? AppColors.error 
                  : AppColors.success,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first transaction',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}