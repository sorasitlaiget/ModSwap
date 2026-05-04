import 'package:flutter/material.dart';
import '/../models/listing_mock.dart';
import '/../theme/app_colors.dart';

class SwapRequestCard extends StatelessWidget {
  final SwapMock swap;
  final VoidCallback? onTap;

  const SwapRequestCard({super.key, required this.swap, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _swapRow('Want :', swap.want),
                  const SizedBox(height: 4),
                  _swapRow('Offer :', swap.offer),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // KMUTT badge
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF5F5F5)],
                ),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text(
                  'KMUTT',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _swapRow(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF1A1A1A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
