import 'dart:async'; // 🎯 1. เพิ่ม import นี้สำหรับระบบหน่วงเวลา (Debounce)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/listing.dart';
import '../providers/auth_provider.dart';
import '../services/listings_service.dart';
import '../theme/app_colors.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/welcome_banner.dart';
import '../widgets/home/home_search_bar.dart';
import '../widgets/home/category_chips.dart';
// หมายเหตุ: ถ้าไฟล์ชื่อ listing_card.dart ให้แก้ตรงนี้เป็น listing_card.dart ด้วยนะครับ
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listings = await _service.getPublished(
        category: _selectedCategory == 'all' ? null : _selectedCategory,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        type: _filterType, // 🎯 3. ส่งค่า filter type ไปให้ API
      );
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

  void _onSearchChanged(String q) {
    // 🎯 4. เปลี่ยนมาใช้ระบบ Debounce หน่วงเวลาครึ่งวิ ไม่ให้แอพค้างตอนพิมพ์
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = q.trim();
      });
      _load();
    });
  }

  void _onSearchSubmitted() {
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by Type',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.all_inclusive, color: AppColors.orange),
                  title: const Text('All Items'),
                  onTap: () => Navigator.pop(context, 'all'),
                ),
                ListTile(
                  leading: const Icon(Icons.sell, color: AppColors.orange),
                  title: const Text('For Sale'),
                  onTap: () => Navigator.pop(context, 'sell'),
                ),
                ListTile(
                  leading: const Icon(Icons.swap_horiz, color: AppColors.orange),
                  title: const Text('Open to Swap'),
                  onTap: () => Navigator.pop(context, 'trade'),
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
      color: const Color(0xFFF2F3F7),
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
                alignment: Alignment.bottomCenter, // จัดให้กล่องอยู่ตำแหน่งล่างสุดของ Stack เสมอ
                children: [
                  // 1. ส่วนแบนเนอร์สีน้ำเงิน และ "พื้นที่ล่องหน" ที่เราเติมเข้าไปเพื่อให้ Stack สูงพอที่จะคลุมกล่อง
                  Column(
                    children: [
                      WelcomeBanner(userName: userName),
                      const SizedBox(height: 55), // 🎯 พื้นที่ล่องหน! ทำให้กล่องด้านล่างไม่ล้นกรอบและ "กดได้"
                    ],
                  ),
                  
                  // 2. กล่อง Search และ Category (เปลี่ยนมาใช้ Padding ธรรมดาแทน)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          HomeSearchBar(
                            onChanged: _onSearchChanged,
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
              const SizedBox(height: 15), // 🎯 8. ขยับระยะห่างตรงนี้เพิ่ม (จาก 56 เป็น 70) เพื่อหลบกล่องที่ขยับลงมา

              const Padding(
                padding: EdgeInsets.fromLTRB(14, 16, 14, 10),
                child: Text(
                  'Campus Pick: New This Week',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
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