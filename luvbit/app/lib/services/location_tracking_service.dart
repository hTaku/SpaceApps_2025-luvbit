import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'api_service.dart';

class LocationTrackingService {
  static LocationTrackingService? _instance;
  static LocationTrackingService get instance => _instance ??= LocationTrackingService._();
  
  LocationTrackingService._();

  Timer? _locationTimer;
  bool _isTracking = false;
  Position? _lastPosition;

  /// 位置情報追跡が開始されているかどうか
  bool get isTracking => _isTracking;

  /// 最後に取得した位置情報
  Position? get lastPosition => _lastPosition;

  /// 位置情報の定期送信を開始（1分間隔）
  Future<void> startTracking() async {
    if (_isTracking) {
      print('位置情報追跡は既に開始されています');
      return;
    }

    print('位置情報追跡を開始します');
    _isTracking = true;

    // 初回の位置情報を即座に送信
    await _sendCurrentLocation();

    // 1分間隔で位置情報を送信
    _locationTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) async {
        await _sendCurrentLocation();
      },
    );
  }

  /// 位置情報の定期送信を停止
  void stopTracking() {
    if (!_isTracking) {
      print('位置情報追跡は既に停止されています');
      return;
    }

    print('位置情報追跡を停止します');
    _isTracking = false;
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  /// 現在位置を取得してAPIに送信
  Future<void> _sendCurrentLocation() async {
    try {
      print('現在位置を取得中...');
      
      // 権限状態の詳細確認
      final permissionStatus = await LocationService.getLocationPermissionStatus();
      print('権限状態詳細: $permissionStatus');
      
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        print('位置情報の取得に失敗しました');
        return;
      }

      _lastPosition = position;
      print('位置情報取得成功: lat=${position.latitude}, lng=${position.longitude}');

      // APIに位置情報を送信
      final result = await ApiService.registUserPosition(
        lat: position.latitude,
        lng: position.longitude,
      );

      if (result != null) {
        print('位置情報の送信に成功しました: $result');
      } else {
        print('位置情報の送信に失敗しました');
      }
    } catch (e) {
      print('位置情報送信エラー: $e');
      
      // 権限エラーの場合は詳細情報を出力
      if (e.toString().contains('権限')) {
        final permissionStatus = await LocationService.getLocationPermissionStatus();
        print('権限エラー詳細: $permissionStatus');
      }
    }
  }

  /// 手動で現在位置を送信
  Future<bool> sendLocationNow() async {
    try {
      print('手動で位置情報を送信します');
      
      // 権限状態の詳細確認
      final permissionStatus = await LocationService.getLocationPermissionStatus();
      print('権限状態詳細: $permissionStatus');
      
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        print('位置情報の取得に失敗しました');
        return false;
      }

      _lastPosition = position;
      print('位置情報取得成功: lat=${position.latitude}, lng=${position.longitude}');

      // APIに位置情報を送信
      final result = await ApiService.registUserPosition(
        lat: position.latitude,
        lng: position.longitude,
      );

      if (result != null) {
        print('位置情報の送信に成功しました: $result');
        return true;
      } else {
        print('位置情報の送信に失敗しました');
        return false;
      }
    } catch (e) {
      print('位置情報送信エラー: $e');
      
      // 権限エラーの場合は詳細情報を出力
      if (e.toString().contains('権限')) {
        final permissionStatus = await LocationService.getLocationPermissionStatus();
        print('権限エラー詳細: $permissionStatus');
      }
      return false;
    }
  }

  /// サービスを完全に終了
  void dispose() {
    stopTracking();
    _instance = null;
  }
}