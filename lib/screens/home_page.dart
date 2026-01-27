import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../providers/transaction_provider.dart';
import '../constants/app_colors.dart';
import '../screens/detailed_view.dart';
import '../main.dart'; // routeObserver

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
  GlobalKey<ScaffoldMessengerState>();

  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    Provider.of<TransactionProvider>(context, listen: false)
        .listenToTransactions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() {
    _messengerKey.currentState?.removeCurrentSnackBar();
  }

  // ---------------- FILTERING ----------------

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    final now = DateTime.now();

    switch (_selectedFilter) {
      case 'Today':
        return transactions.where((t) =>
        t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day).toList();

      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return transactions.where((t) => t.date.isAfter(weekStart)).toList();

      case 'This Month':
        return transactions.where((t) =>
        t.date.year == now.year && t.date.month == now.month).toList();

      default:
        return transactions;
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(user),
              _buildFilterChips(),
              Expanded(
                child: Consumer<TransactionProvider>(
                  builder: (_, provider, __) {
                    if (provider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.neonGreen,
                        ),
                      );
                    }

                    final filtered =
                    _getFilteredTransactions(provider.transactions);

                    if (filtered.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildTransactionList(filtered);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(User? user) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.neonGreen,
              child: Text(
                user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'Your ',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.w300,
            ),
          ),
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
        itemBuilder: (_, index) {
          final filter = filters[index];
          final selected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              onSelected: (_) => setState(() => _selectedFilter = filter),
              selectedColor: AppColors.neonGreen,
              backgroundColor: AppColors.lightGrey,
              labelStyle: TextStyle(
                color: selected ? AppColors.black : AppColors.white,
                fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- LIST ----------------

  Widget _buildTransactionList(List<Transaction> transactions) {
    final grouped = _groupTransactionsByDate(transactions);

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: grouped.length,
      itemBuilder: (_, index) {
        final dateKey = grouped.keys.elementAt(index);
        final dayTxns = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _formatDate(dateKey),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ...dayTxns.map(_buildSwipeableTransactionCard),
          ],
        );
      },
    );
  }

  Map<String, List<Transaction>> _groupTransactionsByDate(
      List<Transaction> transactions) {
    final Map<String, List<Transaction>> map = {};

    for (final t in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(t.date);
      map.putIfAbsent(key, () => []);
      map[key]!.add(t);
    }

    return map;
  }

  String _formatDate(String key) {
    final date = DateTime.parse(key);
    final now = DateTime.now();

    if (DateUtils.isSameDay(date, now)) return 'Today';
    if (DateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }

    return DateFormat('dd MMM, yyyy').format(date);
  }

  // ---------------- CARD (SWIPE EDIT + DELETE) ----------------

  Widget _buildSwipeableTransactionCard(Transaction transaction) {
    final category = DefaultCategories.all.firstWhere(
          (c) => c.id == transaction.category,
      orElse: () => DefaultCategories.all.last,
    );

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.horizontal,

      // 👉 EDIT
      background: _buildEditBackground(),

      // 👈 DELETE
      secondaryBackground: _buildDeleteBackground(),

      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _editTransaction(transaction);
          return false; // snap back
        }

        if (direction == DismissDirection.endToStart) {
          return await _confirmDelete(transaction);
        }

        return false;
      },

      onDismissed: (_) => _deleteTransaction(transaction),

      child: _buildTransactionCard(transaction, category),
    );
  }

  Widget _buildTransactionCard(
      Transaction transaction, Category category) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailedView(transaction: transaction),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(category.icon, color: category.color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                transaction.title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${transaction.type == TransactionType.expense ? '-' : '+'} ₹${transaction.amount.toStringAsFixed(0)}',
              style: TextStyle(
                color: transaction.type == TransactionType.expense
                    ? AppColors.error
                    : AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- EDIT ----------------

  Widget _buildEditBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success,
            AppColors.neonGreen.withOpacity(0.8),
            AppColors.neonGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: const [
          Icon(Icons.edit, color: AppColors.black),
          SizedBox(width: 8),
          Text(
            'Edit',
            style: TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editTransaction(Transaction transaction) async {
    final updated = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(
        builder: (_) => DetailedView(transaction: transaction),
      ),
    );

    if (updated != null) {
      final provider =
      Provider.of<TransactionProvider>(context, listen: false);

      await provider.updateTransaction(updated);

      _messengerKey.currentState?.showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.darkGrey,
          content: Text(
            'Transaction updated',
            style: TextStyle(color: AppColors.white),
          ),
        ),
      );
    }
  }

  // ---------------- DELETE ----------------

  Widget _buildDeleteBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.black,
            AppColors.error.withOpacity(0.8),
            AppColors.error,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_outline, color: AppColors.white),
    );
  }

  Future<bool> _confirmDelete(Transaction transaction) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkGrey,
        title: const Text(
          'Delete transaction?',
          style: TextStyle(color: AppColors.white),
        ),
        content: Text(
          transaction.title,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    final provider =
    Provider.of<TransactionProvider>(context, listen: false);

    await provider.deleteTransaction(transaction.id);

    _messengerKey.currentState?.showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.darkGrey,
        content: Text(
          'Transaction deleted',
          style: TextStyle(color: AppColors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No transactions yet',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
