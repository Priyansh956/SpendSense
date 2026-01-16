import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/transaction_provider.dart';
import '../models/category_model.dart';
import 'edit_categories_page.dart';

/// Profile Page - User settings and category management
/// 
/// Features:
/// - User profile display with email
/// - Category management (edit selected categories)
/// - Account settings (change password, sign out)
/// - App information
/// 
/// This page integrates with:
/// - FirebaseAuth for user management
/// - TransactionProvider for category data
/// - EditCategoriesPage for category editing

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Load user categories from Firestore
  Future<void> _loadUserData() async {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    if (provider.selectedCategories.isEmpty) {
      await provider.loadUserCategories();
    }
  }

  /// Handle user sign out
  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.lightGrey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppColors.textSecondary),
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
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  /// Navigate to edit categories page
  Future<void> _editCategories() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditCategoriesPage(),
      ),
    );

    // Reload data if categories were updated
    if (result == true && mounted) {
      await _loadUserData();
      setState(() {});
    }
  }

  /// Send password reset email
  Future<void> _changePassword() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: user?.email ?? '',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent! Check your inbox.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
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
    }
  }

  /// Show account details dialog
  void _showAccountDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.lightGrey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Account Details',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Email',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? 'No email',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'User ID',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.uid ?? 'No ID',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            const Text(
              'Account Created',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.metadata.creationTime?.toString().split(' ')[0] ?? 'Unknown',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.neonGreen),
            ),
          ),
        ],
      ),
    );
  }

  /// Show app info dialog
  void _showAboutApp() {
    showAboutDialog(
      context: context,
      applicationName: 'SpendSense',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.neonGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.account_balance_wallet,
          color: AppColors.black,
          size: 32,
        ),
      ),
      children: const [
        Text(
          'A beautiful expense tracking app built with Flutter.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        SizedBox(height: 8),
        Text(
          'Track your expenses by category, view spending summaries, and manage your finances with ease.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  /// Show help dialog
  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.lightGrey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Tips:',
                style: TextStyle(
                  color: AppColors.neonGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '• Add transactions using the + button',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              SizedBox(height: 6),
              Text(
                '• View summaries by tapping the chart icon',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              SizedBox(height: 6),
              Text(
                '• Edit categories in Profile → Edit Categories',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              SizedBox(height: 6),
              Text(
                '• Tap on categories to see transaction details',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              SizedBox(height: 6),
              Text(
                '• Filter transactions by time period on the home page',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it!',
              style: TextStyle(color: AppColors.neonGreen),
            ),
          ),
        ],
      ),
    );
  }

  /// Show privacy policy dialog
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.lightGrey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'SpendSense stores your data securely using Firebase.\n\n'
            '• We do not share your personal information with third parties\n'
            '• Your transaction data is private and only accessible by you\n'
            '• We use industry-standard encryption for data storage\n'
            '• Your email is used only for authentication purposes\n'
            '• You can delete your account and all data at any time\n\n'
            'By using SpendSense, you agree to these terms.',
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.neonGreen),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildProfileCard(),
              const SizedBox(height: 24),
              _buildCategoriesSection(),
              const SizedBox(height: 24),
              _buildAccountSection(),
              const SizedBox(height: 24),
              _buildAppSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Build page header
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your account & preferences',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.neonGreen,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  /// Build profile card with user info
  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.neonGreen.withOpacity(0.15),
            AppColors.lightGrey,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.neonGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: AppColors.neonGreen,
            child: Text(
              user?.email?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(
                color: AppColors.black,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email?.split('@')[0] ?? 'User',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'No email',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build categories section
  Widget _buildCategoriesSection() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.neonGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.category,
                        color: AppColors.neonGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Your Categories',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neonGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${provider.selectedCategories.length}',
                        style: const TextStyle(
                          color: AppColors.neonGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (provider.selectedCategories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: provider.selectedCategories.take(8).map((catId) {
                      final category = DefaultCategories.all.firstWhere(
                        (c) => c.id == catId,
                        orElse: () => DefaultCategories.all.last,
                      );
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: category.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: category.color.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              category.icon,
                              color: category.color,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              category.name,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              if (provider.selectedCategories.length > 8)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Text(
                    '+ ${provider.selectedCategories.length - 8} more categories',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              _buildSettingsTile(
                icon: Icons.edit,
                title: 'Edit Categories',
                subtitle: 'Add or remove expense categories',
                onTap: _editCategories,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build account section
  Widget _buildAccountSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildSectionHeader('Account Settings'),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Account Details',
            subtitle: 'View your account information',
            onTap: _showAccountDetails,
          ),
          const Divider(color: AppColors.mediumGrey, height: 1),
          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Reset your password via email',
            onTap: _changePassword,
          ),
          const Divider(color: AppColors.mediumGrey, height: 1),
          _buildSettingsTile(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            onTap: _signOut,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  /// Build app section
  Widget _buildAppSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildSectionHeader('App Information'),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'About SpendSense',
            subtitle: 'Version 1.0.0',
            onTap: _showAboutApp,
          ),
          const Divider(color: AppColors.mediumGrey, height: 1),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'How we protect your data',
            onTap: _showPrivacyPolicy,
          ),
          const Divider(color: AppColors.mediumGrey, height: 1),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help with the app',
            onTap: _showHelp,
          ),
        ],
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Build settings tile
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive 
              ? AppColors.error.withOpacity(0.2)
              : AppColors.neonGreen.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppColors.error : AppColors.neonGreen,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : AppColors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: AppColors.textSecondary,
        size: 16,
      ),
      onTap: _isLoading ? null : onTap,
    );
  }
}