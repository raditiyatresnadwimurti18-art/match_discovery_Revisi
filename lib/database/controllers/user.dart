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

  static Stream<List<LoginModel>> getUsersStream() {
    return _usersCollection
        .where('role', isEqualTo: 'user')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LoginModel.fromMap(doc.data() as Map<String, dynamic>,
              docId: doc.id))
          .toList();
    });
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

  static Future<Map<String, dynamic>> updateUserProfile(String id, String localFilePath) async {
    try {
      print("UserController: Memulai proses update foto profil (User ID: $id)");

      // 1. Upload foto lokal ke Firebase Storage
      String? downloadUrl;
      try {
        downloadUrl = await StorageService.uploadImage(localFilePath, 'profile_images');
      } catch (e) {
        return {'success': false, 'message': e.toString()};
      }
      
      if (downloadUrl != null) {
        // 2. Ambil data lama untuk menghapus file di storage jika ada
        try {
          DocumentSnapshot userDoc = await _usersCollection.doc(id).get();
          if (userDoc.exists) {
            Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
            String? oldUrl = data['profilePath'];
            if (oldUrl != null && oldUrl.startsWith('http')) {
              await StorageService.deleteImage(oldUrl);
            }
          }
        } catch (e) {
          print("UserController: Gagal menghapus foto lama (abaikan): $e");
        }
        
        // 3. Simpan URL baru hasil upload ke field profilePath di Firestore
        await _usersCollection.doc(id).set({
          'profilePath': downloadUrl,
        }, SetOptions(merge: true));
        
        print("UserController: URL Foto Profil berhasil disimpan di Firestore.");
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Gagal mendapatkan URL hasil upload.'};
      }
    } catch (e) {
      print("UserController Error (updateUserProfile): $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<bool> updateUserDetail({
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
        'nama_search': nama.toLowerCase(),
        'email': email,
        'tlpon': tlpon,
        'asalKota': asalKota,
        'pendidikanTerakhir': pendidikanTerakhir,
        'asalSekolah': asalSekolah,
      });
      return true;
    } catch (e) {
      print("Error updateUserDetail: $e");
      return false;
    }
  }

  static Future<bool> updateUser(LoginModel user) async {
    if (user.id == null) return false;
    try {
      Map<String, dynamic> data = user.toMap();
      if (user.nama != null) {
        data['nama_search'] = user.nama!.toLowerCase();
      }
      await _usersCollection.doc(user.id!).update(data);
      return true;
    } catch (e) {
      print("Error updateUser: $e");
      return false;
    }
  }

  static Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _usersCollection.doc(userId).update({
        'isOnline': isOnline,
        'lastActive': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Error updateOnlineStatus: $e");
    }
  }

  // ==================== DELETE ====================

  static Future<bool> deleteUser(String id) async {
    try {
      // NOTE: Hanya menghapus dari Firestore. 
      // Untuk menghapus dari Firebase Auth, diperlukan Firebase Admin SDK atau Firebase Functions.
      await _usersCollection.doc(id).delete();
      return true;
    } catch (e) {
      print("Error deleteUser: $e");
      return false;
    }
  }
}
