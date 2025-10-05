import 'package:flutter/material.dart';
import 'package:Luvbit/services/auth_service.dart';
import 'package:Luvbit/services/api_service.dart';
import 'matching_result_screen.dart';

class MatchingProgressScreen extends StatefulWidget {
  const MatchingProgressScreen({super.key});

  @override
  State<MatchingProgressScreen> createState() => _MatchingProgressScreenState();
}

class _MatchingProgressScreenState extends State<MatchingProgressScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isSearching = true;
  bool _showResult = false;
  String _resultMessage = '';
  bool _matchFound = false;
  Map<String, dynamic>? _matchedUser;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _pulseController.repeat(reverse: true);
    
    // 運命のパートナー検索を開始
    _startDestinyPartnerSearch();
  }

  /// 運命のパートナー検索を開始
  Future<void> _startDestinyPartnerSearch() async {
    try {
      print('運命のパートナー検索を開始します');
      
      final satelliteName = AuthService.satelliteName;
      if (satelliteName == null) {
        throw Exception('衛星名が設定されていません');
      }

      // WebAPI実行
      final result = await ApiService.getDestinyPartner(satelliteName: satelliteName);
      
      // 5秒経過を待つ
      await Future.delayed(const Duration(seconds: 5));
      
      setState(() {
        _isSearching = false;
        _showResult = true;
        
        if (result != null && result['error'] == null) {
          // 成功ケース
          _matchFound = true;
          _resultMessage = '運命のパートナーが見つかりました';
          _matchedUser = result; // ユーザー情報を保存
        } else if (result != null && result['error'] == 'not_found') {
          // 404ケース
          _matchFound = false;
          _resultMessage = result['detail'] ?? '運命のパートナーが見つかりませんでした';
          _matchedUser = null;
        } else {
          // その他のエラー
          _matchFound = false;
          _resultMessage = '運命のパートナーが見つかりませんでした';
          _matchedUser = null;
        }
      });
      
      _pulseController.stop();
      
    } catch (e) {
      print('運命のパートナー検索エラー: $e');
      
      // 5秒経過を待つ
      await Future.delayed(const Duration(seconds: 5));
      
      setState(() {
        _isSearching = false;
        _showResult = true;
        _matchFound = false;
        _resultMessage = '検索中にエラーが発生しました';
      });
      
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _showMatchingResult() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MatchingResultScreen(
          matchedUser: _matchedUser,
          isMatched: _matchFound,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 80),
                
                // タイトル
                const Text(
                  '運命の出会い',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                    letterSpacing: 1,
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // メインコンテンツ
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 検索中のアニメーション
                        if (_isSearching) ...[
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.pink.withOpacity(0.8),
                                        Colors.red.withOpacity(0.6),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.pink.withOpacity(0.3),
                                        spreadRadius: 10,
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 40),
                          
                          const Text(
                            '運命のパートナーを見つけています',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 20),
                          
                          Text(
                            '衛星「${AuthService.satelliteName ?? "不明"}」が\n最適な相手を探索中...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF666666),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        
                        // 結果表示
                        if (_showResult) ...[
                          Icon(
                            _matchFound ? Icons.favorite : Icons.heart_broken,
                            size: 100,
                            color: _matchFound ? Colors.pink : Colors.grey,
                          ),
                          
                          const SizedBox(height: 30),
                          
                          Text(
                            _resultMessage,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: _matchFound ? Color(0xFF333333) : Color(0xFF666666),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // 結果を見るボタン
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _showMatchingResult,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE91E63),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: const Text(
                                '結果を見る',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}