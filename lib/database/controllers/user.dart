import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:match_discovery/database/firebase_service.dart';
import 'package:match_discovery/models/login_model.dart';

class UserController {
  static final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  // ==================== READ ====================

  static Future<LoginModel?> getUserById(String id) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(id).get();
      if (doc.exists) {
        return LoginModel.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);
      }
      print("User dengan ID $id tidak ditemukan di Firestore");
      return null;
    } catch (e) {
      print("Error getUserById: $e");
      return null;
    }
  }

  static Future<List<LoginModel>> getAllUser() async {
    try {
      QuerySnapshot querySnapshot = await _usersCollection
          .where('role', isEqualTo: 'user')
          .get();
      
      return querySnapshot.docs
          .map((doc) => LoginModel.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id))
          .toList();
    } catch (e) {
      print("Error getAllUser: $e");
      return [];
    }
  }

  // ==================== UPDATE ====================

  static Future<bool> updateUserProfile(String id, String localFilePath) async {
    try {
      print("UserController: Memulai proses update foto profil (User ID: $id)");

      // 1. Upload foto lokal ke Firebase Storage
      String? downloadUrl = await StorageService.uploadImage(localFilePath, 'profile_images');
      
      if (downloadUrl != null) {
        // 2. Ambil data lama untuk menghapus file di storage jika ada
        DocumentSnapshot userDoc = await _usersCollection.doc(id).get();
        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          String? oldUrl = data['profilePath'];
          if (oldUrl != null && oldUrl.startsWith('http')) {
            await StorageService.deleteImage(oldUrl);
          }
        }
        
        // 3. Simpan URL baru hasil upload ke field profilePath di Firestore
        await _usersCollection.doc(id).update({
          'profilePath': downloadUrl,
        });
        print("UserController: URL Foto Profil berhasil disimpan di Firestore.");
        return true;
      } else {
        print("UserController ERROR: Gagal mendapatkan URL upload dari storage.");
        return false;
      }
    } catch (e) {
      print("UserController Error (updateUserProfile): $e");
      return false;
    }
  }

  static Future<void> updateUserDetail({
    required String id,
    required String nama,
    required String email,
    required String tlpon,
    required String asalKota,
    required String pendidikanTerakhir,
    required String asalSekolah,
  }) async {
    try {
      await _usersCollection.doc(id).update({
        'nama': nama,
        'email': email,
        'tlpon': tlpon,
        'asalKota': asalKota,
        'pendidikanTerakhir': pendidikanTerakhir,
        'asalSekolah': asalSekolah,
      });
    } catch (e) {
      print("Error updateUserDetail: $e");
    }
  }

  static Future<void> updateUser(LoginModel user) async {
    if (user.id == null) throw Exception("ID wajib ada");
    try {
      await _usersCollection.doc(user.id!).update(user.toMap());
    } catch (e) {
      print("Error updateUser: $e");
    }
  }

  // ==================== DELETE ====================

  static Future<void> deleteUser(String id) async {
    try {
      await _usersCollection.doc(id).delete();
    } catch (e) {
      print("Error deleteUser: $e");
    }
  }
}
