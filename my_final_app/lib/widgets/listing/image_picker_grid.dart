import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/image_service.dart';
import '../../theme/app_colors.dart';

/// Image picker grid — supports both local XFiles (new) and URLs (existing).
/// Uses XFile + Image.memory() for full web + mobile compatibility.
class ImagePickerGrid extends StatelessWidget {
  final List<String> existingUrls;
  final List<XFile> newFiles;
  final void Function(List<XFile>) onFilesChanged;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Maximum $maxCount images')));
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

    for (var i = 0; i < existingUrls.length; i++) {
      slots.add(
        _imageSlot(
          child: CachedNetworkImage(
            imageUrl: existingUrls[i],
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: AppColors.softGray),
            errorWidget: (_, _, _) => const Icon(Icons.broken_image),
          ),
          onRemove: () => _removeExisting(i),
        ),
      );
    }

    for (var i = 0; i < newFiles.length; i++) {
      slots.add(
        _imageSlot(
          child: _XFileImage(xfile: newFiles[i]),
          onRemove: () => _removeFile(i),
        ),
      );
    }

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
            border: Border.all(
              color: AppColors.textGray.withValues(alpha: 0.3),
            ),
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
                color: Colors.black.withValues(alpha: 0.6),
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
            color: AppColors.textGray.withValues(alpha: 0.4),
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

/// Displays an XFile as an image — works on web (memory) and mobile (file).
class _XFileImage extends StatefulWidget {
  final XFile xfile;
  const _XFileImage({required this.xfile});

  @override
  State<_XFileImage> createState() => _XFileImageState();
}

class _XFileImageState extends State<_XFileImage> {
  late final Future<List<int>> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = widget.xfile.readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(color: AppColors.softGray);
        }
        return Image.memory(
          snapshot.data! as dynamic,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
        );
      },
    );
  }
}
