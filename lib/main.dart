import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'providers/transaction_provider.dart';
import 'screens/main_navigation.dart';
import 'screens/category_selection_page.dart';
import 'screens/login.dart';
import 'constants/app_colors.dart';

// ✅ REQUIRED FOR ROUTE-AWARE SNACKBARS
final RouteObserver<PageRoute> routeObserver =
RouteObserver<PageRoute>();

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

        // ✅ REQUIRED
        navigatorObservers: [routeObserver],

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
          return const MainNavigation();
        }

        return const LoginPage();
      },
    );
  }
}
