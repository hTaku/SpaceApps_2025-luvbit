import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth.dart';
import '../config/environment.dart';

class AuthService {
  static final String _baseUrl = Environment.apiBaseUrl;
  static const String _tokenKey = 'auth_token';

  static String? _accessToken;
  static String? _satelliteName;
  static int? _userId;

  static String? get accessToken => _accessToken;
  static String? get satelliteName => _satelliteName;
  static int? get userId => _userId;

  static void setAuthInfo(String token) {
    _accessToken = token;
  }

  static void setSatelliteName(String satelliteName) {
    _satelliteName = satelliteName;
  }

  static void setUserId(int userId) {
    _userId = userId;
  }

  static void clearAuthInfo() {
    _accessToken = null;
    _userId = null;
  }

  Future<AuthResponse> login(String email, String password, {Function? onLoginSuccess}) async {
    print('リクエスト開始: $email');
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/v1/login'),
      );

      // Postmanと同じヘッダーを設定
      request.headers.addAll({
        'Accept': '*/*',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
        'Accept-Encoding': 'gzip, deflate, br',
      });

      // フォームデータを追加
      request.fields.addAll({
        'username': email,
        'password': password,
      });

      // リクエストの詳細情報をデバッグ出力
      print('リクエスト情報:');
      print('URI: ${request.url}');
      print('Headers: ${request.headers}');
      print('Method: ${request.method}');
      print('Fields: ${request.fields}');

      // リクエストを送信
      final streamedResponse = await request.send();
      
      // リクエストの実際のContent-Typeを確認
      print('送信時のContent-Type: ${streamedResponse.request?.headers['content-type']}');
      print('送信時のヘッダー全体: ${streamedResponse.request?.headers}');

      // レスポンスを取得
      final response = await http.Response.fromStream(streamedResponse);

      print('ステータスコード: ${response.statusCode}');
      print('レスポンスヘッダー: ${response.headers}');
      print('レスポンスボディ: ${response.body}');

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await _saveToken(authResponse.accessToken);
        
        // 認証情報を保存（メモリ上）
        AuthService.setAuthInfo(authResponse.accessToken);
        
        // SharedPreferencesにも確実に保存（ApiServiceと同じキー名で）
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', authResponse.accessToken);
        
        // ユーザーIDと衛星名を保存
        if (authResponse.userId != null) {
          AuthService.setUserId(authResponse.userId!);
        }
        if (authResponse.satelliteName != null) {
          AuthService.setSatelliteName(authResponse.satelliteName!);
        }

        print('トークン保存完了: ${authResponse.accessToken}');
        print('ユーザーID: ${authResponse.userId}');

        // ここで画面遷移のコールバックを呼び出す
        if (onLoginSuccess != null) {
          onLoginSuccess();
        }
        
        return authResponse;
      } else {
        throw Exception('ログイン失敗: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('エラー発生: $e');
      rethrow;
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}