import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class DetailedView extends StatefulWidget {
  final Transaction transaction;

  const DetailedView({
    super.key,
    required this.transaction,
  });

  @override
  State<DetailedView> createState() => _DetailedViewState();
}

class _DetailedViewState extends State<DetailedView> {
  late final TextEditingController amountController;
  late final TextEditingController titleController;
  late final TextEditingController categoryController;
  late final TextEditingController dateController;
  late final TextEditingController noteController;

  @override
  void initState() {
    super.initState();

    final t = widget.transaction;

    amountController =
        TextEditingController(text: t.amount.toString());
    titleController =
        TextEditingController(text: t.title);
    categoryController =
        TextEditingController(text: t.category);
    dateController =
        TextEditingController(
          text: "${t.date.day}/${t.date.month}/${t.date.year}",
        );
    noteController =
        TextEditingController(text: t.note ?? '');
  }

  @override
  void dispose() {
    amountController.dispose();
    titleController.dispose();
    categoryController.dispose();
    dateController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void saveEditedTransaction() {
    final updatedTransaction = widget.transaction.copyWith(
      amount: double.tryParse(amountController.text) ??
          widget.transaction.amount,
      title: titleController.text.trim(),
      category: categoryController.text.trim(),
      note: noteController.text.trim(),
      date: widget.transaction.date, // keep same date unless edited
    );

    Navigator.pop(context, updatedTransaction);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Transaction Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                "Category",
                style: TextStyle(
                  color: Colors.lightGreenAccent,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: categoryController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "NOTE",
                style: TextStyle(
                  color: Colors.lightGreenAccent,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreenAccent,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: saveEditedTransaction,
                  child: const Text("Save Changes"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
