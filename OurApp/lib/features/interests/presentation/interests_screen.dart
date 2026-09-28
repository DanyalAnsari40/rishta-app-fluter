import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<dynamic> _interests = [];
  String _activeType = 'received';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final types = ['received', 'sent', 'accepted', 'declined'];
        setState(() => _activeType = types[_tabController.index]);
        _fetchInterests(types[_tabController.index]);
      }
    });
    _fetchInterests('received');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchInterests(String type) async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get('/interests', queryParameters: {'type': type});

      if (response.data['success'] == true) {
        setState(() {
          _interests = response.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptInterest(String interestId) async {
    try {
      final apiClient = ApiClient();
      await apiClient.dio.put('/interests/$interestId/accept');
      _fetchInterests(_activeType);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Interest accepted! You can now chat.')),
        );
      }
    } catch (_) {}
  }

  Future<void> _declineInterest(String interestId) async {
    try {
      final apiClient = ApiClient();
      await apiClient.dio.put('/interests/$interestId/decline');
      _fetchInterests(_activeType);
    } catch (_) {}
  }

  Future<void> _withdrawInterest(String interestId) async {
    try {
      final apiClient = ApiClient();
      await apiClient.dio.delete('/interests/$interestId/withdraw');
      _fetchInterests(_activeType);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.surfaceVariant,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primary,
            tabs: const [
              Tab(text: 'Received'),
              Tab(text: 'Sent'),
              Tab(text: 'Accepted'),
              Tab(text: 'Declined'),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _interests.isEmpty
                  ? Center(child: Text('No $_activeType interests.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _interests.length,
                      itemBuilder: (context, index) {
                        final item = _interests[index];
                        final target = item['targetUser'];
                        final interestId = item['interestId'];

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: target['primaryPhotoUrl'] != null
                                      ? NetworkImage(target['primaryPhotoUrl'])
                                      : null,
                                  child: target['primaryPhotoUrl'] == null ? const Icon(Icons.person) : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${target['name']}, ${target['age']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text('${target['city']} • ${target['education']}',
                                          style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                    ],
                                  ),
                                ),

                                // Action Buttons (Facebook Friend Request Style)
                                if (_activeType == 'received') ...[
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      minimumSize: const Size(60, 36),
                                    ),
                                    onPressed: () => _acceptInterest(interestId),
                                    child: const Text('Confirm', style: TextStyle(fontSize: 12)),
                                  ),
                                  const SizedBox(width: 6),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      minimumSize: const Size(60, 36),
                                      side: const BorderSide(color: Colors.grey),
                                    ),
                                    onPressed: () => _declineInterest(interestId),
                                    child: const Text('Delete', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ),
                                ] else if (_activeType == 'sent') ...[
                                  OutlinedButton(
                                    onPressed: () => _withdrawInterest(interestId),
                                    child: const Text('Withdraw', style: TextStyle(fontSize: 12)),
                                  ),
                                ] else if (_activeType == 'accepted') ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Chat Ready',
                                      style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
