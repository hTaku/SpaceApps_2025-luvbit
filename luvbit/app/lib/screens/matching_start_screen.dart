import 'package:Luvbit/services/auth_service.dart';
import 'package:Luvbit/services/api_service.dart';
import 'package:flutter/material.dart';
import '../services/location_tracking_service.dart';
import '../services/location_service.dart';
import 'matching_progress_screen.dart';

class MatchingStartScreen extends StatefulWidget {
  const MatchingStartScreen({super.key});

  @override
  State<MatchingStartScreen> createState() => _MatchingStartScreenState();
}

class _MatchingStartScreenState extends State<MatchingStartScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _heartAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _heartScaleAnimation;
  bool _isLocationTracking = false;
  String _locationStatus = '位置情報を取得中...';

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    // ハートアニメーション用のコントローラー（1秒間隔で繰り返し）
    _heartAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
    ));

    // ハートのサイズアニメーション（16 -> 20 -> 16のサイズ変化）
    _heartScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.25,
    ).animate(CurvedAnimation(
      parent: _heartAnimationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    
    // 位置情報追跡を開始
    _startLocationTracking();
  }

  /// 位置情報追跡を開始
  Future<void> _startLocationTracking() async {
    try {
      setState(() {
        _locationStatus = '位置情報の権限を確認中...';
      });
      
      // 位置情報権限の詳細状態を確認
      final permissionStatus = await LocationService.getLocationPermissionStatus();
      print('権限状態詳細: $permissionStatus');
      
      // 最初に位置情報を取得して登録
      setState(() {
        _locationStatus = '位置情報を登録中...';
      });
      
      final success = await LocationTrackingService.instance.sendLocationNow();
      if (!success) {
        throw Exception('位置情報の登録に失敗しました');
      }
      
      // 位置情報登録成功後、近隣衛星を取得
      await _fetchNearBySatellites();
      
      // 定期的な位置情報追跡を開始
      await LocationTrackingService.instance.startTracking();
      
      setState(() {
        _isLocationTracking = true;
        _locationStatus = '位置情報を定期送信中（1分間隔）';
      });
      
      // 位置情報追跡開始時にハートアニメーションを開始
      _heartAnimationController.repeat(reverse: true);
      
      print('位置情報追跡を開始しました');
    } catch (e) {
      print('位置情報追跡の開始に失敗しました: $e');
      
      setState(() {
        _isLocationTracking = false;
        if (e.toString().contains('永続的に拒否')) {
          _locationStatus = '設定から位置情報を有効にしてください';
        } else if (e.toString().contains('拒否')) {
          _locationStatus = '位置情報の権限が必要です';
        } else if (e.toString().contains('サービスが無効')) {
          _locationStatus = '位置情報サービスが無効です';
        } else {
          _locationStatus = '位置情報の取得に失敗';
        }
      });
      
      // エラー時はハートアニメーションを停止
      _heartAnimationController.stop();
    }
  }

  /// 近隣衛星を取得
  Future<void> _fetchNearBySatellites() async {
    try {
      final userId = AuthService.userId;
      if (userId == null) {
        print('ユーザーIDが見つかりません');
        return;
      }

      setState(() {
        _locationStatus = '近隣衛星を検索中...';
      });

      final result = await ApiService.getNearBySatellites();
      if (result != null && result['nearby_satellites'] != null) {
        final satellites = List<String>.from(result['nearby_satellites']);
        
        print('近隣衛星を${satellites.length}個取得しました: $satellites');
        
        // 取得した衛星の1つ目をAuthServiceに設定
        if (satellites.isNotEmpty) {
          AuthService.setSatelliteName(satellites.first);
          setState(() {
            _locationStatus = '${satellites.length}個の衛星が近くを通過予定';
          });
        }
      } else {
        print('近隣衛星の取得に失敗しました');
      }
    } catch (e) {
      print('近隣衛星取得エラー: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _heartAnimationController.dispose();
    // 位置情報追跡を停止
    LocationTrackingService.instance.stopTracking();
    super.dispose();
  }

  void _startMatching() async {
    // 位置情報を手動で送信
    final success = await LocationTrackingService.instance.sendLocationNow();
    
    if (success) {
      // マッチング中画面に遷移
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const MatchingProgressScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('位置情報の取得に失敗しました'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  
                  // タイトル
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.play_arrow,
                            color: Color(0xFF2196F3),
                            size: 32,
                          ),
                          Text(
                            '運命の相手は？',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2196F3),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 80),
                  
                  // 衛星イメージ
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value * 0.5),
                        child: Center(
                          child: Container(
                            width: 280,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF1976D2),
                                      Color(0xFF0D47A1),
                                    ],
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    // 星々の背景
                                    ...List.generate(20, (index) {
                                      return Positioned(
                                        left: (index * 31.7) % 260 + 10,
                                        top: (index * 17.3) % 180 + 10,
                                        child: Container(
                                          width: 2,
                                          height: 2,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      );
                                    }),
                                    
                                    // 衛星アイコン
                                    const Center(
                                      child: Icon(
                                        Icons.satellite_alt,
                                        size: 80,
                                        color: Colors.white,
                                      ),
                                    ),
                                    
                                    // ソーラーパネル風の装飾
                                    Positioned(
                                      left: 60,
                                      top: 70,
                                      child: Container(
                                        width: 40,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: Colors.blue[700],
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 60,
                                      top: 70,
                                      child: Container(
                                        width: 40,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: Colors.blue[700],
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // メッセージ
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value * 0.3),
                      child: Text(
                        'その出会い、「${AuthService.satelliteName ?? "不明な衛星"}」がお手伝いします',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF666666),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 位置情報ステータス
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value * 0.25),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _isLocationTracking 
                              ? Colors.red.withOpacity(0.1)  // 赤色の背景に変更
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isLocationTracking 
                                ? Colors.red  // 赤色の境界線に変更
                                : Colors.orange,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // アニメーション付きハートアイコン
                            AnimatedBuilder(
                              animation: _heartScaleAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _isLocationTracking 
                                      ? _heartScaleAnimation.value 
                                      : 1.0,
                                  child: Icon(
                                    _isLocationTracking 
                                        ? Icons.favorite 
                                        : Icons.favorite_border,
                                    size: 16,
                                    color: _isLocationTracking 
                                        ? Colors.red  // 赤色に変更
                                        : Colors.orange,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _locationStatus,
                              style: TextStyle(
                                fontSize: 12,
                                color: _isLocationTracking 
                                    ? Colors.red[700]  // 赤色のテキストに変更
                                    : Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // マッチング開始ボタン
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value * 0.2),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _startMatching,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE91E63),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          child: const Text(
                            'マッチングを開始',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // サブボタン
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value * 0.1),
                      child: TextButton(
                        onPressed: () {
                          // TODO: 設定画面への遷移
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('設定画面は開発中です'),
                            ),
                          );
                        },
                        child: const Text(
                          '設定を変更',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}