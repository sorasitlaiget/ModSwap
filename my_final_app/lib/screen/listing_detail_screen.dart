import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/listing.dart';
import '../services/listings_service.dart';
import '../theme/app_colors.dart';
import '../widgets/listing/state_badge.dart';
import 'post_item_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// Detail screen — view full listing info
class ListingDetailScreen extends StatefulWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final _service = ListingsService();
  Listing? _listing;
  bool _loading = true;
  String? _error;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final l = await _service.getById(widget.listingId);
      if (!mounted) return;
      setState(() {
        _listing = l;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool get _isOwner {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && _listing?.ownerId == uid;
  }

  // ============================================================
  // Owner actions
  // ============================================================

  Future<void> _edit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostItemScreen(existing: _listing!),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _publish() async {
    setState(() => _loading = true);
    try {
      await _service.publish(_listing!.id);
      await _load();
      if (mounted) _showSuccess('Listing published!');
    } catch (e) {
      if (mounted) _showError(e.toString());
      setState(() => _loading = false);
    }
  }

  Future<void> _markSold() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Sold?'),
        content: const Text(
          'This listing will be marked as sold and removed from the home feed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
            child: const Text('Mark Sold',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await _service.markSold(_listing!.id);
      if (mounted) {
        _showSuccess('Marked as sold');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
      setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete listing?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await _service.delete(_listing!.id);
      if (mounted) {
        _showSuccess('Listing deleted');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.orange))
          : _error != null
              ? _buildError()
              : _buildContent(),
      bottomNavigationBar: _listing == null ? null : _buildBottomBar(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final l = _listing!;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: AppColors.navy,
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: FlexibleSpaceBar(
            background: _buildImageGallery(l),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    if (l.state != ListingState.published)
                      StateBadge(state: l.state),
                  ],
                ),
                const SizedBox(height: 8),

                // Price / Type row
                Row(
                  children: [
                    if (l.price != null)
                      Text(
                        l.formattedPrice,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.orange,
                        ),
                      ),
                    if (l.price != null && l.type == ListingType.both)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('/', style: TextStyle(fontSize: 20)),
                      ),
                    if (
                        l.type == ListingType.both)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (l.swapPreference != null && l.swapPreference!.isNotEmpty) 
            ? l.swapPreference! 
            : 'SWAP',
        style: const TextStyle(
          fontSize: 24, // ขนาดเท่าราคา
          fontWeight: FontWeight.bold,
          color: AppColors.orange, // สีเดียวกับราคา
        ),
                          
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Meta info
                _metaRow(Icons.visibility_outlined, '${l.views} views'),
                if (l.category != null)
                  _metaRow(Icons.category_outlined, l.category!.displayName),
                if (l.condition != null)
                  _metaRow(Icons.label_outline, l.condition!.displayName),
                if (l.meetingPoint != null)
                  _metaRow(Icons.location_on_outlined, l.meetingPoint!.name),
                const SizedBox(height: 20),

                if (l.description != null && l.description!.isNotEmpty) ...[
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.navy,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (l.swapPreference != null && l.swapPreference!.isNotEmpty) ...[
                  const Text(
                    'Wants to Swap For',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.softGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l.swapPreference!,
                      style: const TextStyle(color: AppColors.navy),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Owner section
                _buildOwnerSection(l),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery(Listing l) {
    if (l.images.isEmpty) {
      return Container(
        color: AppColors.softGray,
        child: const Center(
          child: Icon(Icons.image_outlined,
              size: 80, color: AppColors.textGray),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          itemCount: l.images.length,
          onPageChanged: (i) => setState(() => _currentImageIndex = i),
          itemBuilder: (_, i) => CachedNetworkImage(
            imageUrl: l.images[i],
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppColors.softGray),
            errorWidget: (_, __, ___) => Container(
              color: AppColors.softGray,
              child: const Icon(Icons.broken_image),
            ),
          ),
        ),
        if (l.images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(l.images.length, (i) {
                final active = i == _currentImageIndex;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? AppColors.orange : Colors.white70,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textGray),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerSection(Listing l) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.navy,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.ownerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  'Student ID: ${l.ownerStudentId}',
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
    );
  }

  Widget _buildBottomBar() {
    final l = _listing!;

    if (_isOwner) {
      // Owner bottom bar: Edit + Publish/Sold/Delete
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppColors.textGray.withOpacity(0.2)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: OutlinedButton(
                  onPressed: _edit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.navy),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Edit',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: l.isDraft
                      ? _publish
                      : (l.isPublished ? _markSold : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    l.isDraft
                        ? 'Publish'
                        : (l.isPublished ? 'Mark Sold' : 'Sold'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Non-owner: contact via Line
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.textGray.withOpacity(0.2)),
          ),
        ),
        child: ElevatedButton.icon(
          onPressed: () => _showLineId(l.ownerLineId),
          icon: const Icon(Icons.chat_bubble_outline),
          label: Text(
            'Contact: ${l.ownerLineId}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }

  /// Open LINE profile directly via deep link.
/// Falls back to dialog if LINE app or browser cannot handle it.
Future<void> _showLineId(String lineId) async {
  final url = Uri.parse('https://line.me/ti/p/~$lineId');

  try {
    final ok = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      _showLineFallbackDialog(lineId);
    }
  } catch (_) {
    if (mounted) _showLineFallbackDialog(lineId);
  }
}

/// Fallback dialog (shown when LINE app and browser both fail)
void _showLineFallbackDialog(String lineId) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Contact via Line'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat, size: 48, color: AppColors.orange),
          const SizedBox(height: 12),
          const Text('Line ID:'),
          const SizedBox(height: 4),
          SelectableText(
            lineId,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap and hold to copy',
            style: TextStyle(fontSize: 11, color: AppColors.textGray),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
}
