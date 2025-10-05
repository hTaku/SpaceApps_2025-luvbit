import 'package:Luvbit/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../widgets/permission_dialog.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasNavigated = false; // 遷移済みフラグを追加

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
    ));

    _startAnimation();
  }

  void _startAnimation() {
    _animationController.forward();
    
    // 権限ダイアログを表示
    Timer(const Duration(seconds: 3), () {
      _showPermissionDialog();
    });
    
    // 一定時間後に自動的にマッチング画面に遷移
    Timer(const Duration(seconds: 8), () {
      _navigateToLoginScreen();
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionDialog(
        onPermissionsGranted: () {
          _navigateToLoginScreen();
        },
        onLater: () {
          _navigateToLoginScreen();
        },
      ),
    );
  }

  void _navigateToLoginScreen() {
    if (_hasNavigated) return; // 既に遷移済みの場合は何もしない
    _hasNavigated = true;
    
    // ダイアログが表示されている場合は閉じる
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: GestureDetector(
        onTap: () {
          // デバッグモードでタップされた場合、直接マッチング画面に遷移
          if (kDebugMode && !_hasNavigated) {
            _navigateToLoginScreen();
          }
        },
        child: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // アプリロゴエリア
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/luvbit_logo_heart.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // アプリタイトル
                    const Text(
                      'Luvbit',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                        letterSpacing: 2,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // キャッチフレーズ
                    const Text(
                      '〜低軌道で、恋が巡りだす〜',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                        letterSpacing: 1,
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // ローディングインジケーター
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFE91E63),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ));
  }
}