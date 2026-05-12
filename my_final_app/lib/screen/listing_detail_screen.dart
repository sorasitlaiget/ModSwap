import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/listing.dart';
import '../services/listings_service.dart';
import '../services/wishlist_service.dart';
import '../theme/app_colors.dart';
import '../widgets/listing/state_badge.dart';
import 'post_item_screen.dart';
import 'rating_screen.dart';
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
  final _wishlistService = WishlistService();
  Listing? _listing;
  bool _loading = true;
  String? _error;
  int _currentImageIndex = 0;
  bool _isInWishlist = false;
  bool _wishlistLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
    _checkWishlist();
  }

  // ============================================================
  // Wishlist actions
  // ============================================================

  Future<void> _checkWishlist() async {
    try {
      final inWishlist = await _wishlistService.isInWishlist(widget.listingId);
      if (mounted) setState(() => _isInWishlist = inWishlist);
    } catch (_) {
      // Silently fail — UI just shows "not in wishlist"
    }
  }

  Future<void> _toggleWishlist() async {
    if (_wishlistLoading) return;
    setState(() => _wishlistLoading = true);
    try {
      final newState = await _wishlistService.toggle(widget.listingId);
      if (!mounted) return;
      setState(() {
        _isInWishlist = newState;
        _wishlistLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newState ? 'Added to wishlist' : 'Removed from wishlist',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _wishlistLoading = false);
      _showError(e.toString());
    }
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
      // Buyer opens a sold listing → show rating sheet on top of detail
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final isBuyer = uid != null && l.ownerId != uid;
      if (isBuyer && l.isSold) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showRatingSheet(l);
        });
      }
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

  void _showRatingSheet(Listing l) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RatingSheet(
        sellerHandle: '@${l.ownerName}',
        sellerName: l.ownerName,
        itemTitle: l.title,
      ),
    );
  }

  // ============================================================
  // Owner actions
  // ============================================================

  Future<void> _edit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostItemScreen(existing: _listing!)),
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
    final confirmed = await _showMarkSoldSheet(_listing!);
    if (confirmed == null) return;

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

  Future<String?> _showMarkSoldSheet(Listing listing) {
    var selectedIndex = 0;
    final priceCtrl = TextEditingController(
      text: listing.price != null ? listing.price!.toInt().toString() : '',
    );
    final buyerCtrl = TextEditingController();
    final returnCtrl = TextEditingController();
    DateTime? completedAt = DateTime.now();
    XFile? swapPhoto;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final selected = selectedIndex;
            final sameAsListed =
                selected == 0 &&
                listing.price != null &&
                priceCtrl.text.trim() == listing.price!.toInt().toString();

            Widget buildField(String label, Widget child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  child,
                  const SizedBox(height: 16),
                ],
              );
            }

            Future<void> _pickPhoto() async {
              final imagePicker = ImagePicker();
              try {
                final pickedFile = await imagePicker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1200,
                  maxHeight: 1200,
                  imageQuality: 85,
                );
                if (pickedFile != null) {
                  setState(() => swapPhoto = pickedFile);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to pick image: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
              child: DraggableScrollableSheet(
                initialChildSize: 0.85,
                minChildSize: 0.6,
                maxChildSize: 0.95,
                expand: false,
                builder: (_, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 16,
                          left: 20,
                          right: 20,
                          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 48,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.textGray.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Mark as Sold',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Future.microtask(() => Navigator.of(ctx).pop(null));
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.softGray,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: SizedBox(
                                      width: 76,
                                      height: 76,
                                      child: listing.images.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: listing.images.first,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) =>
                                                  Container(
                                                    color: AppColors.textGray
                                                        .withOpacity(0.2),
                                                    child: const Icon(
                                                      Icons.broken_image,
                                                    ),
                                                  ),
                                            )
                                          : Container(
                                              color: AppColors.textGray
                                                  .withOpacity(0.2),
                                              child: const Icon(
                                                Icons.image_outlined,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          listing.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.navy,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (listing.price != null)
                                          Text(
                                            listing.formattedPrice,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.orange,
                                            ),
                                          ),
                                        if (listing.type == ListingType.both)
                                          Text(
                                            listing
                                                        .swapPreference
                                                        ?.isNotEmpty ==
                                                    true
                                                ? listing.swapPreference!
                                                : 'SWAP',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.orange,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'How did the deal go ?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildDealOption(
                              title: 'Sold for cash',
                              subtitle: 'Buyer paid in cash or transfer',
                              icon: Icons.currency_bitcoin,
                              selected: selected == 0,
                              onTap: () => setState(() => selectedIndex = 0),
                            ),
                            const SizedBox(height: 10),
                            _buildDealOption(
                              title: 'Swapped for an item',
                              subtitle: 'Pure barter, no money exchanged',
                              icon: Icons.swap_horiz,
                              selected: selected == 1,
                              onTap: () => setState(() => selectedIndex = 1),
                            ),
                            const SizedBox(height: 10),
                            _buildDealOption(
                              title: 'Swap + cash',
                              subtitle: 'Item exchange with cash adjustment',
                              icon: Icons.sync_alt,
                              selected: selected == 2,
                              onTap: () => setState(() => selectedIndex = 2),
                            ),
                            const SizedBox(height: 20),
                            if (selected != 1) ...[
                              buildField(
                                selected == 0 ? 'Final Price' : 'Final Price',
                                TextField(
                                  controller: priceCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.softGray,
                                    hintText:
                                        '฿${listing.price?.toInt() ?? ''}',
                                    prefixText: '฿',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              if (sameAsListed)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    'Same as listed',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                            ],
                            if (selected != 0) ...[
                              buildField(
                                'What I got return',
                                TextField(
                                  controller: returnCtrl,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.softGray,
                                    hintText:
                                        'Apple Pencil 2nd gen + Magic Keyboard',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              buildField(
                                'Photo of the Swap Item',
                                GestureDetector(
                                  onTap: _pickPhoto,
                                  child: Container(
                                    height: 110,
                                    decoration: BoxDecoration(
                                      color: AppColors.softGray,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.textGray.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                    ),
                                    child: swapPhoto != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            child: Image.file(
                                              File(swapPhoto!.path),
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.add,
                                                  color: AppColors.orange,
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'Upload photo',
                                                  style: TextStyle(
                                                    color: AppColors.textGray,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                            buildField(
                              'Buyer',
                              TextField(
                                controller: buyerCtrl,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.softGray,
                                  hintText: '@username',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            buildField(
                              'Date Completed',
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: completedAt ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setState(() => completedAt = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 18,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.softGray,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        completedAt != null
                                            ? '${completedAt!.day.toString().padLeft(2, '0')}/${completedAt!.month.toString().padLeft(2, '0')}/${completedAt!.year}'
                                            : 'Select date',
                                        style: const TextStyle(
                                          color: AppColors.navy,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 18,
                                        color: AppColors.textGray,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Future.microtask(() => Navigator.of(ctx).pop(null));
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.navy,
                                      side: const BorderSide(
                                        color: AppColors.navy,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Future.microtask(() => Navigator.of(ctx).pop(buyerCtrl.text.trim()));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.orange,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    child: const Text(
                                      'Submit Deal',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDealOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange.withOpacity(0.12) : Colors.white,
          border: Border.all(
            color: selected
                ? AppColors.orange
                : AppColors.textGray.withOpacity(0.25),
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? AppColors.orange : AppColors.softGray,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : AppColors.navy,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected ? AppColors.navy : AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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
    );
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
              child: CircularProgressIndicator(color: AppColors.orange),
            )
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
              ),
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
          flexibleSpace: FlexibleSpaceBar(background: _buildImageGallery(l)),
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
                    if (l.type == ListingType.both)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (l.swapPreference != null &&
                                  l.swapPreference!.isNotEmpty)
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

                if (l.swapPreference != null &&
                    l.swapPreference!.isNotEmpty) ...[
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
                if (!_isOwner && l.isSold) ...[
                  const SizedBox(height: 16),
                  _buildRateSellerSection(l),
                ],
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
          child: Icon(
            Icons.image_outlined,
            size: 80,
            color: AppColors.textGray,
          ),
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
              style: const TextStyle(fontSize: 13, color: AppColors.textGray),
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

  Widget _buildRateSellerSection(Listing l) {
    final handle = l.ownerStudentId.isNotEmpty
        ? '@${l.ownerStudentId}'
        : '@${l.ownerName.toLowerCase().replaceAll(' ', '')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softGray,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.textGray.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Rate the seller',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Give feedback to ${l.ownerName} after receiving the item.',
            style: const TextStyle(fontSize: 13, color: AppColors.textGray),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              Navigator.push<bool?>(
                context,
                MaterialPageRoute(
                  builder: (_) => RatingScreen(
                    sellerHandle: handle,
                    sellerName: l.ownerName,
                    itemTitle: l.title,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Rate Seller',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
                  child: const Text(
                    'Edit',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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

    // Non-owner: heart (wishlist) + contact via Line
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
            // ⭐ Heart button (toggle wishlist)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isInWishlist
                      ? AppColors.orange
                      : AppColors.textGray.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: IconButton(
                onPressed: _wishlistLoading ? null : _toggleWishlist,
                icon: _wishlistLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.orange,
                        ),
                      )
                    : Icon(
                        _isInWishlist ? Icons.favorite : Icons.favorite_border,
                        color: _isInWishlist
                            ? AppColors.orange
                            : AppColors.navy,
                        size: 26,
                      ),
                padding: const EdgeInsets.all(11),
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(width: 10),
            // Contact button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showLineId(l.ownerLineId),
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(
                  'Contact: ${l.ownerLineId}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
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
          ],
        ),
      ),
    );
  }

  /// Open LINE profile directly via deep link.
  /// Falls back to dialog if LINE app or browser cannot handle it.
  Future<void> _showLineId(String lineId) async {
    final url = Uri.parse('https://line.me/ti/p/~$lineId');

    try {
      final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
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

// ============================================================
// Rating bottom sheet — shown to buyer when listing is sold
// ============================================================

class _RatingSheet extends StatefulWidget {
  final String sellerHandle;
  final String sellerName;
  final String itemTitle;

  const _RatingSheet({
    required this.sellerHandle,
    required this.sellerName,
    required this.itemTitle,
  });

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _rating = 0;

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

  void _submit() {
    if (_rating == 0) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You rated ${widget.sellerHandle} $_rating.0 stars'),
        backgroundColor: AppColors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                        widget.sellerHandle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.itemTitle,
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
            onPressed: _rating == 0 ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              padding: const EdgeInsets.symmetric(vertical: 14),
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
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
