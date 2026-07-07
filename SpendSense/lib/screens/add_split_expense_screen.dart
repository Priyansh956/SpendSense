import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/category_model.dart';
import '../providers/splitwise_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/splitwise_service.dart';

class AddSplitExpenseScreen extends StatefulWidget {
  const AddSplitExpenseScreen({super.key});

  @override
  State<AddSplitExpenseScreen> createState() => _AddSplitExpenseScreenState();
}

class _AddSplitExpenseScreenState extends State<AddSplitExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Split state
  final Set<String> _selectedFriendUids = {};
  String _splitMode = 'equal'; // 'equal' | 'custom'
  final Map<String, TextEditingController> _customAmountControllers = {};

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    for (final c in _customAmountControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _totalAmount =>
      double.tryParse(_amountController.text) ?? 0;

  int get _participantCount =>
      _selectedFriendUids.length + 1; // +1 for current user

  double get _equalShare =>
      _participantCount > 0 ? _totalAmount / _participantCount : 0;

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.neonGreen,
            onPrimary: AppColors.black,
            surface: AppColors.lightGrey,
            onSurface: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveSplitExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a category'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    if (_selectedFriendUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select at least one friend to split with'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<SplitwiseProvider>();

      // Build participants list
      final participants = <SplitParticipant>[];

      if (_splitMode == 'equal') {
        // Current user's share
        participants.add(SplitParticipant(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.email?.split('@')[0] ?? 'You',
          amount: _equalShare,
          isPaid: true, // Payer already paid their share
        ));

        // Friends' shares
        for (final uid in _selectedFriendUids) {
          participants.add(SplitParticipant(
            uid: uid,
            email: provider.getFriendEmail(uid),
            displayName: provider.getFriendName(uid),
            amount: _equalShare,
            isPaid: false,
          ));
        }
      } else {
        // Custom split
        double total = 0;
        // Current user
        final myAmount =
            double.tryParse(_customAmountControllers['me']?.text ?? '0') ?? 0;
        participants.add(SplitParticipant(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.email?.split('@')[0] ?? 'You',
          amount: myAmount,
          isPaid: true,
        ));
        total += myAmount;

        for (final uid in _selectedFriendUids) {
          final amount =
              double.tryParse(_customAmountControllers[uid]?.text ?? '0') ?? 0;
          participants.add(SplitParticipant(
            uid: uid,
            email: provider.getFriendEmail(uid),
            displayName: provider.getFriendName(uid),
            amount: amount,
            isPaid: false,
          ));
          total += amount;
        }

        // Validate total
        if ((total - _totalAmount).abs() > 0.01) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Split amounts (₹${total.toStringAsFixed(2)}) must equal total (₹${_totalAmount.toStringAsFixed(2)})'),
            backgroundColor: AppColors.error,
          ));
          setState(() => _isLoading = false);
          return;
        }
      }

      final expense = SplitExpense(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        totalAmount: _totalAmount,
        category: _selectedCategory!,
        paidByUid: user.uid,
        paidByEmail: user.email ?? '',
        paidByName: user.email?.split('@')[0] ?? 'You',
        participants: participants,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      await provider.createSplitExpense(expense);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Split expense created!'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Split Expense',
          style: TextStyle(color: AppColors.white),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAmountField(),
              const SizedBox(height: 24),
              _buildTitleField(),
              const SizedBox(height: 24),
              _buildCategorySelector(),
              const SizedBox(height: 24),
              _buildDateSelector(),
              const SizedBox(height: 24),
              _buildFriendSelector(),
              const SizedBox(height: 24),
              if (_selectedFriendUids.isNotEmpty) ...[
                _buildSplitModeSelector(),
                const SizedBox(height: 24),
                _buildSplitPreview(),
                const SizedBox(height: 24),
              ],
              _buildNoteField(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: AppColors.white, fontSize: 18),
      decoration: InputDecoration(
        labelText: 'Total Amount',
        labelStyle: TextStyle(color: AppColors.textSecondary),
        prefixIcon:
        const Icon(Icons.currency_rupee, color: AppColors.neonGreen),
        filled: true,
        fillColor: AppColors.lightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.neonGreen, width: 2),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Please enter amount';
        if (double.tryParse(v) == null || double.parse(v) <= 0) {
          return 'Please enter a valid amount';
        }
        return null;
      },
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      style: const TextStyle(color: AppColors.white, fontSize: 18),
      decoration: InputDecoration(
        labelText: 'Title',
        labelStyle: TextStyle(color: AppColors.textSecondary),
        prefixIcon: const Icon(Icons.title, color: AppColors.neonGreen),
        filled: true,
        fillColor: AppColors.lightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.neonGreen, width: 2),
        ),
      ),
      validator: (v) =>
      (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
    );
  }

  Widget _buildCategorySelector() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final userCategoryIds = provider.selectedCategories;
        final categories = DefaultCategories.all
            .where((c) => userCategoryIds.contains(c.id))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categories.map((cat) {
                final sel = _selectedCategory == cat.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel
                          ? cat.color.withOpacity(0.2)
                          : AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel ? cat.color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.icon,
                            color: sel ? cat.color : AppColors.textSecondary,
                            size: 18),
                        const SizedBox(width: 6),
                        Text(cat.name,
                            style: TextStyle(
                              color: sel ? AppColors.white : AppColors.textSecondary,
                              fontWeight: sel
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.neonGreen),
            const SizedBox(width: 16),
            Text(
              DateFormat('dd MMM, yyyy').format(_selectedDate),
              style:
              const TextStyle(color: AppColors.white, fontSize: 16),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendSelector() {
    return Consumer<SplitwiseProvider>(
      builder: (context, provider, _) {
        final friends = provider.friends;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Split with',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_selectedFriendUids.isNotEmpty)
                  Text(
                    '${_selectedFriendUids.length} selected',
                    style: TextStyle(
                      color: AppColors.neonGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (friends.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Add friends first to split expenses',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...friends.map((friend) {
                final isSelected = _selectedFriendUids.contains(friend.uid);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedFriendUids.remove(friend.uid);
                        _customAmountControllers.remove(friend.uid)?.dispose();
                      } else {
                        _selectedFriendUids.add(friend.uid);
                        _customAmountControllers[friend.uid] =
                            TextEditingController();
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.neonGreen.withOpacity(0.1)
                          : AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.neonGreen
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isSelected
                              ? AppColors.neonGreen
                              : AppColors.mediumGrey,
                          child: Text(
                            friend.displayName[0].toUpperCase(),
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.black
                                  : AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(friend.displayName,
                                  style: const TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold)),
                              Text(friend.email,
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.neonGreen
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.neonGreen
                                  : AppColors.mediumGrey,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                              color: AppColors.black, size: 16)
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildSplitModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Split Method',
          style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _splitMode = 'equal'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _splitMode == 'equal'
                        ? AppColors.neonGreen.withOpacity(0.15)
                        : AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _splitMode == 'equal'
                          ? AppColors.neonGreen
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.balance,
                          color: _splitMode == 'equal'
                              ? AppColors.neonGreen
                              : AppColors.textSecondary,
                          size: 24),
                      const SizedBox(height: 6),
                      Text('Equal Split',
                          style: TextStyle(
                            color: _splitMode == 'equal'
                                ? AppColors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          )),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _splitMode = 'custom';
                    // Init controllers for custom split
                    if (!_customAmountControllers.containsKey('me')) {
                      _customAmountControllers['me'] =
                          TextEditingController();
                    }
                    for (final uid in _selectedFriendUids) {
                      if (!_customAmountControllers.containsKey(uid)) {
                        _customAmountControllers[uid] =
                            TextEditingController();
                      }
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _splitMode == 'custom'
                        ? AppColors.neonGreen.withOpacity(0.15)
                        : AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _splitMode == 'custom'
                          ? AppColors.neonGreen
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.tune,
                          color: _splitMode == 'custom'
                              ? AppColors.neonGreen
                              : AppColors.textSecondary,
                          size: 24),
                      const SizedBox(height: 6),
                      Text('Custom Split',
                          style: TextStyle(
                            color: _splitMode == 'custom'
                                ? AppColors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSplitPreview() {
    return Consumer<SplitwiseProvider>(
      builder: (context, provider, _) {
        final user = FirebaseAuth.instance.currentUser;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.neonGreen.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long,
                      color: AppColors.neonGreen, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Split Preview',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // You
              _buildSplitRow(
                name: 'You (paid)',
                amount: _splitMode == 'equal' ? _equalShare : null,
                controller: _customAmountControllers['me'],
                isCustom: _splitMode == 'custom',
                isPayer: true,
              ),
              const Divider(color: AppColors.mediumGrey, height: 20),
              // Friends
              ...(_selectedFriendUids.map((uid) => _buildSplitRow(
                name: provider!.getFriendName(uid),
                amount: _splitMode == 'equal' ? _equalShare : null,
                controller: _customAmountControllers[uid],
                isCustom: _splitMode == 'custom',
                isPayer: false,
              ))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSplitRow({
    required String name,
    double? amount,
    TextEditingController? controller,
    required bool isCustom,
    required bool isPayer,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isPayer
                ? AppColors.neonGreen
                : AppColors.mediumGrey,
            child: Text(
              name[0].toUpperCase(),
              style: TextStyle(
                color: isPayer ? AppColors.black : AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: AppColors.white, fontSize: 14),
            ),
          ),
          if (!isCustom)
            Text(
              '₹${amount?.toStringAsFixed(2) ?? '0.00'}',
              style: const TextStyle(
                color: AppColors.neonGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            )
          else
            SizedBox(
              width: 90,
              height: 36,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.white, fontSize: 14),
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle:
                  TextStyle(color: AppColors.textTertiary, fontSize: 13),
                  prefixText: '₹',
                  prefixStyle: TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                  filled: true,
                  fillColor: AppColors.darkGrey,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: AppColors.neonGreen, width: 1.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      maxLines: 3,
      style: const TextStyle(color: AppColors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Note (Optional)',
        labelStyle: TextStyle(color: AppColors.textSecondary),
        alignLabelWithHint: true,
        filled: true,
        fillColor: AppColors.lightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.neonGreen, width: 2),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveSplitExpense,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonGreen,
          foregroundColor: AppColors.black,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
                color: AppColors.black, strokeWidth: 2))
            : const Text('Create Split Expense',
            style:
            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}