import 'package:flutter/material.dart';
import '/../models/listing_mock.dart';
import '/../theme/app_colors.dart';

class ListingCard extends StatelessWidget {
  final ListingMock listing;
  final VoidCallback? onTap;

  const ListingCard({super.key, required this.listing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        // ⭐ ใช้ Column + Expanded ให้รูปยืดตามพื้นที่เหลือ
        // เนื่องจาก GridView childAspectRatio: 0.72 บังคับขนาด cell ไว้แล้ว
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ⭐ Expanded ใช้พื้นที่ที่เหลือทั้งหมด (รูป)
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [listing.bgStart, listing.bgEnd],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      listing.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        listing.tag,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body — ส่วนข้อความ ขนาดพอดีกับ content (ไม่ขยายเกิน)
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 6, 7, 7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    listing.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      height: 1.2,
                    ),
                    maxLines: 1, // ⭐ ลดเหลือ 1 บรรทัด กัน overflow
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '฿${_formatPrice(listing.price)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.orange,
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

  String _formatPrice(int n) {
    return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
