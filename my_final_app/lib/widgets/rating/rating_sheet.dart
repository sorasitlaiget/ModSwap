import 'package:flutter/material.dart';
import '../../services/rating_service.dart';
import '../../theme/app_colors.dart';

/// Bottom-sheet shown to the buyer when a seller marks a listing as sold.
/// Handles submit and skip, then deletes the pending rating document.
class RatingSheet extends StatefulWidget {
  final String pendingRatingId;
  final String sellerName;
  final String listingTitle;

  const RatingSheet({
    super.key,
    required this.pendingRatingId,
    required this.sellerName,
    required this.listingTitle,
  });

  @override
  State<RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<RatingSheet> {
  final _ratingService = RatingService();
  int _rating = 0;
  bool _submitting = false;

  String get _ratingLabel {
    switch (_rating) {
      case 1: return '1.0 - Poor';
      case 2: return '2.0 - Not great';
      case 3: return '3.0 - Okay';
      case 4: return '4.0 - Good';
      case 5: return '5.0 - Excellent';
      default: return 'Tap a star to rate';
    }
  }

  Color _starColor(int index) {
    if (_rating == 0 || index > _rating) return AppColors.textGray;
    switch (_rating) {
      case 1: return Colors.red;
      case 2: return Colors.deepOrange;
      case 3: return Colors.amber;
      case 4: return Colors.green;
      default: return AppColors.orange;
    }
  }

  Future<void> _submit() async {
    if (_rating == 0 || _submitting) return;
    setState(() => _submitting = true);
    try {
      await _ratingService.submitRating(
        pendingRatingId: widget.pendingRatingId,
        rating: _rating,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You rated @${widget.sellerName} $_rating.0 stars'),
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
    }
  }

  Future<void> _skip() async {
    try {
      await _ratingService.skipRating(widget.pendingRatingId);
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textGray.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Rate your Experience',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your feedback helps the community',
            style: TextStyle(fontSize: 13, color: AppColors.textGray),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.softGray,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.orange,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${widget.sellerName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.listingTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final star = index + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    size: 44,
                    color: _starColor(star),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            _ratingLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _rating == 0 ? AppColors.textGray : _starColor(_rating),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (_rating == 0 || _submitting) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Submit Rating',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _submitting ? null : _skip,
            child: const Text(
              'Skip for now',
              style: TextStyle(color: AppColors.textGray),
            ),
          ),
        ],
      ),
    );
  }
}
