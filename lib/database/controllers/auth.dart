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
      // ✅ Bersihkan sesi lama sebelum login baru
      await PreferenceHandler.clearAll();

      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = credential.user!.uid;
      
      // Cek di koleksi users (User Biasa)
      DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        await PreferenceHandler.storingIsLogin(true);
        await PreferenceHandler.setRole('user');
        await PreferenceHandler.storingUserId(uid);
        return LoginModel.fromMap(data, docId: uid);
      }
      
      // Jika tidak ada di users, cek di admins (Jika admin login pakai email/auth)
      DocumentSnapshot adminDoc = await _db.collection('admins').doc(uid).get();
      if (adminDoc.exists) {
        Map<String, dynamic> data = adminDoc.data() as Map<String, dynamic>;
        String role = data['role'] ?? 'admin';
        await PreferenceHandler.storingIsLogin(true);
        await PreferenceHandler.setRole(role);
        await PreferenceHandler.storingAdminId(uid);
        return AdminModel.fromMap(data, docId: uid);
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
    // ✅ Bersihkan sesi lama
    await PreferenceHandler.clearAll();

    // Check for hardcoded super admin credentials
    if (username == '111' && password == '222') {
      await PreferenceHandler.storingIsLogin(true);
      await PreferenceHandler.setRole('super');
      await PreferenceHandler.storingAdminId('super_admin_local');

      return AdminModel(
        id: 'super_admin_local',
        username: '111',
        password: '222',
        nama: 'Super Admin',
        role: 'super',
        profilePath: '',
      );
    }

    // Query Firestore for admin in 'admins' collection
    try {
      QuerySnapshot querySnapshot = await _db
          .collection('admins')
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = querySnapshot.docs.first;
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String role = data['role'] ?? 'admin';

        await PreferenceHandler.storingIsLogin(true);
        await PreferenceHandler.setRole(role);
        await PreferenceHandler.storingAdminId(doc.id);

        return AdminModel.fromMap(data, docId: doc.id);
      }
      return null;
    } catch (e) {
      print("Error loginAdminModel: $e");
      return null;
    }
  }

  static Future<bool> loginAdmin({
    required String username,
    required String password,
  }) async {
    final result = await loginAdminModel(
      username: username,
      password: password,
    );
    return result != null;
  }
}
