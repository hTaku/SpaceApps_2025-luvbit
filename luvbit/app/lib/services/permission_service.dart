import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status == PermissionStatus.granted;
  }

  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }

  static Future<Map<String, bool>> requestAllPermissions() async {
    final locationStatus = await Permission.location.request();
    final cameraStatus = await Permission.camera.request();

    return {
      'location': locationStatus == PermissionStatus.granted,
      'camera': cameraStatus == PermissionStatus.granted,
    };
  }

  static Future<bool> checkLocationPermission() async {
    final status = await Permission.location.status;
    return status == PermissionStatus.granted;
  }

  static Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status == PermissionStatus.granted;
  }

  static Future<bool> checkAllPermissions() async {
    final locationGranted = await checkLocationPermission();
    final cameraGranted = await checkCameraPermission();
    return locationGranted && cameraGranted;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }
}