import 'package:flutter/material.dart';

void main(){
  runApp(MaterialApp(home: DetailedView()));
}

class DetailedView extends StatelessWidget {
  const DetailedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8,),
                TextFormField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 32,),
                Text(
                    "Category",
                    style: TextStyle(
                      color: Colors.lightGreenAccent,
                      fontSize: 16,
                    ),
                ),
                SizedBox(height: 8,),
                TextFormField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8,),
                TextFormField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8,),
                Text(
                    "NOTE",
                  style: TextStyle(
                    color: Colors.lightGreenAccent,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8,),
                TextFormField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.contact_page),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
