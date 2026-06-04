import 'package:flutter/material.dart';
import '../../domain/entities/listing.dart';
import '../../services/listings_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme_ext.dart';
import '../../widgets/listing/listing_card_real.dart';
import 'listing_detail_screen.dart';

/// My Items screen — 3 tabs (Drafts / Published / Sold).
/// Pass [initialTabIndex] to open a specific tab (0=Drafts, 1=Published, 2=Sold).
class MyItemsScreen extends StatefulWidget {
  final int initialTabIndex;

  const MyItemsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen>
    with SingleTickerProviderStateMixin {
  final _service = ListingsService();
  late TabController _tabController;

  // Cache by tab index
  final Map<int, List<Listing>> _cache = {};
  final Map<int, bool> _loading = {};
  final Map<int, String?> _error = {};

  static const _tabStates = ['draft', 'published', 'sold'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _loadTab(_tabController.index);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadTab(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTab(int index, {bool force = false}) async {
    if (!force && _cache.containsKey(index)) return;

    setState(() {
      _loading[index] = true;
      _error[index] = null;
    });

    try {
      final listings = await _service.getMyListings(state: _tabStates[index]);
      if (!mounted) return;
      setState(() {
        _cache[index] = listings;
        _loading[index] = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error[index] = e.toString();
        _loading[index] = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    _cache.clear();
    await _loadTab(_tabController.index, force: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBg,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: const Text(
          'My Items',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.orange,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Drafts'),
            Tab(text: 'Published'),
            Tab(text: 'Sold'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(3, (i) => _buildTab(i)),
      ),
    );
  }

  Widget _buildTab(int index) {
    if (_loading[index] == true) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      );
    }

    if (_error[index] != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _error[index]!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textGray),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadTab(index, force: true),
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

    final listings = _cache[index] ?? [];

    if (listings.isEmpty) {
      return _emptyState(index);
    }

    return RefreshIndicator(
      onRefresh: _refreshAll,
      color: AppColors.orange,
      child: GridView.builder(
        padding: const EdgeInsets.all(14),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.72,
        ),
        itemCount: listings.length,
        itemBuilder: (_, i) => ListingCard(
          listing: listings[i],
          showState: true,
          onTap: () => _openDetail(listings[i]),
        ),
      ),
    );
  }

  Widget _emptyState(int index) {
    String title;
    String subtitle;
    IconData icon;

    switch (index) {
      case 0:
        title = 'No drafts yet';
        subtitle = 'Items you save as draft will appear here';
        icon = Icons.drafts_outlined;
        break;
      case 1:
        title = 'No published items';
        subtitle = 'Tap + to post your first item';
        icon = Icons.shopping_bag_outlined;
        break;
      case 2:
        title = 'No sold items yet';
        subtitle = 'Sold items will appear here';
        icon = Icons.check_circle_outline;
        break;
      default:
        title = 'Empty';
        subtitle = '';
        icon = Icons.inbox_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppColors.textGray.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: AppColors.textGray)),
        ],
      ),
    );
  }

  Future<void> _openDetail(Listing listing) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListingDetailScreen(listingId: listing.id),
      ),
    );
    if (result == true) {
      _refreshAll();
    }
  }
}
