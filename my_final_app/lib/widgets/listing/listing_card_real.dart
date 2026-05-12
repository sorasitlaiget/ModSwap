import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/listing.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme_ext.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onTap;
  final bool showState; // 🎯 1. เพิ่มตัวแปรสำหรับเปิด/ปิดการโชว์สถานะ

  const ListingCard({
    super.key, 
    required this.listing, 
    this.onTap,
    this.showState = false, // 🎯 2. กำหนดค่าเริ่มต้นเป็น false (หน้า Home จะได้ไม่โชว์)
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04), // ลดเงาให้ดูละมุนขึ้น
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ส่วนรูปภาพ (ให้ยืดเต็มพื้นที่ที่เหลือ)
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(),
                  
                  // 🎯 3. ป้ายแสดงหมวดหมู่ (Category) มุมขวาบน
                  if (listing.category != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          listing.category!.displayName,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ),

                  // 🎯 4. ป้ายแสดงสถานะ DRAFT มุมซ้ายบน (โชว์เฉพาะเมื่อ showState เป็น true)
                  if (showState && listing.state == ListingState.draft)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'DRAFT',
                          style: TextStyle(
                            fontSize: 9, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // 🎯 5. ป้ายแสดงสถานะ SOLD ทับตรงกลางรูป
                  if (listing.isSold)
                    Container(
                      color: Colors.black.withOpacity(0.6),
                      alignment: Alignment.center,
                      child: const Text(
                        'SOLD',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // ส่วนข้อความด้านล่าง (แก้ Overflow ตรงนี้)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, // ให้ข้อความชิดซ้ายอ่านง่ายกว่า
                children: [
                  Text(
                    listing.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // ป้องกันราคา Overflow ด้วย FittedBox
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: _buildPriceOrSwap(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (listing.thumbnailURL == null || listing.thumbnailURL!.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 32),
      );
    }
    return CachedNetworkImage(
      imageUrl: listing.thumbnailURL!,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: Colors.grey.shade100),
      errorWidget: (_, __, ___) => Container(color: Colors.grey.shade200),
    );
  }

  Widget _buildPriceOrSwap() {
    if (listing.type == ListingType.trade) {
      return const Text(
        'SWAP',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.orange),
      );
    }
    if (listing.price == null) return const SizedBox.shrink();
    
    // โชว์ราคา และถ้าแลกได้ด้วย ให้ใส่ป้ายเล็กๆ ต่อท้าย
    return Row(
      children: [
        Text(
          listing.formattedPrice,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.orange),
        ),
        if (listing.type == ListingType.both) ...[
          const SizedBox(width: 4),
          const Text(
            '/ SWAP', 
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.orange),
          ),
        ]
      ],
    );
  }
}