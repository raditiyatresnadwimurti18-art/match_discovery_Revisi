import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:match_discovery/database/controllers/auth.dart';
import 'package:match_discovery/database/firebase_service.dart';
import 'package:match_discovery/models/admin_model.dart';

class AdminController {
  static final CollectionReference _adminsCollection =
      FirebaseFirestore.instance.collection('admins');

  // ==================== CREATE ====================

  static Future<String?> addAdmin(AdminModel newAdmin) async {
    try {
      // ✅ Gunakan AuthController untuk registrasi (Auth + Firestore)
      String result = await AuthController.registerAdmin(newAdmin);
      
      if (result == 'success') {
        print("AdminController: Berhasil menambah admin ke Auth dan Firestore.");
        return "success";
      } else {
        print("AdminController: Gagal menambah admin ($result)");
        return null;
      }
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

  static Stream<List<AdminModel>> getAdminsStream() {
    return _adminsCollection.snapshots().map((snapshot) {
      List<AdminModel> admins = snapshot.docs
          .map((doc) => AdminModel.fromMap(doc.data() as Map<String, dynamic>,
              docId: doc.id))
          .toList();

      // Tambahkan Super Admin Lokal jika belum ada di list Firestore
      bool superAdminExists =
          admins.any((a) => a.username == '111' || a.id == 'super_admin_local');

      if (!superAdminExists) {
        admins.insert(
            0,
            AdminModel(
              id: 'super_admin_local',
              username: '111',
              password: '222',
              nama: 'Super Admin',
              role: 'super',
              profilePath: '',
            ));
      }
      return admins;
    });
  }

  static Future<List<AdminModel>> getSemuaAdmin() async {
    try {
      QuerySnapshot querySnapshot = await _adminsCollection.get();

      List<AdminModel> admins = querySnapshot.docs
          .map((doc) => AdminModel.fromMap(doc.data() as Map<String, dynamic>,
              docId: doc.id))
          .toList();

      // Tambahkan Super Admin Lokal jika belum ada
      bool superAdminExists =
          admins.any((a) => a.username == '111' || a.id == 'super_admin_local');

      if (!superAdminExists) {
        admins.insert(
            0,
            AdminModel(
              id: 'super_admin_local',
              username: '111',
              password: '222',
              nama: 'Super Admin',
              role: 'super',
              profilePath: '',
            ));
      }
      return admins;
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
          try {
            DocumentSnapshot oldDoc = await _adminsCollection.doc(admin.id).get();
            if (oldDoc.exists) {
              Map<String, dynamic> data = oldDoc.data() as Map<String, dynamic>;
              String? oldUrl = data['profilePath'];
              if (oldUrl != null && oldUrl.startsWith('http')) {
                await StorageService.deleteImage(oldUrl);
              }
            }
          } catch (e) {
            print("AdminController: Gagal menghapus foto lama (abaikan): $e");
          }
          
          // 3. Simpan URL baru ke Firestore
          await _adminsCollection.doc(admin.id).set({
            'profilePath': downloadUrl,
          }, SetOptions(merge: true));
          
          print("AdminController: URL Foto Profil berhasil disimpan di Firestore.");
          return true;
        } else {
          // ❌ GAGAL UPLOAD
          print("AdminController ERROR: Gagal upload ke storage. Update Firestore dibatalkan.");
          return false;
        }
      }
      return false;
    } catch (e) {
      print("AdminController Error (updateAdminProfile): $e");
      return false;
    }
  }

  static Future<bool> updateAdminDetail(
    String id,
    String nama,
    String username,
    String password,
  ) async {
    if (id == 'super_admin_local') return false; // Lewati jika akun lokal
    try {
      // 1. Ambil data lama untuk mendapatkan email dan password lama (untuk Auth update)
      DocumentSnapshot doc = await _adminsCollection.doc(id).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String? email = data['email'];
        String? oldPassword = data['password'];

        // 2. Update Firebase Authentication jika password berubah
        if (email != null && oldPassword != null && oldPassword != password) {
          bool authSuccess = await AuthController.updateAdminAuth(
            email: email,
            oldPassword: oldPassword,
            newPassword: password,
          );
          if (!authSuccess) {
            print("AdminController: Gagal memperbarui Auth, update Firestore dibatalkan.");
            return false;
          }
        }
      }

      // 3. Update Firestore
      await _adminsCollection.doc(id).update({
        'nama': nama,
        'username': username,
        'password': password,
      });
      return true;
    } catch (e) {
      print("Error updateAdminDetail: $e");
      return false;
    }
  }

  static Future<void> updateOnlineStatus(String adminId, bool isOnline) async {
    if (adminId == 'super_admin_local') return;
    try {
      await _adminsCollection.doc(adminId).update({
        'isOnline': isOnline,
        'lastActive': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Error updateOnlineStatus Admin: $e");
    }
  }

  // ==================== DELETE ====================

  static Future<bool> deleteAdmin(String id) async {
    try {
      // 1. Ambil data admin sebelum dihapus
      DocumentSnapshot doc = await _adminsCollection.doc(id).get();
      if (!doc.exists) return false;
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String? email = data['email'];
      String? password = data['password'];
      String? imageUrl = data['profilePath'];

      // 2. Hapus gambar dari Storage (No-op in Base64 mode, but kept for compatibility)
      if (imageUrl != null) {
        await StorageService.deleteImage(imageUrl);
      }

      // 3. Hapus dari Firebase Authentication (jika ada email & password)
      if (email != null && password != null) {
        bool authDeleted = await AuthController.deleteAdminAuth(email: email, password: password);
        if (!authDeleted) {
          print("AdminController: Gagal menghapus Auth, penghapusan Firestore dibatalkan.");
          return false;
        }
      }

      // 4. Hapus dokumen dari Firestore
      await _adminsCollection.doc(id).delete();
      print("AdminController: Berhasil menghapus admin dari Firestore dan Auth.");
      return true;
    } catch (e) {
      print("Error deleteAdmin: $e");
      return false;
    }
  }
}

