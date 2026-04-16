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
      if (!file.existsSync()) {
        print("StorageService: File tidak ditemukan di $filePath");
        return null;
      }

      // Buat referensi unik di Firebase Storage
      String fileName = "${DateTime.now().millisecondsSinceEpoch}_${path.basename(filePath)}";
      Reference ref = _storage.ref().child(folder).child(fileName);

      print("StorageService: Memulai upload ke Firebase ($folder/$fileName)...");
      
      // Metadata untuk membantu Firebase mengenali jenis file
      SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');

      // Upload file
      UploadTask uploadTask = ref.putFile(file, metadata);
      
      // Monitor progres (opsional untuk debug)
      TaskSnapshot snapshot = await uploadTask;
      
      // Ambil URL publik
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      print("StorageService: Upload BERHASIL. URL: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("StorageService ERROR: $e");
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
