import 'package:flutter/material.dart';
import '/../theme/app_colors.dart';

class HomeCategory {
  final String key;
  final String label;
  const HomeCategory({required this.key, required this.label});
}

class CategoryChips extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  static const List<HomeCategory> categories = [
    HomeCategory(key: 'all', label: 'All Items'),
    HomeCategory(key: 'textbooks', label: 'Textbooks'),
    HomeCategory(key: 'electronics', label: 'Electronics'),
    HomeCategory(key: 'fashion', label: 'Fashion'),
    HomeCategory(key: 'dorm', label: 'Housing/Dorm'),
    HomeCategory(key: 'vehicles', label: 'Vehicles'),
  ];

  const CategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, i) {
          final c = categories[i];
          final isActive = c.key == selectedCategory;
          return GestureDetector(
            onTap: () => onCategoryChanged(c.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isActive ? AppColors.navy : Colors.white,
                border: Border.all(
                  color: isActive ? AppColors.navy : const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  c.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppColors.navy,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
