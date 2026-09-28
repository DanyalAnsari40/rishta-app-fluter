import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class ShortlistScreen extends StatefulWidget {
  const ShortlistScreen({super.key});

  @override
  State<ShortlistScreen> createState() => _ShortlistScreenState();
}

class _ShortlistScreenState extends State<ShortlistScreen> {
  bool _isLoading = true;
  List<dynamic> _shortlist = [];

  @override
  void initState() {
    super.initState();
    _fetchShortlist();
  }

  Future<void> _fetchShortlist() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get('/shortlist');

      if (response.data['success'] == true) {
        setState(() {
          _shortlist = response.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFromShortlist(String targetUserId) async {
    try {
      final apiClient = ApiClient();
      await apiClient.dio.delete('/shortlist/$targetUserId');
      _fetchShortlist();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shortlist'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _shortlist.isEmpty
              ? const Center(child: Text('No shortlisted profiles yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _shortlist.length,
                  itemBuilder: (context, index) {
                    final item = _shortlist[index];
                    final p = item['profile'];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundImage: p['primaryPhotoUrl'] != null
                              ? NetworkImage(p['primaryPhotoUrl'])
                              : null,
                          child: p['primaryPhotoUrl'] == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text('${p['name']}, ${p['age']}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${p['city']} • ${p['occupation']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.star_rounded, color: AppTheme.primary),
                          onPressed: () => _removeFromShortlist(item['targetUserId']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
