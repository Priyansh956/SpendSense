import 'package:flutter/material.dart';
import 'addTransaction.dart';
import 'categoricalExpenditure.dart';
import 'settings.dart';

class ExpenseHistory extends StatefulWidget {
  const ExpenseHistory({super.key});

  @override
  State<ExpenseHistory> createState() => _ExpenseHistoryState();
}

class _ExpenseHistoryState extends State<ExpenseHistory> {
  String? _selectedMonth;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade500,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(
            Icons.arrow_back, color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("This week you spent", style: TextStyle(color: Colors.white),),
            SizedBox(height: 16,),
            Row(
              children: [
                Icon(Icons.currency_rupee, color: Colors.white,),
                SizedBox(height: 8,),
                Text("5000", style: TextStyle(color: Colors.white),),
                SizedBox(height: 48),
                Expanded(
                  child: DropdownButtonFormField(
                      value: _selectedMonth,
                      items: ["Jan", "Feb", "Mar", "Apr", "May"].map((String month){
                        return DropdownMenuItem<String>(
                          value: month,
                          child: Text(month)
                        );
                      }).toList(),
                      onChanged: (newValue){
                        setState(() {
                          _selectedMonth = newValue;
                        });
                      },
                      validator: (value){
                        if(value == null){
                          return 'Please select a valid option from the dropdown menu';
                        }
                        return null;
                      },
                  ),
                ),
              ],
            ),
            SizedBox(height: 48,),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(width: 150, height: 100, color: Colors.red),
                  Container(width: 150, height: 100, color: Colors.green),
                  Container(width: 150, height: 100, color: Colors.blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

