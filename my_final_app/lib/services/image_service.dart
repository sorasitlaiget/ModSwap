import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Service for picking + compressing images before upload
class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Pick a single image from gallery and compress
  Future<File?> pickFromGallery() async {
    try {
      debugPrint('[ImageService] Picking from gallery...');
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (picked == null) {
        debugPrint('[ImageService] User cancelled');
        return null;
      }
      debugPrint('[ImageService] Picked: ${picked.path}');
      return await compress(File(picked.path));
    } catch (e, stack) {
      debugPrint('[ImageService] pickFromGallery ERROR: $e');
      debugPrint('$stack');
      return null;
    }
  }

  /// Pick from camera and compress
  Future<File?> pickFromCamera() async {
    try {
      debugPrint('[ImageService] Opening camera...');
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (picked == null) {
        debugPrint('[ImageService] User cancelled');
        return null;
      }
      debugPrint('[ImageService] Picked: ${picked.path}');
      return await compress(File(picked.path));
    } catch (e, stack) {
      debugPrint('[ImageService] pickFromCamera ERROR: $e');
      debugPrint('$stack');
      return null;
    }
  }

  /// Pick multiple images
  Future<List<File>> pickMultiple({int maxCount = 10}) async {
    try {
      final List<XFile> picked = await _picker.pickMultiImage(
        imageQuality: 90,
      );
      final limited = picked.take(maxCount).toList();
      final compressed = <File>[];
      for (final x in limited) {
        final f = await compress(File(x.path));
        if (f != null) compressed.add(f);
      }
      return compressed;
    } catch (e) {
      debugPrint('[ImageService] pickMultiple ERROR: $e');
      return [];
    }
  }

  /// Compress an image — 85% quality, 1080px max
  /// On failure, returns the original file (so we always have something)
  Future<File?> compress(File file) async {
    try {
      // Verify file exists
      if (!await file.exists()) {
        debugPrint('[ImageService] File does not exist: ${file.path}');
        return null;
      }

      final originalSize = await file.length();
      debugPrint(
          '[ImageService] Original size: ${(originalSize / 1024).toStringAsFixed(1)} KB');

      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85,
        minWidth: 1080,
        minHeight: 1080,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        debugPrint(
            '[ImageService] Compress returned null, using original file');
        return file;
      }

      final compressedSize = await File(result.path).length();
      debugPrint(
          '[ImageService] Compressed: ${(compressedSize / 1024).toStringAsFixed(1)} KB '
          '(${((1 - compressedSize / originalSize) * 100).toStringAsFixed(0)}% smaller)');

      return File(result.path);
    } catch (e, stack) {
      debugPrint('[ImageService] compress ERROR: $e');
      debugPrint('$stack');
      // Fallback: return original file
      return file;
    }
  }
}