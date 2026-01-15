import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'color': color.value,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      icon: IconData(map['icon'], fontFamily: 'MaterialIcons'),
      color: Color(map['color']),
    );
  }
}

// Predefined categories
class DefaultCategories {
  static final List<Category> all = [
    Category(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: const Color(0xFFCDFF00),
    ),
    Category(
      id: 'food',
      name: 'Food',
      icon: Icons.restaurant,
      color: const Color(0xFFFF6B6B),
    ),
    Category(
      id: 'transport',
      name: 'Transport',
      icon: Icons.directions_car,
      color: const Color(0xFF4ECDC4),
    ),
    Category(
      id: 'rent',
      name: 'Rent',
      icon: Icons.home,
      color: const Color(0xFF2196F3),
    ),
    Category(
      id: 'education',
      name: 'Education',
      icon: Icons.school,
      color: const Color(0xFF9C27B0),
    ),
    Category(
      id: 'entertainment',
      name: 'Entertainment',
      icon: Icons.movie,
      color: const Color(0xFFFF9800),
    ),
    Category(
      id: 'healthcare',
      name: 'Healthcare',
      icon: Icons.local_hospital,
      color: const Color(0xFFE91E63),
    ),
    Category(
      id: 'utilities',
      name: 'Utilities',
      icon: Icons.lightbulb,
      color: const Color(0xFFFFC107),
    ),
    Category(
      id: 'stocks',
      name: 'Stocks',
      icon: Icons.trending_up,
      color: const Color(0xFF00E676),
    ),
    Category(
      id: 'salary',
      name: 'Salary',
      icon: Icons.account_balance_wallet,
      color: const Color(0xFF00BCD4),
    ),
    Category(
      id: 'other',
      name: 'Other',
      icon: Icons.more_horiz,
      color: const Color(0xFF9E9E9E),
    ),
  ];
}