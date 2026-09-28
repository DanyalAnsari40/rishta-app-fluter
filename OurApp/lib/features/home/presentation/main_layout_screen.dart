import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'home_feed_screen.dart';
import '../../search/presentation/search_screen.dart';
import '../../interests/presentation/interests_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';

class MainLayoutScreen extends ConsumerStatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rishta',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              _tabController.animateTo(2); // Switch to Search tab
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.textPrimary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat opens when interest is mutually accepted.')),
                  );
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.home_rounded), text: 'Home'),
            Tab(icon: Icon(Icons.favorite_rounded), text: 'Interests'),
            Tab(icon: Icon(Icons.search_rounded), text: 'Search'),
            Tab(icon: Icon(Icons.notifications_rounded), text: 'Alerts'),
            Tab(icon: Icon(Icons.menu_rounded), text: 'Menu'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const HomeFeedScreen(),
          const InterestsScreen(),
          const SearchScreen(),
          const NotificationsScreen(),
          _buildMenuTab(context),
        ],
      ),
    );
  }

  Widget _buildMenuTab(BuildContext context) {
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
          onTap: () {
            context.go('/login');
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
