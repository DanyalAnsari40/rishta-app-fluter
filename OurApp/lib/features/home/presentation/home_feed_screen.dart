import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  bool _isLoading = true;
  List<dynamic> _newMembers = [];
  List<dynamic> _feed = [];

  @override
  void initState() {
    super.initState();
    _fetchFeedData();
  }

  Future<void> _fetchFeedData() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get('/search/feed');

      if (response.data['success'] == true) {
        final data = response.data['data'];
        setState(() {
          _newMembers = data['newMembers'] ?? [];
          _feed = data['feed'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    return RefreshIndicator(
      onRefresh: _fetchFeedData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // 1. Horizontal "New Members" story row
          if (_newMembers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'New Members',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _newMembers.length,
                itemBuilder: (context, index) {
                  final m = _newMembers[index];
                  return Container(
                    width: 75,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primary, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundImage: m['primaryPhotoUrl'] != null
                                ? NetworkImage(m['primaryPhotoUrl'])
                                : null,
                            child: m['primaryPhotoUrl'] == null
                                ? const Icon(Icons.person, color: AppTheme.primary)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m['name'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
          ],

          // 2. Feed Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Recommended Matches',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),

          if (_feed.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text('No profiles found matching your preferences yet.'),
              ),
            ),

          // 3. Profile Cards Feed
          ..._feed.map((p) => _buildProfileCard(context, p)),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, Map<String, dynamic> p) {
    final photoUrl = p['primaryPhotoUrl'];
    final compatibility = p['compatibilityPercentage'] ?? 75;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Photo & Compatibility Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: photoUrl != null
                    ? Image.network(
                        photoUrl,
                        height: 260,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 220,
                        color: AppTheme.surfaceVariant,
                        child: const Center(
                          child: Icon(Icons.person, size: 80, color: AppTheme.primary),
                        ),
                      ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$compatibility% Match',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Profile Details Body
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${p['name']}, ${p['age']}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    if (p['isVerifiedBadge'] == true)
                      const Icon(Icons.verified_rounded, color: AppTheme.primary, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${p['city']} • ${p['religion']} (${p['sect']})',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${p['education']} • ${p['occupation']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Button Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Interest sent to ${p['name']}!')),
                          );
                        },
                        icon: const Icon(Icons.favorite, size: 18),
                        label: const Text('Send Interest', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${p['name']} added to Shortlist.')),
                          );
                        },
                        child: const Icon(Icons.star_border_rounded, color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
