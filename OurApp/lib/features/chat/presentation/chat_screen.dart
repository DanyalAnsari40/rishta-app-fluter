import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> extraData;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.extraData,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _messages = [];
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _initChatSession();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChatSession() async {
    await _fetchMessages();
    
    // Auto refresh messages every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchMessages(isBackground: true);
    });
  }

  Future<void> _fetchMessages({bool isBackground = false}) async {
    try {
      final apiClient = ApiClient();
      final res = await apiClient.dio.get('/chat/conversations/${widget.conversationId}/messages');
      if (res.data['success'] == true) {
        final rawMsgs = res.data['data']['messages'] as List<dynamic>;
        
        if (_messages.length != rawMsgs.length) {
          setState(() {
            _messages = rawMsgs.map((e) => Map<String, dynamic>.from(e)).toList();
            _isLoading = false;
          });
          _scrollToBottom();
        } else if (!isBackground) {
          setState(() => _isLoading = false);
        }
      }
    } catch (_) {
      if (mounted && !isBackground) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final targetUserId = widget.extraData['targetUserId'];
    final now = DateTime.now();
    
    // Optimistic UI update
    final tempMsg = {
      'senderId': 'me',
      'receiverId': targetUserId,
      'content': text,
      'createdAt': now.toIso8601String(),
      'read': false,
    };
    
    setState(() {
      _messages.add(tempMsg);
    });
    _scrollToBottom();
    _messageController.clear();

    try {
      final apiClient = ApiClient();
      await apiClient.dio.post(
        '/chat/conversations/${widget.conversationId}/messages',
        data: {
          'receiverId': targetUserId,
          'content': text,
        },
      );
      _fetchMessages(isBackground: true);
    } catch (e) {
      debugPrint("Failed to send message: $e");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(dynamic rawTime) {
    if (rawTime == null) return '9:30 AM';
    try {
      final dt = DateTime.parse(rawTime.toString()).toLocal();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return '9:30 AM';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.extraData['name'] ?? 'Ayesha Khan';
    final photoUrl = widget.extraData['primaryPhotoUrl'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1C1C1E)),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            // User Avatar with Online Dot Indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null || photoUrl.isEmpty
                      ? const Icon(Icons.person, size: 22, color: Color(0xFFF71A65))
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CD964),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: Color(0xFF4CD964)),
                    SizedBox(width: 4),
                    Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E8E93),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF1C1C1E)),
            onPressed: () {
              _showChatOptions(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFF71A65)))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe = msg['senderId'] != widget.extraData['targetUserId'] || msg['senderId'] == 'me';
                        final text = msg['content'] ?? msg['text'] ?? '';
                        final timeStr = _formatTime(msg['createdAt']);
                        final isRead = msg['read'] == true;

                        return _buildChatBubble(text, isMe, timeStr, isRead);
                      },
                    ),
            ),

            // Bottom Input Bar Matching Screenshot Design
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Row(
                children: [
                  // Text Input Pill Container with Attachment Icon
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F5F8),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attach_file_rounded,
                            color: Color(0xFF8E8E93),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              onSubmitted: (_) => _sendMessage(),
                              style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E)),
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(color: Color(0xFFA2A2A8), fontSize: 14),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Circular Pink Send Button
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF71A65),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x3BF71A65),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isMe, String timeStr, bool isRead) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Speech Bubble Box
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFFF71A65) : const Color(0xFFF2F3F5),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFF1C1C1E),
                fontSize: 14.5,
                height: 1.35,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Time Stamp & Checkmark Ticks
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8E8E93),
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.done_all_rounded,
                  size: 14,
                  color: isRead ? const Color(0xFFF71A65) : const Color(0xFF8E8E93),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('View Profile'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_outlined, color: Colors.red),
                title: const Text('Block User', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
