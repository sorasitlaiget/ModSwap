import 'package:flutter/material.dart';
import '../../models/listing.dart';
import '../../theme/app_colors.dart';

/// Small badge showing listing state (DRAFT, SOLD, etc.)
class StateBadge extends StatelessWidget {
  final ListingState state;

  const StateBadge({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;

    switch (state) {
      case ListingState.draft:
        bg = AppColors.textGray;
        label = 'DRAFT';
        break;
      case ListingState.sold:
        bg = Colors.red.shade400;
        label = 'SOLD';
        break;
      case ListingState.published:
        bg = Colors.green.shade500;
        label = 'LIVE';
        break;
      default:
        bg = AppColors.textGray;
        label = state.displayName.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
