import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendsense/providers/transaction_provider.dart';
import 'package:spendsense/screens/main_navigation.dart';
import 'package:spendsense/screens/category_selection_page.dart';
import 'package:spendsense/constants/app_colors.dart';
import 'package:spendsense/screens/login.dart';
import 'package:spendsense/screens/signup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp(
        title: 'SpendSense',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.black,
          primaryColor: AppColors.neonGreen,
          fontFamily: 'Inter',
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.neonGreen,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
          '/home': (context) => const MainNavigation(),
          '/categories': (context) => const CategorySelectionPage(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.black,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.neonGreen,
              ),
            ),
          );
        }
        
        if (snapshot.hasData) {
          // User is logged in
          return FutureBuilder<bool>(
            future: _checkUserHasCategories(snapshot.data!.uid),
            builder: (context, categorySnapshot) {
              if (categorySnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: AppColors.black,
                  body: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.neonGreen,
                    ),
                  ),
                );
              }
              
              if (categorySnapshot.data == true) {
                return const MainNavigation();
              } else {
                return const CategorySelectionPage();
              }
            },
          );
        }
        
        // User is not logged in - return your login page
        return const LoginPage();
        
        // Temporary placeholder - replace with your login page
        // return Scaffold(
        //   backgroundColor: AppColors.black,
        //   body: Center(
        //     child: Column(
        //       mainAxisAlignment: MainAxisAlignment.center,
        //       children: [
        //         const Icon(
        //           Icons.account_balance_wallet,
        //           size: 80,
        //           color: AppColors.neonGreen,
        //         ),
        //         const SizedBox(height: 24),
        //         const Text(
        //           'SpendSense',
        //           style: TextStyle(
        //             color: AppColors.white,
        //             fontSize: 36,
        //             fontWeight: FontWeight.bold,
        //           ),
        //         ),
        //         const SizedBox(height: 48),
        //         ElevatedButton(
        //           onPressed: () {
        //             // Navigate to your login page
        //             // Navigator.pushNamed(context, '/login');
        //           },
        //           style: ElevatedButton.styleFrom(
        //             backgroundColor: AppColors.neonGreen,
        //             foregroundColor: AppColors.black,
        //             padding: const EdgeInsets.symmetric(
        //               horizontal: 48,
        //               vertical: 16,
        //             ),
        //             shape: RoundedRectangleBorder(
        //               borderRadius: BorderRadius.circular(16),
        //             ),
        //           ),
        //           child: const Text(
        //             'Get Started',
        //             style: TextStyle(
        //               fontSize: 18,
        //               fontWeight: FontWeight.bold,
        //             ),
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // );
      },
    );
  }

  Future<bool> _checkUserHasCategories(String userId) async {
    try {
      final provider = TransactionProvider();
      await provider.loadUserCategories();
      return provider.selectedCategories.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}