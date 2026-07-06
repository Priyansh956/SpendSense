import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/category_model.dart';
import '../providers/splitwise_provider.dart';
import '../services/splitwise_service.dart';

class SplitDetailsScreen extends StatelessWidget {
  final String friendUid;
  final String friendName;

  const SplitDetailsScreen({
    super.key,
    required this.friendUid,
    required this.friendName,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.neonGreen.withOpacity(0.8),
              child: Text(
                friendName.isNotEmpty ? friendName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(friendName,
                style: const TextStyle(color: AppColors.white, fontSize: 18)),
          ],
        ),
      ),
      body: SafeArea(
        child: Consumer<SplitwiseProvider>(
          builder: (context, provider, _) {
            if (user == null) return const SizedBox.shrink();

            final expenses =
            provider.expensesWithFriend(friendUid, user.uid);

            if (expenses.isEmpty) {
              return _buildEmptyState();
            }

            // Compute balance with this specific friend
            final balances = provider.getBalances(user.uid);
            final balance = balances[friendUid] ?? 0;

            return Column(
              children: [
                _buildBalanceBanner(balance),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) => _SplitExpenseCard(
                      expense: expenses[index],
                      currentUid: user.uid,
                      friendUid: friendUid,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBalanceBanner(double balance) {
    final isOwed = balance > 0;
    final isEven = balance == 0;

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isEven
            ? AppColors.lightGrey
            : isOwed
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEven
              ? AppColors.mediumGrey
              : isOwed
              ? AppColors.success.withOpacity(0.4)
              : AppColors.error.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEven
                ? Icons.check_circle_outline
                : isOwed
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            color: isEven
                ? AppColors.textSecondary
                : isOwed
                ? AppColors.success
                : AppColors.error,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEven
                      ? 'You\'re all settled up!'
                      : isOwed
                      ? '$friendName owes you'
                      : 'You owe $friendName',
                  style: TextStyle(
                    color: isEven
                        ? AppColors.textSecondary
                        : AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isEven) ...[
                  const SizedBox(height: 4),
                  Text(
                    '₹${balance.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isOwed ? AppColors.success : AppColors.error,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
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
          const Icon(Icons.receipt_long_outlined,
              size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          const Text(
            'No shared expenses',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Split an expense with $friendName to see it here',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SplitExpenseCard extends StatelessWidget {
  final SplitExpense expense;
  final String currentUid;
  final String friendUid;

  const _SplitExpenseCard({
    required this.expense,
    required this.currentUid,
    required this.friendUid,
  });

  @override
  Widget build(BuildContext context) {
    final iAmPayer = expense.paidByUid == currentUid;
    final myParticipant = expense.participants
        .where((p) => p.uid == currentUid)
        .firstOrNull;
    final friendParticipant = expense.participants
        .where((p) => p.uid == friendUid)
        .firstOrNull;

    final category = DefaultCategories.all.firstWhere(
          (c) => c.id == expense.category,
      orElse: () => DefaultCategories.all.last,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                  Icon(category.icon, color: category.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(expense.date),
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${expense.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'paid by ${iAmPayer ? 'you' : expense.paidByName}',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          const Divider(
              color: AppColors.mediumGrey, height: 1, indent: 16, endIndent: 16),

          // Participants
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: expense.participants
                  .map((p) => _ParticipantRow(
                participant: p,
                isCurrentUser: p.uid == currentUid,
                isFriend: p.uid == friendUid,
                expenseId: expense.id,
                iAmPayer: iAmPayer,
              ))
                  .toList(),
            ),
          ),

          // Note
          if (expense.note != null && expense.note!.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.darkGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes, size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      expense.note!,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  final SplitParticipant participant;
  final bool isCurrentUser;
  final bool isFriend;
  final String expenseId;
  final bool iAmPayer;

  const _ParticipantRow({
    required this.participant,
    required this.isCurrentUser,
    required this.isFriend,
    required this.expenseId,
    required this.iAmPayer,
  });

  @override
  Widget build(BuildContext context) {
    final name = isCurrentUser ? 'You' : participant.displayName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: participant.isPaid
                ? AppColors.success.withOpacity(0.2)
                : AppColors.mediumGrey,
            child: Text(
              name[0].toUpperCase(),
              style: TextStyle(
                color: participant.isPaid ? AppColors.success : AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: participant.isPaid 
                    ? AppColors.textSecondary 
                    : (isCurrentUser ? AppColors.neonGreen : AppColors.white),
                fontSize: 14,
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                decoration: participant.isPaid ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            '₹${participant.amount.toStringAsFixed(0)}',
            style: TextStyle(
                color: participant.isPaid ? AppColors.textSecondary : AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                decoration: participant.isPaid ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          if (participant.isPaid)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '✓ Paid',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (iAmPayer && isFriend)
            GestureDetector(
              onTap: () => _markPaid(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.neonGreen.withOpacity(0.4),
                  ),
                ),
                child: const Text(
                  'Mark Paid',
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Pending',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _markPaid(BuildContext context) async {
    try {
      await context
          .read<SplitwiseProvider>()
          .markPaid(expenseId, participant.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${participant.displayName} marked as paid'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}