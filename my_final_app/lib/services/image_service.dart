import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';

/// Service for picking + compressing images before upload.
/// Returns XFile on all platforms (web-safe).
class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (picked == null) return null;
      return kIsWeb ? picked : await _compress(picked);
    } catch (e) {
      AppLogger.e('[ImageService] pickFromGallery ERROR', error: e);
      return null;
    }
  }

  Future<XFile?> pickFromCamera() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (picked == null) return null;
      return kIsWeb ? picked : await _compress(picked);
    } catch (e) {
      AppLogger.e('[ImageService] pickFromCamera ERROR', error: e);
      return null;
    }
  }

  Future<List<XFile>> pickMultiple({int maxCount = 10}) async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 90);
      final limited = picked.take(maxCount).toList();
      if (kIsWeb) return limited;
      final result = <XFile>[];
      for (final x in limited) {
        final compressed = await _compress(x);
        result.add(compressed);
      }
      return result;
    } catch (e) {
      AppLogger.e('[ImageService] pickMultiple ERROR', error: e);
      return [];
    }
  }

  Future<XFile> _compress(XFile xfile) async {
    try {
      final file = File(xfile.path);
      if (!await file.exists()) return xfile;

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

      return result ?? xfile;
    } catch (e) {
      AppLogger.e('[ImageService] compress ERROR', error: e);
      return xfile;
    }
  }
}
