import 'package:flutter/material.dart';
import '/../theme/app_colors.dart';

/// Header bar with KMUTT logo, MODSWAP text, and user avatar
class HomeHeader extends StatelessWidget {
  final VoidCallback? onAvatarTap;

  const HomeHeader({super.key, this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      // 1. กำหนดความสูงที่แน่นอนให้เล็กลง (เช่น 80 หรือ 100)
      height: 80, 
      // 2. ลดหรือเอา padding vertical ออก เพื่อให้ Container เป็นตัวคุมความสูงแทน
      padding: const EdgeInsets.symmetric(horizontal: 18), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: KMUTT logo + MODSWAP text
          Row(
            children: [
              Image.asset(
                'images/KMUTT_Logo.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 4),
              Transform.translate(
  offset: const Offset(-120, 0),
  child: Image.asset( 
    'images/ModFont.png',
    width: 350,
    height: 320,
    fit: BoxFit.contain,
  ),
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
                    color: Colors.black.withOpacity(0.06),
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
    );
  }
}

/// "MODSWAP" inline text matching the design (M + O image + D + Swap)
/// Simplified: use logoFont image instead of inline composition
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
