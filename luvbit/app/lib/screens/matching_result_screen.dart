import 'package:flutter/material.dart';
import 'dart:convert';
import 'chat_screen.dart';

class MatchingResultScreen extends StatelessWidget {
  final Map<String, dynamic>? matchedUser;
  final bool isMatched;

  const MatchingResultScreen({
    super.key,
    this.matchedUser,
    this.isMatched = false,
  });

  /// プロフィール画像を構築するメソッド
  Widget _buildProfileImage() {
    final profileImageBase64 = matchedUser?['profile_image'];
    
    if (profileImageBase64 != null && profileImageBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(profileImageBase64);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: 150,
          height: 150,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultProfileImage();
          },
        );
      } catch (e) {
        print('プロフィール画像のデコードエラー: $e');
        return _buildDefaultProfileImage();
      }
    }
    
    return _buildDefaultProfileImage();
  }

  /// デフォルトのプロフィール画像を構築するメソッド
  Widget _buildDefaultProfileImage() {
    return Container(
      width: 150,
      height: 150,
      color: Colors.grey[300],
      child: const Icon(
        Icons.person,
        size: 80,
        color: Colors.grey,
      ),
    );
  }

  /// 情報行を構築するメソッド
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF666666),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  /// 性別の表示文字列を取得
  String _getSexDisplay() {
    final sex = matchedUser?['sex'];
    if (sex == null) return '未設定';
    
    switch (sex) {
      case 1:
        return '男性';
      case 2:
        return '女性';
      default:
        return 'その他';
    }
  }

  /// 年齢の表示文字列を取得
  String _getAgeDisplay() {
    final age = matchedUser?['age'];
    if (age == null) return '未設定';
    return '${age}歳';
  }

  /// 星座の表示文字列を取得
  String _getConstellationDisplay() {
    final constellation = matchedUser?['constellation'];
    if (constellation == null || constellation.isEmpty) return '未設定';
    return constellation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 80),
              
              // タイトル
              Text(
                isMatched ? 'おめでとうございます。運命の人はこちらの方です。' : 'マッチング結果',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 60),
              
              // 結果表示エリア
              Expanded(
                child: Center(
                  child: isMatched && matchedUser != null 
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // プロフィール画像
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.pink,
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: _buildProfileImage(),
                            ),
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // ニックネーム
                          Text(
                            '${matchedUser!['nickname'] ?? '未設定'}さん',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // ユーザー詳細情報
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow('性別', _getSexDisplay()),
                                const SizedBox(height: 8),
                                _buildInfoRow('年齢', _getAgeDisplay()),
                                const SizedBox(height: 8),
                                _buildInfoRow('星座', _getConstellationDisplay()),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // チャットボタン
                          SizedBox(
                            width: 200,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                // チャット画面に遷移
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      partnerId: matchedUser!['user_id'],
                                      partnerNickname: matchedUser!['nickname'] ?? '未設定',
                                      partnerProfileImage: matchedUser!['profile_image'],
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 3,
                              ),
                              child: const Text(
                                'チャット',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'マッチング相手が見つかりませんでした',
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xFF666666),
                        ),
                        textAlign: TextAlign.center,
                      ),
                ),
              ),
              
              // ホームに戻るボタン
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'ホーム',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}