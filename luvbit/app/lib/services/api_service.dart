import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:38000',
  );

  /// 認証トークンを取得
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// 認証トークンを保存
  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// 認証トークンを削除
  static Future<void> removeAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  /// 認証ヘッダーを作成
  static Future<Map<String, String>> _getHeaders({bool withAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (withAuth) {
      final token = await getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// 位置情報を登録するAPI
  static Future<Map<String, dynamic>?> registUserPosition({
    required double lat,
    required double lng,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/regist_user_position');
      final headers = await _getHeaders();
      
      final body = json.encode({
        'lat': lat,
        'lng': lng,
      });

      debugPrint('位置情報登録API呼び出し: lat=$lat, lng=$lng');
      debugPrint('API URL: $url');
      debugPrint('Headers: $headers');
      debugPrint('Body: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      debugPrint('APIレスポンス: ${response.statusCode}');
      debugPrint('レスポンスヘッダー: ${response.headers}');
      debugPrint('レスポンスボディ: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('位置情報登録成功: $responseData');
        return responseData;
      } else {
        debugPrint('位置情報登録失敗: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('位置情報登録エラー: $e');
      return null;
    }
  }

  /// ユーザーログインAPI（例）
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/login');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'username=$email&password=$password',
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final token = responseData['access_token'];
        
        if (token != null) {
          await saveAuthToken(token);
                    
          return {
            'access_token': token,
            'user_id': responseData['user_id'],
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('ログインエラー: $e');
      return null;
    }
  }

  /// 保存された衛星名を取得
  static Future<String?> getSatelliteName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('satellite_name');
  }

  /// 近隣通過衛星を取得するAPI
  static Future<Map<String, dynamic>?> getNearBySatellites() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/satellites/nearby');
      final headers = await _getHeaders();

      debugPrint('近隣衛星取得API呼び出し');
      debugPrint('API URL: $url');
      debugPrint('Headers: $headers');

      final response = await http.get(
        url,
        headers: headers,
      );

      debugPrint('近隣衛星APIレスポンス: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('近隣衛星取得成功: $responseData');
        return responseData;
      } else {
        debugPrint('近隣衛星取得失敗: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('近隣衛星取得エラー: $e');
      return null;
    }
  }

  /// 運命のパートナーを検索するAPI
  static Future<Map<String, dynamic>?> getDestinyPartner({
    required String satelliteName,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/get_destiny_partner?satellite_name=${Uri.encodeComponent(satelliteName)}');
      final headers = await _getHeaders();

      debugPrint('運命のパートナー検索API呼び出し: satelliteName=$satelliteName');
      debugPrint('API URL: $url');
      debugPrint('Headers: $headers');

      final response = await http.get(
        url,
        headers: headers,
      );

      debugPrint('運命のパートナーAPIレスポンス: ${response.statusCode}');
      debugPrint('レスポンスヘッダー: ${response.headers}');
      debugPrint('レスポンスボディ: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('運命のパートナー検索成功: $responseData');
        return responseData;
      } else if (response.statusCode == 404) {
        final responseData = json.decode(response.body);
        debugPrint('運命のパートナーが見つかりません: ${responseData['detail']}');
        return {'error': 'not_found', 'detail': responseData['detail']};
      } else {
        debugPrint('運命のパートナー検索失敗: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('運命のパートナー検索エラー: $e');
      return null;
    }
  }

  /// チャットルームを作成するAPI
  static Future<Map<String, dynamic>?> createChatRoom(int partnerUserId) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/chat/rooms');
      final headers = await _getHeaders();

      final body = json.encode({
        'partner_user_id': partnerUserId,
      });

      debugPrint('チャットルーム作成API呼び出し: partnerUserId=$partnerUserId');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      debugPrint('チャットルーム作成APIレスポンス: ${response.statusCode}');
      debugPrint('レスポンスボディ: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('チャットルーム作成成功: $responseData');
        return responseData;
      } else {
        debugPrint('チャットルーム作成失敗: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('チャットルーム作成エラー: $e');
      return null;
    }
  }

  /// チャットメッセージ一覧を取得するAPI
  static Future<Map<String, dynamic>?> getChatMessages(int chatRoomId, {int page = 1, int limit = 50}) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/chat/rooms/$chatRoomId/messages?page=$page&limit=$limit');
      final headers = await _getHeaders();

      debugPrint('チャットメッセージ取得API呼び出し: chatRoomId=$chatRoomId, page=$page, limit=$limit');

      final response = await http.get(
        url,
        headers: headers,
      );

      debugPrint('チャットメッセージ取得APIレスポンス: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('チャットメッセージ取得成功: ${responseData['messages']?.length ?? 0}件');
        return responseData;
      } else {
        debugPrint('チャットメッセージ取得失敗: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('チャットメッセージ取得エラー: $e');
      return null;
    }
  }

  /// メッセージを送信するAPI
  static Future<Map<String, dynamic>?> sendMessage(int chatRoomId, String messageText) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/chat/rooms/$chatRoomId/messages');
      final headers = await _getHeaders();

      final body = json.encode({
        'message_text': messageText,
        'message_type': 'text',
      });

      debugPrint('メッセージ送信API呼び出し: chatRoomId=$chatRoomId, messageText=$messageText');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      debugPrint('メッセージ送信APIレスポンス: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('メッセージ送信成功: $responseData');
        return responseData;
      } else {
        debugPrint('メッセージ送信失敗: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('メッセージ送信エラー: $e');
      return null;
    }
  }

  /// チャットルーム一覧を取得するAPI
  static Future<List<Map<String, dynamic>>?> getChatRooms() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/chat/rooms');
      final headers = await _getHeaders();

      debugPrint('チャットルーム一覧取得API呼び出し');

      final response = await http.get(
        url,
        headers: headers,
      );

      debugPrint('チャットルーム一覧取得APIレスポンス: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('チャットルーム一覧取得成功: ${responseData.length}件');
        return List<Map<String, dynamic>>.from(responseData);
      } else {
        debugPrint('チャットルーム一覧取得失敗: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('チャットルーム一覧取得エラー: $e');
      return null;
    }
  }

  /// 自分のユーザー情報を取得するAPI
  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/user_info');
      final headers = await _getHeaders();

      debugPrint('ユーザー情報取得API呼び出し');

      final response = await http.get(
        url,
        headers: headers,
      );

      debugPrint('ユーザー情報取得APIレスポンス: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('ユーザー情報取得成功');
        return responseData;
      } else {
        debugPrint('ユーザー情報取得失敗: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('ユーザー情報取得エラー: $e');
      return null;
    }
  }
}