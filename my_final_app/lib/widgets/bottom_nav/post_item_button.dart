import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// The center "+" button on the NavBar that opens the Post Item flow.
class PostItemButton extends StatefulWidget {
  final VoidCallback onTap;

  const PostItemButton({super.key, required this.onTap});

  @override
  State<PostItemButton> createState() => _PostItemButtonState();
}

class _PostItemButtonState extends State<PostItemButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) => _controller.forward();
  void _handleTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Transform.translate(
          offset: const Offset(0, -12),
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
