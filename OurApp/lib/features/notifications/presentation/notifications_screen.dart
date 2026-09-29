import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get('/notifications');

      if (response.data['success'] == true) {
        setState(() {
          _notifications = response.data['data']['notifications'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markRead(String notificationId, int index) async {
    try {
      final apiClient = ApiClient();
      await apiClient.dio.put('/notifications/$notificationId/read');
      setState(() {
        if (index < _notifications.length) {
          _notifications[index]['isRead'] = true;
        }
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      final apiClient = ApiClient();
      await apiClient.dio.put('/notifications/read-all');
      _fetchNotifications();
    } catch (_) {}
  }

  String _formatTimeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          // Header Bar with Mark All Read Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications & Alerts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                if (_notifications.any((n) => n['isRead'] == false))
                  GestureDetector(
                    onTap: _markAllRead,
                    child: const Text(
                      'Mark all as read',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E5EA)),

          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: _fetchNotifications,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : _notifications.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.notifications_off_outlined,
                                      size: 40,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No notifications yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Interest requests and message alerts will appear here.',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final item = _notifications[index];
                            final isRead = item['isRead'] ?? false;
                            final notificationId = item['_id']?.toString();
                            final timeAgo = _formatTimeAgo(item['createdAt']);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isRead ? Colors.white : const Color(0xFFFFF7F9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isRead ? Colors.grey.shade200 : AppTheme.primary.withOpacity(0.3),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                onTap: () {
                                  if (notificationId != null && !isRead) {
                                    _markRead(notificationId, index);
                                  }
                                },
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: item['type'] == 'new_interest'
                                        ? const Color(0xFFFFF0F5)
                                        : item['type'] == 'interest_accepted'
                                            ? const Color(0xFFE8F5E9)
                                            : const Color(0xFFF4F5F8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item['type'] == 'new_interest'
                                        ? Icons.favorite_rounded
                                        : item['type'] == 'interest_accepted'
                                            ? Icons.check_circle_rounded
                                            : Icons.notifications_rounded,
                                    color: item['type'] == 'new_interest'
                                        ? AppTheme.primary
                                        : item['type'] == 'interest_accepted'
                                            ? Colors.green.shade600
                                            : AppTheme.primary,
                                    size: 22,
                                  ),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item['title'] ?? 'Alert',
                                        style: TextStyle(
                                          fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                          fontSize: 14,
                                          color: const Color(0xFF1C1C1E),
                                        ),
                                      ),
                                    ),
                                    if (timeAgo.isNotEmpty)
                                      Text(
                                        timeAgo,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    item['body'] ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isRead ? Colors.grey.shade700 : Colors.black87,
                                    ),
                                  ),
                                ),
                                trailing: !isRead
                                    ? Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
