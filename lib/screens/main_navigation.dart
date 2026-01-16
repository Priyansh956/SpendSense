import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'home_page.dart';
import 'expense_summary_page.dart';
import 'category_wise_page.dart';
import 'package:spendsense/screens/add_transaction_page_updated.dart';
import 'profile_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const HomePage(),
    const ExpenseSummaryPage(),
    const Placeholder(), // Placeholder for FAB
    const CategoryWisePage(),
    const ProfilePage(), // Profile/Settings page
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: _pages,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionPage(),
            ),
          );
          
          if (result == true) {
            setState(() {
              _currentIndex = 0;
            });
          }
        },
        backgroundColor: AppColors.neonGreen,
        elevation: 8,
        child: const Icon(
          Icons.add,
          color: AppColors.black,
          size: 32,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.darkGrey,
        elevation: 0,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, Icons.home, 0),
              _buildNavItem(Icons.pie_chart_outline, Icons.pie_chart, 1),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(Icons.category_outlined, Icons.category, 3),
              _buildNavItem(Icons.person_outline, Icons.person, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData outlinedIcon, IconData filledIcon, int index) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.neonGreen.withOpacity(0.2) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isSelected ? filledIcon : outlinedIcon,
          color: isSelected ? AppColors.neonGreen : AppColors.textSecondary,
          size: 28,
        ),
      ),
    );
  }
}