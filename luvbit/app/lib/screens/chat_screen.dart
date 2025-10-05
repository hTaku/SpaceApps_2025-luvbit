import 'package:flutter/material.dart';
import 'package:Luvbit/services/api_service.dart';
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  final int partnerId;
  final String partnerNickname;
  final String? partnerProfileImage;

  const ChatScreen({
    super.key,
    required this.partnerId,
    required this.partnerNickname,
    this.partnerProfileImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  int? _chatRoomId;
  bool _isLoading = true;
  bool _isSending = false;
  String? _myProfileImage;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// チャットの初期化
  Future<void> _initializeChat() async {
    try {
      // 自分のプロフィール画像を取得
      await _loadMyProfile();
      
      // チャットルームを作成または取得
      final chatRoomResult = await ApiService.createChatRoom(widget.partnerId);
      
      if (chatRoomResult != null && chatRoomResult['id'] != null) {
        _chatRoomId = chatRoomResult['id'];
        
        // メッセージ履歴を取得
        await _loadMessages();
      }
      
    } catch (e) {
      print('チャット初期化エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('チャットの初期化に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 自分のプロフィール情報を取得
  Future<void> _loadMyProfile() async {
    try {
      final userInfo = await ApiService.getUserInfo();
      if (userInfo != null && userInfo['profile_image'] != null) {
        setState(() {
          _myProfileImage = userInfo['profile_image'];
        });
      }
    } catch (e) {
      print('自分のプロフィール取得エラー: $e');
    }
  }

  /// メッセージ履歴を読み込み
  Future<void> _loadMessages() async {
    if (_chatRoomId == null) return;

    try {
      final result = await ApiService.getChatMessages(_chatRoomId!);
      
      if (result != null && result['messages'] != null) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(result['messages']);
          _messages = _messages.reversed.toList(); // 古い順に並び替え
        });
        
        // 最新メッセージまでスクロール
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
      
    } catch (e) {
      print('メッセージ読み込みエラー: $e');
    }
  }

  /// メッセージを送信
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatRoomId == null || _isSending) {
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      final result = await ApiService.sendMessage(_chatRoomId!, messageText);
      
      if (result != null) {
        setState(() {
          _messages.add(result);
        });
        
        // 最新メッセージまでスクロール
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
      
    } catch (e) {
      print('メッセージ送信エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('メッセージの送信に失敗しました: $e')),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  /// 相手のプロフィール画像を構築
  Widget _buildProfileImage({double size = 40}) {
    if (widget.partnerProfileImage != null && widget.partnerProfileImage!.isNotEmpty) {
      try {
        final bytes = base64Decode(widget.partnerProfileImage!);
        return CircleAvatar(
          radius: size / 2,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (e) {
        print('プロフィール画像デコードエラー: $e');
      }
    }
    
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: Colors.grey[600],
      ),
    );
  }

  /// 自分のプロフィール画像を構築
  Widget _buildMyProfileImage({double size = 40}) {
    if (_myProfileImage != null && _myProfileImage!.isNotEmpty) {
      try {
        final bytes = base64Decode(_myProfileImage!);
        return CircleAvatar(
          radius: size / 2,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (e) {
        print('自分のプロフィール画像デコードエラー: $e');
      }
    }
    
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.blue[300],
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: Colors.white,
      ),
    );
  }

  /// メッセージバブルを構築
  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final bool isMyMessage = message['is_mine'] ?? false;
    final String messageText = message['message_text'] ?? '';
    final String senderNickname = message['sender_nickname'] ?? '';
    final DateTime createdAt = DateTime.parse(message['created_at']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMyMessage) ...[
            _buildProfileImage(size: 32),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMyMessage)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Text(
                      senderNickname,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMyMessage ? const Color(0xFF2196F3) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    messageText,
                    style: TextStyle(
                      color: isMyMessage ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                  child: Text(
                    '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMyMessage) ...[
            const SizedBox(width: 8),
            _buildMyProfileImage(size: 32),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            _buildProfileImage(size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${widget.partnerNickname}さん',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // メッセージ一覧
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(
                          child: Text(
                            'まだメッセージがありません\n最初のメッセージを送ってみましょう！',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return _buildMessageBubble(_messages[index]);
                          },
                        ),
                ),
                
                // メッセージ入力エリア
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey, width: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'メッセージを入力...',
                              border: InputBorder.none,
                            ),
                            maxLines: null,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF2196F3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _isSending ? null : _sendMessage,
                          icon: _isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}