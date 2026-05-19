import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Navy welcome banner with user name and mascot illustration
class WelcomeBanner extends StatelessWidget {
  final String userName;

  const WelcomeBanner({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 64),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Welcome text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    children: [
                      const TextSpan(text: 'Welcome, '),
                      TextSpan(
                        text: '$userName!',
                        style: const TextStyle(color: AppColors.orange),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'What do you need to buying today?',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Mascot — fixed to use ModSwap.png (uppercase to match pubspec.yaml)
          Image.asset(
            'images/ModSwap.png',
            width: 110,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox(width: 110, height: 80),
          ),
        ],
      ),
    );
  }
}
