import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:match_discovery/database/firebase_service.dart';
import 'package:match_discovery/models/lomba_model.dart';

class LombaController {
  static final CollectionReference _lombaCollection =
      FirebaseFirestore.instance.collection('lomba');

  // ==================== CREATE ====================

  static Future<void> insertLomba(LombaModel data) async {
    try {
      // 1. Upload gambar jika ada
      if (data.gambarPath != null && !data.gambarPath!.startsWith('http')) {
        String? downloadUrl = await StorageService.uploadImage(data.gambarPath!, 'lomba_images');
        if (downloadUrl != null) {
          // Ganti path lokal dengan URL Storage
          data = LombaModel(
            id: data.id,
            judul: data.judul,
            gambarPath: downloadUrl,
            kuota: data.kuota,
            jenis: data.jenis,
            tanggal: data.tanggal,
            lokasi: data.lokasi,
            deskripsi: data.deskripsi,
          );
        }
      }

      // 2. Ambil DocumentReference baru untuk generate ID otomatis
      DocumentReference docRef = _lombaCollection.doc();
      
      // 3. Set ID tersebut ke dalam model
      data.id = docRef.id;

      // 4. Simpan data (sudah termasuk field 'id' di dalam map)
      await docRef.set(data.toMap());
    } catch (e) {
      print("Error insertLomba: $e");
    }
  }

  // ==================== READ ====================

  static Future<List<LombaModel>> getAllLomba() async {
    try {
      QuerySnapshot querySnapshot = await _lombaCollection.get();
      return querySnapshot.docs
          .map((doc) => LombaModel.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id))
          .toList();
    } catch (e) {
      print("Error getAllLomba: $e");
      return [];
    }
  }

  // ==================== UPDATE ====================

  static Future<void> updateLomba(LombaModel data) async {
    if (data.id == null) throw Exception("Gagal Update: ID Lomba tidak ditemukan");
    try {
      // 1. Cek apakah gambar diubah (path lokal)
      if (data.gambarPath != null && !data.gambarPath!.startsWith('http')) {
        // Upload gambar baru
        String? downloadUrl = await StorageService.uploadImage(data.gambarPath!, 'lomba_images');
        
        if (downloadUrl != null) {
          // Hapus gambar lama dari Storage
          DocumentSnapshot oldDoc = await _lombaCollection.doc(data.id).get();
          if (oldDoc.exists) {
            String? oldUrl = (oldDoc.data() as Map<String, dynamic>)['gambarPath'];
            await StorageService.deleteImage(oldUrl);
          }
          
          // Gunakan URL baru
          data = LombaModel(
            id: data.id,
            judul: data.judul,
            gambarPath: downloadUrl,
            kuota: data.kuota,
            jenis: data.jenis,
            tanggal: data.tanggal,
            lokasi: data.lokasi,
            deskripsi: data.deskripsi,
          );
        }
      }
      
      await _lombaCollection.doc(data.id).update(data.toMap());
    } catch (e) {
      print("Error updateLomba: $e");
    }
  }

  // ==================== DELETE ====================

  static Future<void> deleteLomba(String id) async {
    try {
      // 1. Hapus gambar dari Storage jika ada
      DocumentSnapshot doc = await _lombaCollection.doc(id).get();
      if (doc.exists) {
        String? imageUrl = (doc.data() as Map<String, dynamic>)['gambarPath'];
        await StorageService.deleteImage(imageUrl);
      }
      
      // 2. Hapus dokumen dari Firestore
      await _lombaCollection.doc(id).delete();
    } catch (e) {
      print("Error deleteLomba: $e");
    }
  }
}
