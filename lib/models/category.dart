import 'package:flutter/material.dart';
import 'categories.dart';

final List<Category> categories = [
  Category(
    name: "Rent",
    amount: 2500,
    percent: 50,
    icon: Icons.home,
    backgroundColor: Colors.blue,
  ),
  Category(
    name: "Shopping",
    amount: 500,
    percent: 15,
    icon: Icons.shopping_bag,
    backgroundColor: Colors.white,
  ),
  Category(
    name: "Stocks",
    amount: 2500,
    percent: 35,
    icon: Icons.trending_up,
    backgroundColor: Colors.grey.shade800,
  ),
];
