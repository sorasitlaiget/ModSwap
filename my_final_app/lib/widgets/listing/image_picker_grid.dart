import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/image_service.dart';
import '../../theme/app_colors.dart';
import 'package:image_picker/image_picker.dart';

/// Image picker grid — supports both local files (new) and URLs (existing).
/// Used in Post/Edit Item form. 1-10 images.
class ImagePickerGrid extends StatelessWidget {
  /// Already-uploaded images (URLs from backend)
  final List<String> existingUrls;

  /// Newly picked files (not yet uploaded)
  final List<File> newFiles;

  final void Function(List<File>) onFilesChanged;
  final void Function(List<String>) onExistingChanged;

  final int maxCount;

  const ImagePickerGrid({
    super.key,
    this.existingUrls = const [],
    this.newFiles = const [],
    required this.onFilesChanged,
    required this.onExistingChanged,
    this.maxCount = 10,
  });

  int get totalCount => existingUrls.length + newFiles.length;

  Future<void> _addImages(BuildContext context) async {
    if (totalCount >= maxCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum $maxCount images')),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final imageService = ImageService();
    final remaining = maxCount - totalCount;

    if (source == ImageSource.gallery) {
      final picked = await imageService.pickMultiple(maxCount: remaining);
      if (picked.isNotEmpty) {
        onFilesChanged([...newFiles, ...picked]);
      }
    } else {
      final picked = await imageService.pickFromCamera();
      if (picked != null) {
        onFilesChanged([...newFiles, picked]);
      }
    }
  }

  void _removeExisting(int index) {
    final updated = [...existingUrls]..removeAt(index);
    onExistingChanged(updated);
  }

  void _removeFile(int index) {
    final updated = [...newFiles]..removeAt(index);
    onFilesChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final slots = <Widget>[];

    // Existing URLs (from backend)
    for (var i = 0; i < existingUrls.length; i++) {
      slots.add(_imageSlot(
        child: CachedNetworkImage(
          imageUrl: existingUrls[i],
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: AppColors.softGray),
          errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
        ),
        onRemove: () => _removeExisting(i),
      ));
    }

    // New files (local)
    for (var i = 0; i < newFiles.length; i++) {
      slots.add(_imageSlot(
        child: Image.file(newFiles[i], fit: BoxFit.cover),
        onRemove: () => _removeFile(i),
      ));
    }

    // Add button (if not full)
    if (totalCount < maxCount) {
      slots.add(_addSlot(context));
    }

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: slots,
    );
  }

  Widget _imageSlot({required Widget child, required VoidCallback onRemove}) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.textGray.withOpacity(0.3)),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addSlot(BuildContext context) {
    return GestureDetector(
      onTap: () => _addImages(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.softGray,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.textGray.withOpacity(0.4),
            width: 1.2,
          ),
        ),
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.orange,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
