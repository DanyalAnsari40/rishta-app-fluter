import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'home_feed_screen.dart';
import '../../search/presentation/search_screen.dart';
import '../../interests/presentation/interests_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';

class MainLayoutScreen extends ConsumerStatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen> {
  int _currentIndex = 0;

  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadNotificationCount();
  }

  Future<void> _fetchUnreadNotificationCount() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get('/notifications');
      if (response.data['success'] == true) {
        setState(() {
          _unreadCount = response.data['data']['unreadCount'] ?? 0;
        });
      }
    } catch (_) {}
  }

  void _onNavigateTab(int index) {
    if (index >= 0 && index < 5) {
      setState(() => _currentIndex = index);
      if (index == 3) {
        // Clear badge count when visiting notifications tab
        setState(() => _unreadCount = 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeFeedScreen(onNavigateTab: _onNavigateTab),
      const InterestsScreen(),
      const SearchScreen(),
      const NotificationsScreen(),
      _buildMenuTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // Header AppBar matching design screenshot
  PreferredSizeWidget _buildAppBar() {
    final titles = ['Home', 'Matches', 'Search', 'Alerts', 'Menu'];

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Image.asset(
            'assets/images/rishta_logo_header.png',
            height: 34,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Rishta',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          if (_currentIndex != 0) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                titles[_currentIndex],
                style: const TextStyle(
                  color: Color(0xFF1C1C1E),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        // Notification Bell with Red Badge Dot
        GestureDetector(
          onTap: () {
            setState(() {
              _currentIndex = 3;
              _unreadCount = 0;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF1C1C1E),
                    size: 22,
                  ),
                ),
                if (_unreadCount > 0)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadCount > 9 ? '9+' : '$_unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Modern Bottom Navigation Bar matching design screenshot
  Widget _buildBottomNavBar() {
    final items = const [
      _NavItemData(activeIcon: Icons.home_rounded, inactiveIcon: Icons.home_outlined, label: 'Home'),
      _NavItemData(activeIcon: Icons.favorite_rounded, inactiveIcon: Icons.favorite_border_rounded, label: 'Matches'),
      _NavItemData(activeIcon: Icons.search_rounded, inactiveIcon: Icons.search_rounded, label: 'Search'),
      _NavItemData(activeIcon: Icons.notifications_rounded, inactiveIcon: Icons.notifications_none_rounded, label: 'Alerts'),
      _NavItemData(activeIcon: Icons.tune_rounded, inactiveIcon: Icons.menu_rounded, label: 'Menu'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 0.8),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(items.length, (index) {
              final isSelected = _currentIndex == index;
              final item = items[index];

              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _currentIndex = index),
                  splashColor: AppTheme.primary.withValues(alpha: 0.1),
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Active indicator pill bar top or active icon
                      Icon(
                        isSelected ? item.activeIcon : item.inactiveIcon,
                        color: isSelected ? AppTheme.primary : const Color(0xFF8E8E93),
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppTheme.primary : const Color(0xFF8E8E93),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 14,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTab() {
    final profileState = ref.watch(profileProvider);
    final authState = ref.watch(authProvider);

    final profile = profileState.profile;
    final fullName = profile?.basicInfo.fullName;
    final userEmail = authState.user?.email;

    final String userName = (fullName != null && fullName.isNotEmpty)
        ? fullName
        : ((userEmail != null && userEmail.isNotEmpty) ? userEmail : 'My Profile');

    String? userPhoto;
    if (profile != null && profile.photos.isNotEmpty) {
      final primary = profile.photos.firstWhere((p) => p.isPrimary, orElse: () => profile.photos.first);
      userPhoto = primary.secureUrl;
    }

    final menuItems = [
      {
        'icon': Icons.person_rounded,
        'title': 'My Profile',
        'isOutline': false,
        'onTap': () => context.push('/profile-wizard'),
      },
      {
        'icon': Icons.favorite_rounded,
        'title': 'My Matches',
        'isOutline': false,
        'onTap': () => setState(() => _currentIndex = 1),
      },
      {
        'icon': Icons.favorite_border_rounded,
        'title': 'Favorites',
        'isOutline': true,
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Favorites / Shortlist selected')),
          );
        },
      },
      {
        'icon': Icons.settings_outlined,
        'title': 'Settings',
        'isOutline': true,
        'onTap': () => context.push('/language'),
      },
      {
        'icon': Icons.help_outline_rounded,
        'title': 'Help & Support',
        'isOutline': true,
        'onTap': () {
          showAboutDialog(
            context: context,
            applicationName: 'Rishta App',
            applicationVersion: '1.0.0',
            applicationLegalese: '© 2026 Rishta Matrimony Inc. All rights reserved.',
          );
        },
      },
      {
        'icon': Icons.info_outline_rounded,
        'title': 'About Rishta',
        'isOutline': true,
        'onTap': () {
          showAboutDialog(
            context: context,
            applicationName: 'Rishta',
            applicationVersion: '1.0.0',
            children: const [
              Text('Rishta helps you find your life partner with trust, privacy, and ease.'),
            ],
          );
        },
      },
    ];

    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // 1. Profile Header Box (User Avatar, Name, Edit Profile link)
          GestureDetector(
            onTap: () => context.push('/profile-wizard'),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  // Avatar with Pink Ring Border
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: AppTheme.surfaceVariant,
                      backgroundImage: (userPhoto != null && userPhoto.isNotEmpty)
                          ? NetworkImage(userPhoto)
                          : null,
                      child: (userPhoto == null || userPhoto.isEmpty)
                          ? const Icon(Icons.person, size: 36, color: AppTheme.primary)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name & Edit Profile Link
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1E),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 2. Profile Visibility Switch Card
          Builder(
            builder: (context) {
              final bool isVisible = !(profile?.privacySettings.isPaused ?? false);
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isVisible ? const Color(0xFFFFF0F5) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isVisible ? AppTheme.primary.withValues(alpha: 0.3) : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: isVisible ? AppTheme.primary : Colors.grey.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isVisible ? 'Visible in Feed & Search' : 'Profile Hidden (Paused)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isVisible ? AppTheme.primary : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isVisible ? 'Other users can see your profile' : 'Hidden from feed & search',
                            style: TextStyle(
                              fontSize: 11,
                              color: isVisible ? AppTheme.primary.withValues(alpha: 0.8) : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isVisible,
                      activeThumbColor: AppTheme.primary,
                      onChanged: (val) async {
                        final success = await ref.read(profileProvider.notifier).saveSection('privacy-settings', {
                          'isPaused': !val,
                        });
                        if (context.mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(val
                                  ? 'Your profile is now visible to all users!'
                                  : 'Your profile is now hidden from search & feed'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // 3. Menu Item List
          ...menuItems.map((item) {
            final IconData icon = item['icon'] as IconData;
            final String title = item['title'] as String;
            final VoidCallback onTap = item['onTap'] as VoidCallback;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                onTap: onTap,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                leading: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2E),
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFC7C7CC),
                  size: 22,
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          // 3. Logout Item (Pink/Red logout button at bottom)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (mounted) {
                  context.go('/login');
                }
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              leading: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemData {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;

  const _NavItemData({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
  });
}
