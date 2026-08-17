import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Picks an image from the camera / gallery and stores it permanently in
/// the app's documents directory, returning the saved path (or null).
class MediaService {
  static Future<String?> pickImageToDocuments({
    required String prefix,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked == null) return null;

      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${dir.path}/habit_images');
      if (!imagesDir.existsSync()) imagesDir.createSync(recursive: true);

      final ext = picked.path.contains('.') ? picked.path.split('.').last : 'jpg';
      final dest =
          '${imagesDir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await File(picked.path).copy(dest);
      return dest;
    } catch (e) {
      debugPrint('Media pick failed: $e');
      return null;
    }
  }
}
