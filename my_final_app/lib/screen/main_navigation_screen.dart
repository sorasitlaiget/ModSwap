import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/theme_provider.dart';
import '../services/listings_service.dart';
import '../services/rating_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_ext.dart';
import '../widgets/bottom_nav/mod_swap_bottom_nav.dart';
import '../widgets/home/home_header.dart';
import '../widgets/rating/rating_sheet.dart';
import 'home_screen.dart';
import 'my_items_screen.dart';
import 'notification_screen.dart';
import 'post_item_screen.dart';
import 'wishlist_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final _ratingService = RatingService();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ratingSubscription;
  bool _showingRatingPopup = false;
  QuerySnapshot<Map<String, dynamic>>? _latestRatingSnapshot;
  // Listings already shown this session — prevents re-showing if duplicate doc
  // hasn't been deleted from Firestore yet when the next snapshot fires.
  final _handledListingIds = <String>{};

  @override
  void initState() {
    super.initState();
    _listenPendingRatings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && mounted) {
        context.read<NotificationProvider>().init(uid);
      }
    });
  }

  @override
  void dispose() {
    _ratingSubscription?.cancel();
    super.dispose();
  }

  void _listenPendingRatings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _ratingSubscription = _ratingService.pendingRatingsStream(uid).listen((
      snapshot,
    ) {
      _latestRatingSnapshot = snapshot;
      if (!_showingRatingPopup) _maybeShowRating();
    });
  }

  void _maybeShowRating() {
    final snapshot = _latestRatingSnapshot;
    if (snapshot == null || snapshot.docs.isEmpty || _showingRatingPopup) {
      return;
    }

    // Deduplicate by listingId — keep the first doc per listing,
    // delete any extras left over from old-format documents.
    final seenListingIds = <String>{};
    QueryDocumentSnapshot<Map<String, dynamic>>? docToShow;

    for (final doc in snapshot.docs) {
      final listingId = (doc.data()['listingId'] as String?) ?? doc.id;
      if (_handledListingIds.contains(listingId) ||
          seenListingIds.contains(listingId)) {
        _ratingService.skipRating(
          doc.id,
        ); // silently delete handled or duplicate
      } else {
        seenListingIds.add(listingId);
        docToShow ??= doc;
      }
    }

    if (docToShow == null) return;

    final listingIdToShow =
        (docToShow.data()['listingId'] as String?) ?? docToShow.id;
    _handledListingIds.add(
      listingIdToShow,
    ); // mark before showing — prevents re-show if doc lingers
    final data = docToShow.data();
    _showingRatingPopup = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _showingRatingPopup = false;
        return;
      }
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => RatingSheet(
          pendingRatingId: docToShow!.id,
          sellerName: data['sellerName'] as String? ?? '',
          listingTitle: data['listingTitle'] as String? ?? '',
        ),
      ).then((_) {
        _showingRatingPopup = false;
      });
    });
  }

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
      backgroundColor: context.appBg,
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
        notificationCount: context.watch<NotificationProvider>().unreadCount,
        onTap: _onTap,
      ),
    );
  }

  Widget _buildPage(int index) {
    if (index == 0) {
      return const HomeScreen(key: ValueKey('home'));
    }
    if (index == 1) {
      return MyItemsScreen(
        key: ValueKey('my_items_${DateTime.now().millisecondsSinceEpoch}'),
      );
    }
    if (index == 3) {
      // ← เพิ่ม block นี้
      return const NotificationScreen(key: ValueKey('notification'));
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

// ===========================================================================
// MENU PAGE — redesigned to match Figma reference
// (profile card + stats row + MY ACTIVITY list + Logout)
// ===========================================================================
class _MenuPage extends StatefulWidget {
  const _MenuPage({super.key});

  @override
  State<_MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<_MenuPage> {
  final _listingsService = ListingsService();
  int? _itemsCount; // null = loading; int = loaded

  @override
  void initState() {
    super.initState();
    _loadItemsCount();
  }

  Future<void> _loadItemsCount() async {
    try {
      // Backend caps limit at 50.
      final all = await _listingsService.getMyListings(state: 'all', limit: 50);
      if (!mounted) return;
      setState(() => _itemsCount = all.length);
    } catch (_) {
      if (!mounted) return;
      setState(() => _itemsCount = 0);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
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
      backgroundColor: context.appBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── White top header: same widget used on Home page ──────────────
            const HomeHeader(),

            // ── Navy section: profile summary + stats ────────────────────────
            Container(
              width: double.infinity,
              color: AppColors.navy,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                children: [
                  _ProfileSummaryCard(
                    displayName: profile.displayName,
                    email: profile.email,
                    studentId: profile.studentId,
                    onEdit: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                      if (updated == true && context.mounted) {
                        // Profile already updated in AuthState; widget will rebuild.
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: _itemsCount?.toString() ?? '…',
                          label: 'Items',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: profile.rating.toStringAsFixed(1),
                          label: 'Rating',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: '${profile.totalTrades}',
                          label: 'Deals',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Light section: activity list + logout ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(title: 'MY ACTIVITY'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _MenuRow(
                          icon: Icons.favorite_border,
                          label: 'Wishlist',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WishlistScreen(),
                              ),
                            );
                          },
                        ),
                        const _RowDivider(),
                        _MenuRow(
                          icon: Icons.lock_outline,
                          label: 'Change Password',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChangePasswordScreen(),
                              ),
                            );
                          },
                        ),
                        const _RowDivider(),
                        // Dark Mode toggle — uses ThemeProvider to switch themes app-wide.
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, _) {
                            return _MenuRow(
                              icon: Icons.dark_mode_outlined,
                              label: 'Dark Mode',
                              onTap: () =>
                                  themeProvider.toggle(!themeProvider.isDark),
                              trailing: Switch(
                                value: themeProvider.isDark,
                                onChanged: themeProvider.toggle,
                                activeThumbColor: Colors.white,
                                activeTrackColor: AppColors.orange,
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: const Color(0xFFD1D5DB),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Logout button (centered, pill-shaped)
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(
                        Icons.logout,
                        color: AppColors.logoutRed,
                        size: 20,
                      ),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: AppColors.logoutRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.logoutBg,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 36,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
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
    );
  }
}

/// White profile card sitting on the navy section.
/// Avatar + name + email + ID + Edit button.
class _ProfileSummaryCard extends StatelessWidget {
  final String displayName;
  final String email;
  final String? studentId;
  final VoidCallback onEdit;

  const _ProfileSummaryCard({
    required this.displayName,
    required this.email,
    required this.studentId,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.orange,
            child: Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.primaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(color: context.secondaryText, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                if (studentId != null && studentId!.isNotEmpty)
                  Text(
                    'ID: $studentId',
                    style: TextStyle(
                      color: context.secondaryText,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.logoutBg,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onEdit,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Edit',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single navy-tinted stat card used in the row (Items / Rating / Swaps).
class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2966), // slightly lighter navy
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Small uppercase label above a grouped menu card (e.g., "MY ACTIVITY").
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textGray,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Single row inside a grouped menu card.
/// Default trailing is a chevron arrow; pass [trailing] to override
/// (e.g. a Switch for the Dark Mode toggle).
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final tail =
        trailing ??
        const Icon(Icons.chevron_right, color: AppColors.textGray, size: 22);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: trailing != null ? 6 : 14,
        ),
        child: Row(
          children: [
            Icon(icon, color: context.primaryText, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: context.primaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            tail,
          ],
        ),
      ),
    );
  }
}

/// Thin divider line between rows in a grouped menu card.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 52),
      color: context.divider,
    );
  }
}
