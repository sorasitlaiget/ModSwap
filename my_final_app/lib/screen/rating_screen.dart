import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class RatingScreen extends StatefulWidget {
  final String sellerHandle;
  final String sellerName;
  final String itemTitle;

  const RatingScreen({
    super.key,
    required this.sellerHandle,
    required this.sellerName,
    required this.itemTitle,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 0;

  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return '1.0 - Poor';
      case 2:
        return '2.0 - Not great';
      case 3:
        return '3.0 - Okay';
      case 4:
        return '4.0 - Good';
      case 5:
        return '5.0 - Excellent';
      default:
        return 'Tap a star to rate';
    }
  }

  Color _ratingColor(int index) {
    if (_rating == 0) return AppColors.textGray;
    if (index <= _rating) {
      switch (_rating) {
        case 1:
          return Colors.red;
        case 2:
          return Colors.deepOrange;
        case 3:
          return Colors.amber;
        case 4:
          return Colors.green;
        case 5:
          return AppColors.orange;
        default:
          return AppColors.orange;
      }
    }
    return AppColors.textGray;
  }

  void _submitRating() {
    if (_rating == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You rated ${widget.sellerHandle} $_rating.0 stars'),
        backgroundColor: AppColors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
    // Navigate to home, removing all previous screens
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _skipRating() {
    // Navigate to home, removing all previous screens
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'Rate your Experience',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your feedback helps the community',
                  style: TextStyle(fontSize: 14, color: AppColors.textGray),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.softGray,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.orange,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.sellerHandle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.navy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.itemTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = starIndex),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          starIndex <= _rating ? Icons.star : Icons.star_border,
                          size: 44,
                          color: _ratingColor(starIndex),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Text(
                  _ratingLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _rating == 0
                        ? AppColors.textGray
                        : _ratingColor(_rating),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 44),
                ElevatedButton(
                  onPressed: _rating == 0 ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Submit Rating',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _skipRating,
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(color: AppColors.textGray),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
