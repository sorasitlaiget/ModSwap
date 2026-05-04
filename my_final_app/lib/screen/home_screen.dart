import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/listing_mock.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/welcome_banner.dart';
import '../widgets/home/home_search_bar.dart';
import '../widgets/home/category_chips.dart';
import '../widgets/home/listing_card.dart';
import '../widgets/home/swap_request_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';

  List<ListingMock> get _filteredListings {
    var list = ListingMock.samples;

    if (_selectedCategory != 'all') {
      list = list.where((l) => l.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((l) => l.name.toLowerCase().contains(q)).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthState>().profile;
    final userName = profile?.displayName ?? 'Friend';

    return Container(
      color: const Color(0xFFF2F3F7),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            HomeHeader(
              onAvatarTap: () {
                // TODO: navigate to profile
              },
            ),

            // Welcome + Search overlap section
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Welcome banner (with extra bottom padding for the search overlap)
                WelcomeBanner(userName: userName),

                // Search + Categories card overlapping bottom of banner
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: -40,
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
                          onChanged: (q) =>
                              setState(() => _searchQuery = q),
                          onFilterTap: () {
                            // TODO: open filter modal
                          },
                        ),
                        const SizedBox(height: 2),
                        CategoryChips(
                          selectedCategory: _selectedCategory,
                          onCategoryChanged: (c) =>
                              setState(() => _selectedCategory = c),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Spacer for the search card overlap
            const SizedBox(height: 56),

            // Section: Campus Pick
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

            // Listings grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _filteredListings.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No items in this category yet.',
                          style: TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredListings.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.72,
                      ),
                      itemBuilder: (_, i) => ListingCard(
                        listing: _filteredListings[i],
                        onTap: () {
                          // TODO: navigate to detail
                        },
                      ),
                    ),
            ),

            // Section: Swap Request
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 20, 14, 10),
              child: Text(
                'Swap Request',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ),

            // Swap horizontal scroll
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: SwapMock.samples.length,
                separatorBuilder: (_, __) => const SizedBox(width: 9),
                itemBuilder: (_, i) => SwapRequestCard(
                  swap: SwapMock.samples[i],
                  onTap: () {
                    // TODO: open swap detail
                  },
                ),
              ),
            ),

            // Bottom spacer
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}