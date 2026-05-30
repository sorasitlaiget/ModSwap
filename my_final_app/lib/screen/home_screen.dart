import 'dart:async'; // 🎯 1. เพิ่ม import นี้สำหรับระบบหน่วงเวลา (Debounce)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/listing.dart';
import '../providers/auth_provider.dart';
import '../services/listings_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_ext.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/welcome_banner.dart';
import '../widgets/home/home_search_bar.dart';
import '../widgets/home/category_chips.dart';
import '../widgets/listing/listing_card_real.dart';
import 'listing_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = ListingsService();

  // 🎯 2. เพิ่มตัวแปร Timer สำหรับค้นหา และตัวแปรเก็บค่า Filter
  Timer? _debounce;
  String? _filterType;

  String _selectedCategory = 'all';
  String _searchQuery = '';

  List<Listing> _listings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<Listing> listings;

      if (_searchQuery.isNotEmpty && _searchQuery.length >= 2) {
        // ⭐ Smart semantic search (Gemini embeddings)
        // "flower" finds "rose", "ดอกไม้", "bouquet" etc.
        final results = await _service.search(
          query: _searchQuery,
          category: _selectedCategory == 'all' ? null : _selectedCategory,
          type: _filterType,
          limit: 30,
        );
        listings = results.map((r) => r.listing).toList();
      } else {
        // Regular browse (no search)
        listings = await _service.getPublished(
          category: _selectedCategory == 'all' ? null : _selectedCategory,
          type: _filterType,
        );
      }

      if (!mounted) return;
      setState(() {
        _listings = listings;
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

  void _onCategoryChanged(String c) {
    setState(() => _selectedCategory = c);
    _load();
  }

  /// Called when user clears the search field
  /// (instant — back to browse mode)
  void _onSearchChanged(String q) {
    final trimmed = q.trim();
    // Only react to clearing the field — don't search on every keystroke
    // (saves API quota: 1,000 calls/day limit on Gemini free tier)
    if (trimmed.isEmpty && _searchQuery.isNotEmpty) {
      setState(() => _searchQuery = '');
      _load();
    }
  }

  /// Called when user presses Enter — runs the actual search
  void _onSearchSubmitted(String q) {
    final trimmed = q.trim();
    if (trimmed == _searchQuery) return;
    setState(() => _searchQuery = trimmed);
    _load();
  }

  Future<void> _openDetail(Listing listing) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListingDetailScreen(listingId: listing.id),
      ),
    );
    _load();
  }

  // 🎯 5. เพิ่มฟังก์ชันแสดง Bottom Sheet สำหรับ Filter
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textGray.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Filter by Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _TypeOption(icon: Icons.all_inclusive, label: 'All Items', value: 'all', current: _filterType),
                    const SizedBox(width: 10),
                    _TypeOption(icon: Icons.sell_outlined, label: 'For Sale', value: 'sell', current: _filterType),
                    const SizedBox(width: 10),
                    _TypeOption(icon: Icons.swap_horiz, label: 'Open to Swap', value: 'trade', current: _filterType),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((selectedType) {
      // 🎯 เช็คว่าผู้ใช้กดเลือกอะไรมา แล้วอัปเดตข้อมูล
      if (selectedType != null) {
        final newType = selectedType == 'all' ? null : selectedType as String;
        if (newType != _filterType) {
          setState(() {
            _filterType = newType;
          });
          _load();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthState>().profile;
    final userName = profile?.displayName ?? 'Friend';

    return Container(
      color: context.appBg,
      child: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.orange,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeHeader(
                onAvatarTap: () {
                  // TODO: navigate to profile
                },
              ),
              Stack(
                alignment: Alignment
                    .bottomCenter, // จัดให้กล่องอยู่ตำแหน่งล่างสุดของ Stack เสมอ
                children: [
                  // 1. ส่วนแบนเนอร์สีน้ำเงิน และ "พื้นที่ล่องหน" ที่เราเติมเข้าไปเพื่อให้ Stack สูงพอที่จะคลุมกล่อง
                  Column(
                    children: [
                      WelcomeBanner(userName: userName),
                      const SizedBox(
                        height: 55,
                      ), // 🎯 พื้นที่ล่องหน! ทำให้กล่องด้านล่างไม่ล้นกรอบและ "กดได้"
                    ],
                  ),

                  // 2. กล่อง Search และ Category (เปลี่ยนมาใช้ Padding ธรรมดาแทน)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          HomeSearchBar(
                            onChanged: _onSearchChanged,
                            onSubmitted: _onSearchSubmitted,
                            onFilterTap: _showFilterBottomSheet,
                          ),
                          const SizedBox(height: 12),
                          CategoryChips(
                            selectedCategory: _selectedCategory,
                            onCategoryChanged: _onCategoryChanged,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 15,
              ), // 🎯 8. ขยับระยะห่างตรงนี้เพิ่ม (จาก 56 เป็น 70) เพื่อหลบกล่องที่ขยับลงมา

              Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
                child: Text(
                  _searchQuery.isEmpty
                      ? 'Campus Pick: New This Week'
                      : 'Search results for "$_searchQuery"',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.primaryText,
                  ),
                ),
              ),

              _buildContent(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGray),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_listings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No items in this category yet.',
            style: TextStyle(color: Color(0xFF888888), fontSize: 13),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _listings.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (_, i) => ListingCard(
          listing: _listings[i],
          onTap: () => _openDetail(_listings[i]),
        ),
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? current;

  const _TypeOption({
    required this.icon,
    required this.label,
    required this.value,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = (current == null && value == 'all') || current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pop(context, value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.orange.withValues(alpha: 0.1)
                : AppColors.softGray,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.orange : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.orange : AppColors.navy,
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.orange : AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
