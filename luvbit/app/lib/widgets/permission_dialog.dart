import 'package:flutter/material.dart';
import '../services/permission_service.dart';

class PermissionDialog extends StatelessWidget {
  final VoidCallback? onPermissionsGranted;
  final VoidCallback? onLater;

  const PermissionDialog({
    super.key, 
    this.onPermissionsGranted,
    this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'アプリの権限許可',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('このアプリを使用するために、以下の権限が必要です：'),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(child: Text('位置情報\n相手との距離を測定するため')),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.green),
              SizedBox(width: 8),
              Expanded(child: Text('カメラ\nプロフィール写真の撮影のため')),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onLater?.call();
          },
          child: const Text('後で'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            final permissions = await PermissionService.requestAllPermissions();
            
            if (permissions['location'] == true && permissions['camera'] == true) {
              onPermissionsGranted?.call();
            } else {
              _showPermissionDeniedDialog(context);
            }
          },
          child: const Text('許可する'),
        ),
      ],
    );
  }

  static void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('権限が必要です'),
        content: const Text('アプリの機能を完全に利用するには、設定から権限を有効にしてください。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              PermissionService.openSettings();
            },
            child: const Text('設定を開く'),
          ),
        ],
      ),
    );
  }
}