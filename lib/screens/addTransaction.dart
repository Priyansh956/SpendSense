import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spendsense/models/transaction.dart';
import 'package:spendsense/screens/settings.dart';
import 'categoricalExpenditure.dart';
import 'homepage.dart';
import 'history.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPage();
}

class _AddTransactionPage extends State<AddTransactionPage> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _note = TextEditingController();
  int _currentIndex = 0;

  DateTime? _selectedDate;
  final TextEditingController _dateCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedCategory = 'Food';
  String _transactionType = 'Expense'; // New: for Expense/Income toggle

  @override
  void initState() {
    super.initState();
    // Set "Today" as default date
    _selectedDate = DateTime.now();
    _dateCtrl.text = "Today";
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final transaction = ExpenseTransaction(
      amount: double.parse(_amount.text.trim()),
      title: _title.text.trim(),
      category: _selectedCategory,
      date: _selectedDate!,
      note: _note.text.trim(),
      userId: user.uid,
    );

    await FirebaseFirestore.instance.collection('transactions').add(transaction.toMap());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Transaction added")),
    );

    // Clear form after saving
    _amount.clear();
    _title.clear();
    _note.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _dateCtrl.text = "Today";
      _selectedCategory = 'Food';
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _note.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CAF50), // Solid green background
      body: SafeArea(
        child: Column(
          children: [
            // Header section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Add",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        "Transaction",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 0.9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Form container
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Expense/Income Toggle
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildToggleButton('Expense', _transactionType == 'Expense'),
                              _buildToggleButton('Income', _transactionType == 'Income'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Amount field with $ icon
                        TextFormField(
                          controller: _amount,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: "Amount",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.attach_money, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter amount";
                            }
                            if (double.tryParse(value) == null) {
                              return "Invalid number";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Title field
                        TextFormField(
                          controller: _title,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: "Title",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.title, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Category dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: "Category",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.category_outlined, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          items: ["Food", "Travel", "Shopping", "Bills", "Entertainment", "Other"]
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        // Date field
                        TextFormField(
                          readOnly: true,
                          controller: _dateCtrl,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: "Today",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.calendar_today_outlined, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              initialDate: _selectedDate ?? DateTime.now(),
                            );

                            if (picked != null) {
                              setState(() {
                                _selectedDate = picked;
                                final now = DateTime.now();
                                if (picked.year == now.year &&
                                    picked.month == now.month &&
                                    picked.day == now.day) {
                                  _dateCtrl.text = "Today";
                                } else {
                                  _dateCtrl.text = "${picked.day}/${picked.month}/${picked.year}";
                                }
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        // Note field
                        TextFormField(
                          controller: _note,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: "Note",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.notes_outlined, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Save button
                        SizedBox(
                          width: 160,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _saveTransaction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              "Save",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });

          // Navigate based on selected index
          switch (index) {
            case 0:
            // Already on Add Transaction page, do nothing
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ExpenseHistory()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => categoricalExpense()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => UserSettings()),
              );
              break;
          }
        },
        destinations: [
          NavigationDestination(
              icon: Icon(Icons.home),
              label: "Add Transaction"
          ),
          NavigationDestination(
            icon: Icon(Icons.attach_money),
            label: "Expense History",
          ),
          NavigationDestination(
              icon: Icon(Icons.calendar_month),
              label: "Categorised"
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: "Settings",
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _transactionType = text;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}