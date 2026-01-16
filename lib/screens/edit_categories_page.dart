import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../providers/transaction_provider.dart';
import '../constants/app_colors.dart';

class EditCategoriesPage extends StatefulWidget {
  const EditCategoriesPage({super.key});

  @override
  State<EditCategoriesPage> createState() => _EditCategoriesPageState();
}

class _EditCategoriesPageState extends State<EditCategoriesPage> {
  final Set<String> _selectedCategories = {};
  final Set<String> _initialCategories = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    await provider.loadUserCategories();
    
    setState(() {
      _selectedCategories.addAll(provider.selectedCategories);
      _initialCategories.addAll(provider.selectedCategories);
      _isLoading = false;
    });
  }

  bool get _hasChanges {
    if (_selectedCategories.length != _initialCategories.length) return true;
    return !_selectedCategories.containsAll(_initialCategories) ||
           !_initialCategories.containsAll(_selectedCategories);
  }

  Future<void> _saveCategories() async {
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one category'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show confirmation if removing categories
    final removedCategories = _initialCategories.difference(_selectedCategories);
    if (removedCategories.isNotEmpty) {
      final shouldContinue = await _showRemovalWarning(removedCategories);
      if (!shouldContinue) return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      await provider.saveUserCategories(_selectedCategories.toList());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Categories updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool> _showRemovalWarning(Set<String> removedCategories) async {
    final categoryNames = removedCategories.map((id) {
      final cat = DefaultCategories.all.firstWhere(
        (c) => c.id == id,
        orElse: () => DefaultCategories.all.last,
      );
      return cat.name;
    }).join(', ');

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.lightGrey,
        title: const Text(
          'Remove Categories?',
          style: TextStyle(color: AppColors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to remove:',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              categoryNames,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Existing transactions in these categories will remain, but you won\'t be able to add new ones.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Continue',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.lightGrey,
        title: const Text(
          'Discard Changes?',
          style: TextStyle(color: AppColors.white),
        ),
        content: Text(
          'You have unsaved changes. Do you want to discard them?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Keep Editing',
              style: TextStyle(color: AppColors.neonGreen),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Discard',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  void _selectAll() {
    setState(() {
      _selectedCategories.clear();
      _selectedCategories.addAll(DefaultCategories.all.map((c) => c.id));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedCategories.clear();
    });
  }

  void _resetToDefault() {
    setState(() {
      _selectedCategories.clear();
      _selectedCategories.addAll(_initialCategories);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          backgroundColor: AppColors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.white),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
          ),
          title: const Text(
            'Edit Categories',
            style: TextStyle(color: AppColors.white),
          ),
          actions: [
            if (_hasChanges)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Modified',
                      style: TextStyle(
                        color: AppColors.neonGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.neonGreen,
                ),
              )
            : Column(
                children: [
                  _buildHeader(),
                  _buildQuickActions(),
                  Expanded(
                    child: _buildCategoryGrid(),
                  ),
                  _buildBottomBar(),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final addedCount = _selectedCategories.difference(_initialCategories).length;
    final removedCount = _initialCategories.difference(_selectedCategories).length;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedCategories.length} Selected',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'of ${DefaultCategories.all.length} available categories',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasChanges)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      if (addedCount > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add,
                              color: AppColors.success,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$addedCount',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      if (removedCount > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.remove,
                              color: AppColors.error,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$removedCount',
                              style: const TextStyle(
                                color: AppColors.error,
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
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildQuickActionButton(
            'Select All',
            Icons.check_circle_outline,
            _selectAll,
            _selectedCategories.length == DefaultCategories.all.length,
          ),
          const SizedBox(width: 8),
          _buildQuickActionButton(
            'Deselect All',
            Icons.cancel_outlined,
            _deselectAll,
            _selectedCategories.isEmpty,
          ),
          const SizedBox(width: 8),
          if (_hasChanges)
            _buildQuickActionButton(
              'Reset',
              Icons.refresh,
              _resetToDefault,
              false,
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    VoidCallback onTap,
    bool isDisabled,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDisabled 
                ? AppColors.mediumGrey.withOpacity(0.3)
                : AppColors.lightGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDisabled 
                  ? Colors.transparent
                  : AppColors.mediumGrey,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isDisabled 
                    ? AppColors.textTertiary 
                    : AppColors.neonGreen,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isDisabled 
                      ? AppColors.textTertiary 
                      : AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: DefaultCategories.all.length,
      itemBuilder: (context, index) {
        final category = DefaultCategories.all[index];
        final isSelected = _selectedCategories.contains(category.id);
        final wasInitiallySelected = _initialCategories.contains(category.id);
        final isNew = isSelected && !wasInitiallySelected;
        final isRemoved = !isSelected && wasInitiallySelected;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedCategories.remove(category.id);
              } else {
                _selectedCategories.add(category.id);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected 
                  ? category.color.withOpacity(0.2)
                  : AppColors.lightGrey,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected 
                    ? category.color 
                    : isRemoved
                        ? AppColors.error.withOpacity(0.5)
                        : Colors.transparent,
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category.icon,
                        size: 40,
                        color: isSelected 
                            ? category.color 
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        category.name,
                        style: TextStyle(
                          color: isSelected 
                              ? AppColors.white 
                              : AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: isSelected 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (isNew)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (isRemoved)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'REMOVE',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (isSelected)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: AppColors.black,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasChanges) ...[
              Text(
                'You have unsaved changes',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                if (_hasChanges)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _resetToDefault,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.white,
                        side: const BorderSide(color: AppColors.mediumGrey),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (_hasChanges) const SizedBox(width: 16),
                Expanded(
                  flex: _hasChanges ? 1 : 0,
                  child: SizedBox(
                    width: _hasChanges ? null : double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isSaving || !_hasChanges) ? null : _saveCategories,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasChanges 
                            ? AppColors.neonGreen 
                            : AppColors.mediumGrey,
                        foregroundColor: AppColors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _hasChanges ? 'Save Changes' : 'No Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _hasChanges 
                                    ? AppColors.black 
                                    : AppColors.textSecondary,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}