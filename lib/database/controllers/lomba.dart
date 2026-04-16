import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:match_discovery/database/firebase_service.dart';
import 'package:match_discovery/models/lomba_model.dart';

class LombaController {
  static final CollectionReference _lombaCollection =
      FirebaseFirestore.instance.collection('lomba');

  // ==================== READ ====================

  static Future<List<LombaModel>> getAllLomba() async {
    try {
      QuerySnapshot querySnapshot = await _lombaCollection.get();
      return querySnapshot.docs.map((doc) {
        return LombaModel.fromMap(doc.data() as Map<String, dynamic>,
            docId: doc.id);
      }).toList();
    } catch (e) {
      print("Error getAllLomba: $e");
      return [];
    }
  }

  // ==================== CREATE ====================

  static Future<Map<String, dynamic>> insertLomba(LombaModel data) async {
    try {
      print("LombaController: Menambahkan lomba baru...");
      String? downloadUrl = data.gambarPath;

      // 1. Upload gambar jika path-nya adalah path lokal HP
      if (data.gambarPath != null && !data.gambarPath!.startsWith('http') && data.gambarPath!.isNotEmpty) {
        try {
          downloadUrl = await StorageService.uploadImage(data.gambarPath!, 'lomba_images');
        } catch (e) {
          return {'success': false, 'message': e.toString()};
        }
      }

      // 2. Gunakan ID otomatis dari Firestore
      DocumentReference docRef = _lombaCollection.doc();
      
      // 3. Update model dengan URL hasil upload dan ID dokumen
      LombaModel finalData = LombaModel(
        id: docRef.id,
        judul: data.judul,
        gambarPath: downloadUrl,
        kuota: data.kuota,
        jenis: data.jenis,
        tanggal: data.tanggal,
        lokasi: data.lokasi,
        deskripsi: data.deskripsi,
      );

      // 4. Simpan ke Firestore
      await docRef.set(finalData.toMap());
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== UPDATE ====================

  static Future<Map<String, dynamic>> updateLomba(LombaModel data) async {
    if (data.id == null) return {'success': false, 'message': 'ID Lomba tidak ditemukan.'};
    
    try {
      String? finalUrl = data.gambarPath;

      // 1. Cek apakah gambar diubah ke file lokal baru
      if (data.gambarPath != null && !data.gambarPath!.startsWith('http') && data.gambarPath!.isNotEmpty) {
        try {
          finalUrl = await StorageService.uploadImage(data.gambarPath!, 'lomba_images');
          
          if (finalUrl != null) {
            // Hapus gambar lama
            DocumentSnapshot oldDoc = await _lombaCollection.doc(data.id).get();
            if (oldDoc.exists) {
              Map<String, dynamic> oldData = oldDoc.data() as Map<String, dynamic>;
              String? oldUrl = oldData['gambarPath'];
              if (oldUrl != null && oldUrl.startsWith('http')) {
                await StorageService.deleteImage(oldUrl);
              }
            }
          }
        } catch (e) {
          return {'success': false, 'message': e.toString()};
        }
      }
      
      // 2. Update data di Firestore
      Map<String, dynamic> updateData = data.toMap();
      updateData['gambarPath'] = finalUrl;
      
      await _lombaCollection.doc(data.id).update(updateData);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
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
