import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // データベースの初期化
  await DatabaseHelper().database;
  
  runApp(const LuvbitApp());
}

class LuvbitApp extends StatelessWidget {
  const LuvbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luvbit',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        primaryColor: const Color(0xFFE91E63),
        fontFamily: 'Hiragino Sans',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE91E63),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
