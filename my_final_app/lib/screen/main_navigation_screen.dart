import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav/mod_swap_bottom_nav.dart';
import 'home_screen.dart';
import 'my_items_screen.dart';
import 'post_item_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  Future<void> _onTap(int index) async {
    if (index == 2) {
      // Post Item — open as full screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PostItemScreen()),
      );
      if (result == true && mounted) {
        // After successful post, go to My Items tab
        setState(() => _currentIndex = 1);
      }
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOut,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.015),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _buildPage(_currentIndex),
      ),
      bottomNavigationBar: ModSwapBottomNav(
        currentIndex: _currentIndex,
        notificationCount: 0,
        onTap: _onTap,
      ),
    );
  }

  Widget _buildPage(int index) {
    if (index == 0) {
      return const HomeScreen(key: ValueKey('home'));
    }
    if (index == 1) {
      return MyItemsScreen(key: ValueKey('my_items_${DateTime.now().millisecondsSinceEpoch}'));
    }
    if (index == 4) {
      return const _MenuPage(key: ValueKey('menu'));
    }
    return _PlaceholderPage(
      key: ValueKey<int>(index),
      title: ['Home', 'My Item', 'Post Item', 'Notification', 'Menu'][index],
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Coming soon',
            style: TextStyle(color: AppColors.textGray),
          ),
        ],
      ),
    );
  }
}

class _MenuPage extends StatelessWidget {
  const _MenuPage({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textGray),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.logoutRed,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthState>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthState>().profile;
    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.navy,
                child: Icon(Icons.person, size: 56, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                profile.displayName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile.email,
                style: const TextStyle(color: AppColors.textGray),
              ),
              const SizedBox(height: 32),
              _InfoCard(
                icon: Icons.badge_outlined,
                label: 'Student ID',
                value: profile.studentId ?? '-',
              ),
              const SizedBox(height: 8),
              _InfoCard(
                icon: Icons.school_outlined,
                label: 'Faculty',
                value: profile.faculty ?? '-',
              ),
              const SizedBox(height: 8),
              _InfoCard(
                icon: Icons.chat_outlined,
                label: 'Line ID',
                value: profile.lineId ?? '-',
              ),
              const SizedBox(height: 8),
              _InfoCard(
                icon: Icons.star_outline,
                label: 'Rating',
                value:
                    '${profile.rating.toStringAsFixed(1)} (${profile.totalReviews} reviews)',
              ),
              const SizedBox(height: 8),
              _InfoCard(
                icon: Icons.swap_horiz,
                label: 'Total Trades',
                value: '${profile.totalTrades}',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.logoutRed),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: AppColors.logoutBg,
                  ),
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout, color: AppColors.logoutRed),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      color: AppColors.logoutRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.softGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.navy),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
