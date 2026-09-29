import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const HomeFeedScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  bool _isLoading = true;
  List<dynamic> _featuredProfiles = [];
  List<dynamic> _recommendedFeed = [];
  final Set<String> _shortlistedIds = {};

  // Static fallback featured profiles matching design screenshot
  final List<Map<String, dynamic>> _fallbackFeatured = [
    {
      'id': 'f1',
      'name': 'Ayesha Khan',
      'age': 28,
      'city': 'Lahore',
      'image': 'assets/images/ayesha_khan.jpg',
      'isAsset': true,
      'religion': 'Sunni',
      'education': 'M.Sc Software Engineering',
      'occupation': 'UI/UX Designer',
    },
    {
      'id': 'f2',
      'name': 'Usman Ali',
      'age': 31,
      'city': 'Karachi',
      'image': 'assets/images/usman_ali.jpg',
      'isAsset': true,
      'religion': 'Sunni',
      'education': 'MBA Finance',
      'occupation': 'Investment Banker',
    },
    {
      'id': 'f3',
      'name': 'Anum Shah',
      'age': 26,
      'city': 'Islamabad',
      'image': 'assets/images/ayesha_khan.jpg',
      'isAsset': true,
      'religion': 'Sunni',
      'education': 'B.D.S Doctor',
      'occupation': 'Dentist',
    },
  ];

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
        final apiMembers = data['newMembers'] ?? [];
        final apiFeed = data['feed'] ?? [];

        setState(() {
          _featuredProfiles = apiMembers.isNotEmpty ? apiMembers : _fallbackFeatured;
          _recommendedFeed = apiFeed;
          _isLoading = false;
        });
      } else {
        setState(() {
          _featuredProfiles = _fallbackFeatured;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _featuredProfiles = _fallbackFeatured;
          _isLoading = false;
        });
      }
    }
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (_shortlistedIds.contains(id)) {
        _shortlistedIds.remove(id);
      } else {
        _shortlistedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchFeedData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // 1. Hero Banner ("Real Connections Start Here")
          _buildHeroBanner(context),

          const SizedBox(height: 16),

          // 2. Quick Actions Row (Matches, Search, Alerts, Profile)
          _buildQuickActionGrid(context),

          const SizedBox(height: 20),

          // 3. Featured Profiles Section
          _buildFeaturedProfilesSection(context),

          const SizedBox(height: 20),

          // 4. Recommended Matches Section (if available from API feed or items)
          if (_recommendedFeed.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recommended Matches',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                  ),
                ],
              ),
            ),
            ..._recommendedFeed.map((p) => _buildProfileCard(context, p)),
          ],
        ],
      ),
    );
  }

  // 1. Hero Banner Component
  Widget _buildHeroBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 220,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              Image.asset(
                'assets/images/hero_banner.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF1C1C1E),
                ),
              ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.45),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),

              // Banner Content Text & Search Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Real Connections\nStart Here',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Find your life partner with trust,\nprivacy and ease.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (widget.onNavigateTab != null) {
                            widget.onNavigateTab!(2); // Navigate to Search tab (index 2)
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        icon: const Icon(Icons.search_rounded, size: 20, color: Colors.white),
                        label: const Text(
                          'Search Matches',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
      ),
    );
  }

  // 2. Quick Action Buttons Row (Matches, Search, Alerts, Profile)
  Widget _buildQuickActionGrid(BuildContext context) {
    final actions = [
      {
        'label': 'Matches',
        'icon': Icons.favorite_rounded,
        'hasBadge': true,
        'iconColor': AppTheme.primary,
        'tabIndex': 1,
      },
      {
        'label': 'Search',
        'icon': Icons.search_rounded,
        'hasBadge': false,
        'iconColor': AppTheme.primary,
        'tabIndex': 2,
      },
      {
        'label': 'Alerts',
        'icon': Icons.notifications_rounded,
        'hasBadge': true,
        'iconColor': AppTheme.primary,
        'tabIndex': 3,
      },
      {
        'label': 'Profile',
        'icon': Icons.person_rounded,
        'hasBadge': false,
        'iconColor': const Color(0xFFF57C00), // Warm orange/pink icon accent
        'tabIndex': 4,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: actions.map((item) {
          final int tabIndex = item['tabIndex'] as int;
          final IconData iconData = item['icon'] as IconData;
          final Color iconColor = item['iconColor'] as Color;
          final bool hasBadge = item['hasBadge'] as bool;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(tabIndex);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F5), // Soft pastel pink surface tint
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          iconData,
                          color: iconColor,
                          size: 26,
                        ),
                        if (hasBadge)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFFFF0F5), width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['label'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2C2E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 3. Featured Profiles Section
  Widget _buildFeaturedProfilesSection(BuildContext context) {
    final profiles = _featuredProfiles.isNotEmpty ? _featuredProfiles : _fallbackFeatured;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Profiles',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: const Color(0xFF1C1C1E),
                    ),
              ),
              GestureDetector(
                onTap: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(2); // Navigate to Search tab
                  }
                },
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Horizontal Profiles Scroll List
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final p = profiles[index];
              final String id = p['id']?.toString() ?? 'p_$index';
              final String name = p['name'] ?? 'Profile';
              final dynamic age = p['age'] ?? 25;
              final String city = p['city'] ?? 'Pakistan';
              final String imagePath = p['image'] ?? 'assets/images/ayesha_khan.jpg';
              final String? photoUrl = p['primaryPhotoUrl'];
              final isFav = _shortlistedIds.contains(id);

              return Container(
                width: 155,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Image with Floating Favorite Heart Badge
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: photoUrl != null
                              ? Image.network(
                                  photoUrl,
                                  height: 145,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildFallbackImage(imagePath),
                                )
                              : _buildFallbackImage(imagePath),
                        ),

                        // Floating Pink Heart Action Badge
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _toggleFavorite(id),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isFav ? Colors.white : AppTheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isFav ? Icons.favorite_rounded : Icons.favorite_rounded,
                                color: isFav ? AppTheme.primary : Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Details
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$age • $city',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackImage(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        height: 145,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 145,
          color: AppTheme.surfaceVariant,
          child: const Center(
            child: Icon(Icons.person, size: 48, color: AppTheme.primary),
          ),
        ),
      );
    }
    return Container(
      height: 145,
      color: AppTheme.surfaceVariant,
      child: const Center(
        child: Icon(Icons.person, size: 48, color: AppTheme.primary),
      ),
    );
  }

  // 4. Feed Profile Card for Recommended Matches
  Widget _buildProfileCard(BuildContext context, Map<String, dynamic> p) {
    final photoUrl = p['primaryPhotoUrl'];
    final compatibility = p['compatibilityPercentage'] ?? 85;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
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
                        height: 240,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 200,
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
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
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    if (p['isVerifiedBadge'] == true)
                      const Icon(Icons.verified_rounded, color: AppTheme.primary, size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${p['city'] ?? 'Pakistan'} • ${p['religion'] ?? 'Islam'}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
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
