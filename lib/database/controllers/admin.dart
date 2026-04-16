import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:match_discovery/database/firebase_service.dart';
import 'package:match_discovery/models/admin_model.dart';

class AdminController {
  static final CollectionReference _adminsCollection =
      FirebaseFirestore.instance.collection('admins');

  // ==================== CREATE ====================

  static Future<String?> addAdmin(AdminModel newAdmin) async {
    try {
      DocumentReference docRef = await _adminsCollection.add(newAdmin.toMap());
      return docRef.id;
    } catch (e) {
      print("Error saat menambah admin: $e");
      return null;
    }
  }

  // ==================== READ ====================

  static Future<AdminModel?> getAdminById(String id) async {
    // ✅ Tambahkan penanganan untuk Super Admin Lokal
    if (id == 'super_admin_local') {
      return AdminModel(
        id: 'super_admin_local',
        username: '111',
        password: '222',
        nama: 'Super Admin',
        role: 'super',
        profilePath: '',
      );
    }

    try {
      DocumentSnapshot doc = await _adminsCollection.doc(id).get();
      if (!doc.exists) return null;
      return AdminModel.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);
    } catch (e) {
      print("Error getAdminById: $e");
      return null;
    }
  }

  static Future<List<AdminModel>> getSemuaAdmin() async {
    try {
      QuerySnapshot querySnapshot = await _adminsCollection.get();
      
      return querySnapshot.docs
          .map((doc) => AdminModel.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id))
          .toList();
    } catch (e) {
      print("Error getSemuaAdmin: $e");
      return [];
    }
  }

  // ==================== UPDATE ====================

  static Future<bool> updateAdminProfile(AdminModel admin) async {
    if (admin.id == null || admin.id == 'super_admin_local') {
      print("AdminController: Lewati update profile untuk akun lokal atau ID null.");
      return false;
    }
    
    try {
      print("AdminController: Memulai proses update foto profil Admin (ID: ${admin.id})");
      String? localPath = admin.profilePath;

      // Pastikan path-nya adalah path lokal HP sebelum mencoba upload
      if (localPath != null && !localPath.startsWith('http') && localPath.isNotEmpty) {
        // 1. Upload ke Storage
        String? downloadUrl = await StorageService.uploadImage(localPath, 'profile_images');
        
        if (downloadUrl != null) {
          // 2. Hapus file lama di Storage
          DocumentSnapshot oldDoc = await _adminsCollection.doc(admin.id).get();
          if (oldDoc.exists) {
            Map<String, dynamic> data = oldDoc.data() as Map<String, dynamic>;
            String? oldUrl = data['profilePath'];
            if (oldUrl != null && oldUrl.startsWith('http')) {
              await StorageService.deleteImage(oldUrl);
            }
          }
          
          // 3. Simpan URL baru ke Firestore
          await _adminsCollection.doc(admin.id).update({
            'profilePath': downloadUrl,
          });
          print("AdminController: URL Foto Profil berhasil disimpan di Firestore.");
          return true;
        } else {
          print("AdminController ERROR: Gagal mendapatkan URL upload dari storage.");
          return false;
        }
      }
      return false;
    } catch (e) {
      print("AdminController Error (updateAdminProfile): $e");
      return false;
    }
  }

  static Future<void> updateAdminDetail(
    String id,
    String nama,
    String username,
    String password,
  ) async {
    if (id == 'super_admin_local') return; // Lewati jika akun lokal
    try {
      await _adminsCollection.doc(id).update({
        'nama': nama,
        'username': username,
        'password': password,
      });
    } catch (e) {
      print("Error updateAdminDetail: $e");
    }
  }

  // ==================== DELETE ====================

  static Future<void> deleteAdmin(String id) async {
    try {
      // 1. Hapus gambar dari Storage
      DocumentSnapshot doc = await _adminsCollection.doc(id).get();
      if (doc.exists) {
        String? imageUrl = (doc.data() as Map<String, dynamic>)['profilePath'];
        await StorageService.deleteImage(imageUrl);
      }

      await _adminsCollection.doc(id).delete();
    } catch (e) {
      print("Error deleteAdmin: $e");
    }
  }
}

