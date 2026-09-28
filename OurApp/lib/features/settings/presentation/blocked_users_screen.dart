import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  bool _isLoading = true;
  List<dynamic> _blockedList = [];

  @override
  void initState() {
    super.initState();
    _fetchBlockedUsers();
  }

  Future<void> _fetchBlockedUsers() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get('/safety/block');

      if (response.data['success'] == true) {
        setState(() {
          _blockedList = response.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unblockUser(String blockedUserId) async {
    try {
      final apiClient = ApiClient();
      await apiClient.dio.delete('/safety/block/$blockedUserId');
      _fetchBlockedUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User unblocked.')),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _blockedList.isEmpty
              ? const Center(child: Text('No blocked users.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _blockedList.length,
                  itemBuilder: (context, index) {
                    final item = _blockedList[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundImage: item['primaryPhotoUrl'] != null
                              ? NetworkImage(item['primaryPhotoUrl'])
                              : null,
                          child: item['primaryPhotoUrl'] == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(item['name'] ?? 'Blocked User', style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: OutlinedButton(
                          onPressed: () => _unblockUser(item['blockedUserId']),
                          child: const Text('Unblock'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
