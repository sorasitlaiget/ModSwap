import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Service for uploading files to Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a single listing image
  /// Path: listings/{userId}/{listingId}/{index}.jpg
  Future<String> uploadListingImage({
    required String listingId,
    required int index,
    required File file,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('Not authenticated');
    }

    final path = 'listings/$userId/$listingId/$index.jpg';
    final ref = _storage.ref(path);

    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  /// Upload multiple images sequentially
  Future<List<String>> uploadListingImages({
    required String listingId,
    required List<File> files,
    void Function(int current, int total)? onProgress,
  }) async {
    final urls = <String>[];
    for (int i = 0; i < files.length; i++) {
      onProgress?.call(i + 1, files.length);
      final url = await uploadListingImage(
        listingId: listingId,
        index: i,
        file: files[i],
      );
      urls.add(url);
    }
    return urls;
  }

  /// Upload user avatar
  Future<String> uploadAvatar(File file) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('Not authenticated');
    }

    final path = 'avatars/$userId/profile.jpg';
    final ref = _storage.ref(path);

    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }
}
