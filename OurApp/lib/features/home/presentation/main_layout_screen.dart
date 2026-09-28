import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'home_feed_screen.dart';
import '../../search/presentation/search_screen.dart';
import '../../interests/presentation/interests_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../auth/providers/auth_provider.dart';

class MainLayoutScreen extends ConsumerStatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      const HomeFeedScreen(),
      const InterestsScreen(),
      const SearchScreen(),
      const NotificationsScreen(),
      _buildMenuTab(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: _buildGlassBottomNavBar(),
      ),
    );
  }

  Widget _buildGlassBottomNavBar() {
    final items = const [
      _NavItemData(icon: Icons.home_rounded, label: 'Home'),
      _NavItemData(icon: Icons.favorite_rounded, label: 'Matches'),
      _NavItemData(icon: Icons.search_rounded, label: 'Search'),
      _NavItemData(icon: Icons.notifications_rounded, label: 'Alerts'),
      _NavItemData(icon: Icons.grid_view_rounded, label: 'Menu'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFFF71A65).withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 1.5,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final itemWidth = totalWidth / items.length;
          final activeIndicatorLeft = _currentIndex * itemWidth + (itemWidth - 44) / 2;

          return SizedBox(
            height: 68,
            child: Stack(
              children: [
                // Sliding Animated Jelly Glass Indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack, // Spring jelly movement
                  left: activeIndicatorLeft,
                  top: 8,
                  child: _buildSlidingGlassIndicator(),
                ),

                // Navigation Item Buttons Row
                Row(
                  children: List.generate(items.length, (index) {
                    final isSelected = _currentIndex == index;
                    final item = items[index];

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _currentIndex = index),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Inactive Icon slot container
                            SizedBox(
                              width: 44,
                              height: 42,
                              child: Center(
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutBack,
                                  scale: isSelected ? 1.0 : 0.9,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 250),
                                    opacity: isSelected ? 0.0 : 1.0,
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF4F5F8),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        item.icon,
                                        color: Colors.grey.shade500,
                                        size: 21,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            // Text label with smooth animated style
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 250),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? const Color(0xFFF71A65) : Colors.grey.shade500,
                              ),
                              child: Text(item.label),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),

                // Foreground Active Icon layer positioned on top of sliding indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  left: activeIndicatorLeft,
                  top: 8,
                  child: SizedBox(
                    width: 44,
                    height: 42,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: child,
                        ),
                        child: Icon(
                          items[_currentIndex].icon,
                          key: ValueKey<int>(_currentIndex),
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlidingGlassIndicator() {
    return SizedBox(
      width: 44,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Back offset rotated translucent jelly layer
          Positioned(
            top: -2,
            right: 0,
            child: Transform.rotate(
              angle: 0.18,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF71A65).withOpacity(0.55),
                      const Color(0xFFFF528E).withOpacity(0.35),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF71A65).withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(2, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Front glass vibrant active squircle
          Positioned(
            top: 2,
            left: 0,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFF71A65),
                    Color(0xFFFF3B7B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF71A65).withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_currentIndex == 0) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            const Icon(Icons.favorite, color: Color(0xFFF71A65), size: 28),
            const SizedBox(width: 8),
            const Text(
              'Rishta',
              style: TextStyle(
                color: Color(0xFFF71A65),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.black87),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat opens when interest is mutually accepted.')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      );
    }
    
    // Default AppBar for other tabs
    final titles = ['Home', 'Interests', 'Search', 'Notifications', 'My Profile'];
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(
        titles[_currentIndex],
        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  Widget _buildMenuTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppTheme.surfaceVariant,
            child: Icon(Icons.person, color: AppTheme.primary),
          ),
          title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('View and edit your profile details'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/profile-wizard'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.star_outline_rounded, color: AppTheme.primary),
          title: const Text('Shortlist'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.tune_rounded, color: AppTheme.primary),
          title: const Text('Partner Preferences'),
          onTap: () => context.push('/profile-wizard'),
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline_rounded, color: AppTheme.primary),
          title: const Text('Privacy & Settings'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.language_rounded, color: AppTheme.primary),
          title: const Text('Change Language'),
          onTap: () => context.push('/language'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout_rounded, color: Colors.red),
          title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          onTap: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) {
              context.go('/login');
            }
          },
        ),
      ],
    );
  }
}

class PlaceholderTab extends StatelessWidget {
  final String title;
  const PlaceholderTab({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  const _NavItemData({required this.icon, required this.label});
}

