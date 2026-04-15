import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:match_discovery/database/firebase_service.dart';
import 'package:match_discovery/models/admin_model.dart';

class AdminController {
  static final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  // ==================== CREATE ====================

  static Future<String?> addAdmin(AdminModel newAdmin) async {
    try {
      DocumentReference docRef = await _usersCollection.add(newAdmin.toMap());
      return docRef.id;
    } catch (e) {
      print("Error saat menambah admin: $e");
      return null;
    }
  }

  // ==================== READ ====================

  static Future<AdminModel?> getAdminById(String id) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(id).get();
      if (!doc.exists) return null;
      return AdminModel.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);
    } catch (e) {
      print("Error getAdminById: $e");
      return null;
    }
  }

  static Future<List<AdminModel>> getSemuaAdmin() async {
    try {
      QuerySnapshot querySnapshot = await _usersCollection
          .where('role', whereIn: ['admin', 'super'])
          .get();
      
      return querySnapshot.docs
          .map((doc) => AdminModel.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id))
          .toList();
    } catch (e) {
      print("Error getSemuaAdmin: $e");
      return [];
    }
  }

  // ==================== UPDATE ====================

  static Future<void> updateAdminProfile(AdminModel admin) async {
    if (admin.id == null) return;
    try {
      String? finalPath = admin.profilePath;

      // 1. Upload jika path lokal
      if (finalPath != null && !finalPath.startsWith('http') && finalPath.isNotEmpty) {
        String? downloadUrl = await StorageService.uploadImage(finalPath, 'profile_images');
        if (downloadUrl != null) {
          // Hapus gambar lama
          DocumentSnapshot oldDoc = await _usersCollection.doc(admin.id).get();
          if (oldDoc.exists) {
            String? oldUrl = (oldDoc.data() as Map<String, dynamic>)['profilePath'];
            await StorageService.deleteImage(oldUrl);
          }
          finalPath = downloadUrl;
        }
      }

      await _usersCollection.doc(admin.id).update({
        'nama': admin.nama ?? 'Admin',
        'profilePath': finalPath,
        'role': admin.role,
      });
    } catch (e) {
      print("Error updateAdminProfile: $e");
    }
  }

  static Future<void> updateAdminDetail(
    String id,
    String nama,
    String username,
    String password,
  ) async {
    try {
      await _usersCollection.doc(id).update({
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
      DocumentSnapshot doc = await _usersCollection.doc(id).get();
      if (doc.exists) {
        String? imageUrl = (doc.data() as Map<String, dynamic>)['profilePath'];
        await StorageService.deleteImage(imageUrl);
      }

      await _usersCollection.doc(id).delete();
    } catch (e) {
      print("Error deleteAdmin: $e");
    }
  }
}
