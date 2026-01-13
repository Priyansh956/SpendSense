import 'package:flutter/material.dart';
import 'package:spendsense/screens/homepage.dart';
import 'package:spendsense/screens/signup.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login.dart';
import 'screens/addTransaction.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 🔁 SWITCH THIS LINE TO TEST DIFFERENT SCREENS
      home: const ExpenseHistory(),
      // home: const LoginPage(),
    );
  }
}
