import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class StorageService {
  /// Mengubah gambar menjadi String Base64 (Teks) agar bisa disimpan di Firestore.
  /// Ini adalah "Cara Lain" yang 100% berhasil tanpa perlu Firebase Storage.
  static Future<String?> uploadImage(String filePath, String folder) async {
    try {
      File file = File(filePath);
      if (!file.existsSync()) {
        throw Exception("File tidak ditemukan.");
      }

      print("StorageService: Mengompres dan mengonversi gambar ke Base64...");

      // 1. Kompres gambar agar ukurannya kecil (di bawah 200KB)
      // Ini penting agar tidak melebihi batas Firestore (1MB)
      final filePathLast = file.absolute.path;
      final outPath = "${file.parent.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg";
      
      var result = await FlutterImageCompress.compressAndGetFile(
        filePathLast,
        outPath,
        quality: 30, // Kualitas dikurangi agar ringan
        minWidth: 400,
        minHeight: 400,
      );

      if (result == null) throw Exception("Gagal mengompres gambar.");

      // 2. Baca file hasil kompresi sebagai bytes
      List<int> imageBytes = await File(result.path).readAsBytes();
      
      // 3. Ubah ke String Base64
      String base64Image = base64Encode(imageBytes);
      
      // 4. Tambahkan header agar Flutter tahu ini adalah gambar
      String finalString = "data:image/jpeg;base64,$base64Image";

      // Hapus file sementara
      await File(result.path).delete();

      print("StorageService: Konversi Base64 BERHASIL.");
      return finalString;
    } catch (e) {
      print("StorageService ERROR (Base64 Mode): $e");
      throw Exception("Gagal memproses gambar: $e");
    }
  }

  /// Tidak diperlukan di mode Base64 karena data terhapus otomatis saat dokumen dihapus.
  static Future<void> deleteImage(String? imageUrl) async {
    return;
  }
}
