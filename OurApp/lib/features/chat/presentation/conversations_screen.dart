import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  bool _isLoading = true;
  List<dynamic> _conversations = [];
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
    
    // Poll for conversation list updates every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchConversations(isBackground: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchConversations({bool isBackground = false}) async {
    if (!isBackground) setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get('/chat/conversations');

      if (response.data['success'] == true) {
        setState(() {
          _conversations = response.data['data'] ?? [];
          if (!isBackground) _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !isBackground) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _conversations.isEmpty
              ? const Center(
                  child: Text('No active conversations yet.\nAccept an interest to start chatting!',
                      textAlign: TextAlign.center),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final c = _conversations[index];
                    final unread = (c['unreadCount'] ?? 0) > 0;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundImage: c['primaryPhotoUrl'] != null
                            ? NetworkImage(c['primaryPhotoUrl'])
                            : null,
                        child: c['primaryPhotoUrl'] == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(
                        c['name'] ?? 'Member',
                        style: TextStyle(
                          fontWeight: unread ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        c['lastMessage'] ?? 'No messages yet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unread ? AppTheme.textPrimary : AppTheme.textSecondary,
                          fontWeight: unread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: unread
                          ? Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                      onTap: () {
                        context.push(
                          '/chat/${c['conversationId']}',
                          extra: {
                            'targetUserId': c['targetUserId'],
                            'name': c['name'],
                            'primaryPhotoUrl': c['primaryPhotoUrl'],
                          },
                        );
                      },
                    );
                  },
                ),
    );
  }
}
