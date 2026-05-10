import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../services/wishlist_service.dart';
import '../theme/app_colors.dart';
import '../widgets/listing/listing_card_real.dart';
import 'listing_detail_screen.dart';

/// Wishlist Screen — listings the user has saved
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final _service = WishlistService();
  late Future<List<Listing>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getMyWishlist();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.getMyWishlist();
    });
  }

  Future<void> _openDetail(Listing listing) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListingDetailScreen(listingId: listing.id),
      ),
    );
    // Refresh on return — user may have unwishlisted from detail screen
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: const Text(
          'Wishlist',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Listing>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            );
          }

          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return _buildEmpty();
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.orange,
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.68,
              ),
              itemCount: items.length,
              itemBuilder: (_, index) {
                final listing = items[index];
                return ListingCard(
                  listing: listing,
                  onTap: () => _openDetail(listing),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: AppColors.textGray.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No items in your wishlist yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap ❤ on any item to save it here',
              style: TextStyle(fontSize: 13, color: AppColors.textGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 60, color: AppColors.orange),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: AppColors.navy),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
