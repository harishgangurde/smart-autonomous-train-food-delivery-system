import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Uploads a picked image to Firebase Storage and returns its public
/// download URL — this is what lets staff pick a photo from their gallery
/// instead of hunting down and pasting an image URL, which was slow and
/// unreliable (random web images, broken links, load-time lag).
class StorageService {
  FirebaseStorage get _storage => FirebaseStorage.instance;

  Future<String> uploadMenuImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final ref = _storage.ref().child('menu_images/$fileName');
    final task =
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return task.ref.getDownloadURL();
  }
}
