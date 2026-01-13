import 'package:flutter/material.dart';

class Category{
  final String name;
  final double amount;
  final int percent;
  final IconData icon;
  final Color backgroundColor;

  Category({
    required this.name,
    required this.amount,
    required this.percent,
    required this.icon,
    required this.backgroundColor,
  });
}