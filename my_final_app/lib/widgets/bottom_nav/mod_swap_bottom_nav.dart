import 'package:flutter/material.dart';
import '../../theme/app_theme_ext.dart';
import 'nav_item.dart';
import 'post_item_button.dart';

/// Bottom navigation bar for ModSwap.
class ModSwapBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int notificationCount;

  const ModSwapBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: context.cardBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
              isActive: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            NavItem(
              icon: Icons.favorite_border,
              activeIcon: Icons.favorite,
              label: 'My Item',
              isActive: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            PostItemButton(onTap: () => onTap(2)),
            NavItem(
              icon: Icons.notifications_outlined,
              activeIcon: Icons.notifications,
              label: 'Notification',
              isActive: currentIndex == 3,
              onTap: () => onTap(3),
              badgeCount: notificationCount,
            ),
            NavItem(
              icon: Icons.menu,
              activeIcon: Icons.menu,
              label: 'Menu',
              isActive: currentIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}
