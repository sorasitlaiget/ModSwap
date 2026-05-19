import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Search input + filter button
///
/// Behavior:
///  - `onChanged`: called on every keystroke (for typeahead, optional)
///  - `onSubmitted`: called when user presses Enter / Return ⭐
///  - `onFilterTap`: called when user taps the filter icon
class HomeSearchBar extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilterTap;
  final TextEditingController? controller;

  const HomeSearchBar({
    super.key,
    this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted, // ⭐ กด Enter → ค้นหา
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search for books, electronics and more...',
                hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 12, color: AppColors.navy),
            ),
          ),
          GestureDetector(
            onTap: onFilterTap,
            child: const Icon(Icons.tune, color: Color(0xFF9CA3AF), size: 20),
          ),
        ],
      ),
    );
  }
}
