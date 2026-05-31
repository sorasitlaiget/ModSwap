import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Service for uploading files to Firebase Storage.
/// Uses XFile + putData() for cross-platform (mobile + web) support.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadListingImage({
    required String listingId,
    required int index,
    required XFile file,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('Not authenticated');

    final path = 'listings/$userId/$listingId/$index.jpg';
    final ref = _storage.ref(path);
    final bytes = await file.readAsBytes();

    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await task.ref.getDownloadURL();
  }

  Future<List<String>> uploadListingImages({
    required String listingId,
    required List<XFile> files,
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

  Future<String> uploadSwapPhoto({
    required String listingId,
    required XFile file,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('Not authenticated');

    final path = 'deals/$userId/$listingId/swap_photo.jpg';
    final ref = _storage.ref(path);
    final bytes = await file.readAsBytes();

    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await task.ref.getDownloadURL();
  }

  Future<String> uploadAvatar(XFile file) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('Not authenticated');

    final path = 'avatars/$userId/profile.jpg';
    final ref = _storage.ref(path);
    final bytes = await file.readAsBytes();

    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await task.ref.getDownloadURL();
  }
}
