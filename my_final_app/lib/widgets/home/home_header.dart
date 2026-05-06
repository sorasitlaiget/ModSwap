import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Header bar with KMUTT logo, MODSWAP text, and user avatar
class HomeHeader extends StatelessWidget {
  final VoidCallback? onAvatarTap;

  const HomeHeader({super.key, this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      // 🎯 แก้ตรงนี้ที่ 1: ลบ height: 70 ออก แล้วใช้ SafeArea + padding บนล่างแทน เพื่อไม่ให้ชนแบตเตอรี่
      padding: const EdgeInsets.only(left: 18, right: 18, top: 10, bottom: 10),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: KMUTT logo + MODSwap text/image
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ⚠️ iOS is case-sensitive — must match pubspec exactly: .PNG
                Image.asset(
                  'images/KMUTT_Logo.png',
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 50,
                    height: 50,
                  ),
                ),
                // 🎯 แก้ตรงนี้ที่ 2: เปลี่ยนจาก width: 8 เป็น width: 2 เพื่อให้ ModFont ขยับชิดซ้าย (ใกล้โลโก้มากขึ้น)
                const SizedBox(width: 0), 
                // Use ModFont image if exists, else fallback to text
                Image.asset(
                  'images/ModFont.png',
                  // 🎯 แก้ตรงนี้ที่ 3: เพิ่ม height จาก 40 เป็น 55 เพื่อให้ตัวหนังสือใหญ่ขึ้น
                  height: 50, 
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const _ModSwapText(),
                ),
              ],
            ),

            // Right: Avatar
            GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF5945A),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fallback text if ModFont image not available
class _ModSwapText extends StatelessWidget {
  const _ModSwapText();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 24,
          letterSpacing: -1,
          height: 1,
        ),
        children: [
          TextSpan(text: 'MOD', style: TextStyle(color: AppColors.orange)),
          TextSpan(text: 'Swap', style: TextStyle(color: AppColors.navy)),
        ],
      ),
    );
  }
}