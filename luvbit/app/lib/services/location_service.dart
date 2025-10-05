import 'package:geolocator/geolocator.dart';

class LocationService {
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // 10メートル移動したら更新
  );

  /// 現在位置を取得する
  static Future<Position?> getCurrentPosition() async {
    try {
      // 位置情報サービスが有効かチェック
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('位置情報サービスが無効です');
        throw Exception('位置情報サービスが無効です');
      }

      // Geolocatorを使用した権限チェック
      LocationPermission permission = await Geolocator.checkPermission();
      print('現在の位置情報権限状態: $permission');

      if (permission == LocationPermission.denied) {
        // 権限が拒否されている場合、権限を要求
        permission = await Geolocator.requestPermission();
        print('権限要求後の状態: $permission');
        
        if (permission == LocationPermission.denied) {
          print('位置情報の権限が拒否されました');
          throw Exception('位置情報の権限が拒否されました');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('位置情報の権限が永続的に拒否されました');
        throw Exception('位置情報の権限が永続的に拒否されています。設定から手動で許可してください。');
      }

      print('権限チェック完了、位置情報を取得します');

      // 現在位置を取得
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('位置情報取得成功: lat=${position.latitude}, lng=${position.longitude}');
      return position;
    } catch (e) {
      print('位置情報取得エラー: $e');
      return null;
    }
  }

  /// 位置情報の変更を監視する（リアルタイム更新用）
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    );
  }

  /// 位置情報サービスの状態をチェック
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// アプリの位置情報権限状態を取得
  static Future<LocationPermission> getLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  /// 位置情報権限の詳細状態を確認
  static Future<Map<String, dynamic>> getLocationPermissionStatus() async {
    final permission = await Geolocator.checkPermission();
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    
    return {
      'permission': permission.toString(),
      'serviceEnabled': serviceEnabled,
      'canRequest': permission == LocationPermission.denied,
      'needsManualSettings': permission == LocationPermission.deniedForever,
    };
  }

  /// 権限要求を試行
  static Future<bool> requestLocationPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      print('権限要求結果: $permission');
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      print('権限要求エラー: $e');
      return false;
    }
  }

  /// 2点間の距離を計算（メートル単位）
  static double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}