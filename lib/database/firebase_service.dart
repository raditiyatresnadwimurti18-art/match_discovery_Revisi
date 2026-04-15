import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload gambar ke Firebase Storage dan kembalikan URL-nya.
  /// [folder] adalah nama folder di Storage (misal: 'profile_images' atau 'lomba_images').
  static Future<String?> uploadImage(String filePath, String folder) async {
    try {
      File file = File(filePath);
      if (!file.existsSync()) return null;

      // Buat nama file unik berdasarkan timestamp
      String fileName = "${DateTime.now().millisecondsSinceEpoch}${path.extension(filePath)}";
      
      // Referensi ke lokasi penyimpanan
      Reference ref = _storage.ref().child(folder).child(fileName);

      // Mulai upload
      UploadTask uploadTask = ref.putFile(file);
      
      // Tunggu selesai dan ambil URL
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print("Error StorageService (uploadImage): $e");
      return null;
    }
  }

  /// Hapus gambar dari Storage berdasarkan URL.
  static Future<void> deleteImage(String? imageUrl) async {
    if (imageUrl == null || !imageUrl.startsWith('http')) return;
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print("Error StorageService (deleteImage): $e");
    }
  }
}
