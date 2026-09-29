import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../profile/presentation/profile_detail_screen.dart';
import '../../chat/presentation/chat_screen.dart';


class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _interests = [];
  String _activeType = 'received';
  String _searchQuery = '';

  final List<Map<String, String>> _tabs = const [
    {'key': 'received', 'label': 'Received'},
    {'key': 'sent', 'label': 'Sent'},
    {'key': 'accepted', 'label': 'Accepted'},
    {'key': 'declined', 'label': 'Declined'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final selectedType = _tabs[_tabController.index]['key']!;
        setState(() {
          _activeType = selectedType;
          _searchQuery = '';
          _searchController.clear();
        });
        _fetchInterests(selectedType);
      }
    });
    _fetchInterests('received');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
      final response = await apiClient.dio.put('/interests/$interestId/accept');
      _fetchInterests(_activeType);

      if (mounted && response.data['success'] == true) {
        final data = response.data['data'] ?? {};
        final partnerName = data['partnerName'] ?? 'Member';
        final conversationId = data['conversationId']?.toString();
        final partnerUserId = data['partnerUserId']?.toString();
        final partnerPhotoUrl = data['partnerPhotoUrl'];

        _showConnectionSuccessfulDialog(
          context: context,
          name: partnerName,
          conversationId: conversationId,
          targetUserId: partnerUserId,
          photoUrl: partnerPhotoUrl,
        );
      }
    } catch (_) {}
  }

  void _showConnectionSuccessfulDialog({
    required BuildContext context,
    required String name,
    required String? conversationId,
    required String? targetUserId,
    required String? photoUrl,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded, color: Color(0xFFF71A65), size: 36),
            ),
            const SizedBox(height: 12),
            const Text(
              'Connection Successful! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
            ),
          ],
        ),
        content: Text(
          'You and $name are now connected! Mutual interest has been confirmed and saved.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.black.withValues(alpha: 0.7), height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          if (conversationId != null && targetUserId != null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF71A65),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
              label: const Text('Start Chat Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      conversationId: conversationId,
                      extraData: {
                        'targetUserId': targetUserId,
                        'name': name,
                        'primaryPhotoUrl': photoUrl,
                      },
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
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
    final filteredInterests = _interests.where((item) {
      if (_searchQuery.trim().isEmpty) return true;
      final target = item['targetUser'] ?? {};
      final name = (target['name'] ?? '').toString().toLowerCase();
      final city = (target['city'] ?? '').toString().toLowerCase();
      final q = _searchQuery.trim().toLowerCase();
      return name.contains(q) || city.contains(q);
    }).toList();

    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          // Header Card with Custom Tab Pills & Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // Custom Tab Pills
                Container(
                  height: 44,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: List.generate(_tabs.length, (index) {
                      final isSelected = _tabController.index == index;
                      final tab = _tabs[index];

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _tabController.animateTo(index);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [Color(0xFFF71A65), Color(0xFFFF528E)],
                                    )
                                  : null,
                              color: isSelected ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFF71A65).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                tab['label']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),

                // Search Bar inside Interests Header
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search ${_activeType} requests...',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Count Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: Row(
              children: [
                Text(
                  _isLoading ? 'Loading...' : '${filteredInterests.length} Requests',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Content List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF71A65)))
                : filteredInterests.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        itemCount: filteredInterests.length,
                        itemBuilder: (context, index) {
                          final item = filteredInterests[index];
                          return _buildInterestCard(item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF71A65).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_border_rounded, size: 44, color: Color(0xFFF71A65)),
          ),
          const SizedBox(height: 16),
          Text(
            'No $_activeType interests',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            'When you $_activeType requests, they will show up here.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestCard(Map<String, dynamic> item) {
    final target = item['targetUser'] ?? {};
    final interestId = item['interestId']?.toString() ?? '';
    final conversationId = item['conversationId']?.toString();
    final name = target['name'] ?? 'Member';

    return GestureDetector(
      onTap: () {
        if (_activeType == 'accepted') {
          _showConnectionSuccessfulDialog(
            context: context,
            name: name,
            conversationId: conversationId,
            targetUserId: target['userId']?.toString(),
            photoUrl: target['primaryPhotoUrl'],
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileDetailScreen(profileData: target),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Profile photo with gradient border
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF71A65), Color(0xFFFF528E)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: target['primaryPhotoUrl'] != null
                      ? NetworkImage(target['primaryPhotoUrl'])
                      : null,
                  child: target['primaryPhotoUrl'] == null
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(width: 12),

              // Profile info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${target['name'] ?? 'Member'}, ${target['age'] ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${target['city'] ?? 'Pakistan'} • ${target['education'] ?? 'Educated'}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Action Buttons
              if (_activeType == 'received') ...[
                GestureDetector(
                  onTap: () => _acceptInterest(interestId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF71A65), Color(0xFFFF4884)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF71A65).withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _declineInterest(interestId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      'Decline',
                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ),
              ] else if (_activeType == 'sent') ...[
                GestureDetector(
                  onTap: () => _withdrawInterest(interestId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      'Withdraw',
                      style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ),
              ] else if (_activeType == 'accepted') ...[
                GestureDetector(
                  onTap: () {
                    _showConnectionSuccessfulDialog(
                      context: context,
                      name: name,
                      conversationId: conversationId,
                      targetUserId: target['userId']?.toString(),
                      photoUrl: target['primaryPhotoUrl'],
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF71A65).withOpacity(0.12),
                          const Color(0xFFFF528E).withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF71A65).withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFFF71A65)),
                        SizedBox(width: 4),
                        Text(
                          'Connected',
                          style: TextStyle(color: Color(0xFFF71A65), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (_activeType == 'declined') ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Declined',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
