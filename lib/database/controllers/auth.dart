import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/models/login_model.dart';
import 'package:match_discovery/models/admin_model.dart';

class AuthController {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== USER ====================

  /// Registrasi User baru.
  /// Return 'success' jika berhasil, atau pesan error Firebase jika gagal.
  static Future<String> registerUser(LoginModel user) async {
    try {
      // 1. Buat akun di Firebase Authentication
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: user.email!,
        password: user.password!,
      );

      String uid = credential.user!.uid;

      // 2. Simpan data tambahan ke Firestore koleksi 'users'
      await _db.collection('users').doc(uid).set({
        'id': uid,
        'nama': user.nama,
        'email': user.email,
        'tlpon': user.tlpon,
        'role': 'user',
      });

      return 'success';
    } on FirebaseAuthException catch (e) {
      print("Error Firebase Auth: ${e.code} - ${e.message}");
      // Kembalikan kode error spesifik dari Firebase
      return e.code;
    } catch (e) {
      print("Error registerUser: $e");
      return 'error';
    }
  }

  /// Login User/Admin menggunakan Firebase Auth.
  static Future<dynamic> login(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = credential.user!.uid;

      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String role = data['role'] ?? 'user';

        await PreferenceHandler.setRole(role);
        await PreferenceHandler.storingIsLogin(true);

        if (role == 'admin' || role == 'super') {
          await PreferenceHandler.storingAdminId(uid);
          return AdminModel.fromMap(data);
        } else {
          await PreferenceHandler.storingUserId(uid);
          return LoginModel.fromMap(data);
        }
      }
      return null;
    } catch (e) {
      print("Error login: $e");
      return null;
    }
  }

  // ==================== COMPATIBILITY ====================

  static Future<LoginModel?> loginUser({
    required String email,
    required String password,
  }) async {
    final result = await login(email, password);
    if (result is LoginModel) return result;
    return null;
  }

  static Future<AdminModel?> loginAdminModel({
    required String username,
    required String password,
  }) async {
    final result = await login(username, password);
    if (result is AdminModel) return result;
    return null;
  }

  static Future<bool> loginAdmin({
    required String username,
    required String password,
  }) async {
    final result = await login(username, password);
    return result != null && (result is AdminModel);
  }
}
