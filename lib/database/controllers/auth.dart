import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/database/firebase_service.dart';
import 'package:match_discovery/database/notification_service.dart';
import 'package:match_discovery/firebase_options.dart';
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
        
        // Subscribe to notifications
        await NotificationService.subscribeToLombaTopic();
        NotificationService.listenToNewLomba(); // Mulai dengarkan data baru
        
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
        
        // Subscribe to notifications
        await NotificationService.subscribeToLombaTopic();
        NotificationService.listenToNewLomba(); // Mulai dengarkan data baru
        
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

  // ==================== ADMIN ====================

  /// Registrasi Admin baru ke Firebase Auth dan Firestore.
  static Future<String> registerAdmin(AdminModel admin) async {
    FirebaseApp? tempApp;
    try {
      // 1. Buat akun di Firebase Authentication
      // Jika email tidak ada, gunakan username sebagai basis email
      String emailToRegister = admin.email ?? "${admin.username}@admin.com";
      
      print("AuthController: Mendaftarkan admin baru $emailToRegister ke Auth...");

      // Gunakan Firebase App sementara agar Super Admin tidak ter-logout
      String tempAppName = "RegisterAdminApp_${DateTime.now().millisecondsSinceEpoch}";
      tempApp = await Firebase.initializeApp(
        name: tempAppName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);
// 1. Registrasi di Firebase Authentication
UserCredential credential = await tempAuth.createUserWithEmailAndPassword(
  email: emailToRegister,
  password: admin.password,
);

String uid = credential.user!.uid;
print("AuthController: Berhasil registrasi Auth. UID: $uid");

// 1.5 Proses Gambar Profil ke Base64 jika ada
String finalProfilePath = admin.profilePath ?? '';
if (finalProfilePath.isNotEmpty && !finalProfilePath.startsWith('http') && !finalProfilePath.startsWith('data:image')) {
  try {
    // Gunakan StorageService yang sudah kita ubah ke mode Base64
    String? base64Result = await StorageService.uploadImage(finalProfilePath, 'profile_images');
    if (base64Result != null) {
      finalProfilePath = base64Result;
    }
  } catch (e) {
    print("AuthController: Gagal konversi gambar admin ke Base64: $e");
  }
}

// 2. Simpan data tambahan ke Firestore koleksi 'admins'
await _db.collection('admins').doc(uid).set({
  'id': uid,
  'nama': admin.nama,
  'username': admin.username,
  'email': emailToRegister,
  'password': admin.password,
  'role': admin.role,
  'profilePath': finalProfilePath,
});


      // 3. Hapus app sementara
      await tempApp.delete();
      tempApp = null;

      return 'success';
    } on FirebaseAuthException catch (e) {
      print("Error Firebase Auth Admin: ${e.code} - ${e.message}");
      if (tempApp != null) await tempApp.delete();
      return e.code; // Misal: 'email-already-in-use', 'weak-password'
    } catch (e) {
      print("Error registerAdmin: $e");
      if (tempApp != null) await tempApp.delete();
      return 'error';
    }
  }

  /// Login Admin menggunakan Firebase Auth.
  static Future<AdminModel?> loginAdminModel({
    required String username,
    required String password,
  }) async {
    // ✅ Bersihkan sesi lama
    await PreferenceHandler.clearAll();

    // 1. Check for hardcoded super admin credentials
    if (username == '111' && password == '222') {
      try {
        print("AuthController: Mencoba Login Auth untuk Super Admin...");
        await _auth.signInWithEmailAndPassword(
          email: "111@admin.com",
          password: "222",
        );
      } catch (e) {
        print("AuthController: Login gagal, mencoba pendaftaran otomatis Super Admin...");
        try {
          await _auth.createUserWithEmailAndPassword(
            email: "111@admin.com",
            password: "222",
          );
          // Simpan juga ke Firestore agar konsisten
          await _db.collection('admins').doc(_auth.currentUser!.uid).set({
            'id': _auth.currentUser!.uid,
            'nama': 'Super Admin',
            'username': '111',
            'email': '111@admin.com',
            'password': '222',
            'role': 'super',
            'profilePath': '',
          });
        } catch (e2) {
          print("AuthController ERROR Kritis: Gagal mendaftarkan Super Admin otomatis: $e2");
        }
      }

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

    // 2. Coba login via Firebase Auth
    try {
      print("AuthController: Mencoba mencari data admin untuk: $username");
      String? targetEmail;
      
      // A. Cek apakah yang diinput adalah format email
      if (username.contains('@')) {
        targetEmail = username;
      } else {
        // B. Jika bukan email, cari email berdasarkan username di Firestore
        QuerySnapshot adminSearch = await _db
            .collection('admins')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();

        if (adminSearch.docs.isNotEmpty) {
          targetEmail = adminSearch.docs.first.get('email');
        }
      }

      // C. Jika email tetap tidak ditemukan, gunakan default (format lama)
      targetEmail ??= "${username}@admin.com";

      print("AuthController: Mencoba SignIn Auth dengan Email: $targetEmail");
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: targetEmail,
        password: password,
      );

      String uid = credential.user!.uid;
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
      print("Error loginAdminModel via Auth: $e");
      
      // Fallback ke pencarian Firestore jika Auth gagal (untuk akun lama yang belum di Auth)
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
      } catch (e2) {
        print("Fallback loginAdminModel failed: $e2");
      }
      
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

  // ==================== RESET PASSWORD ====================

  /// Mengirim email reset password ke pengguna.
  static Future<String> forgotPassword(String email) async {
    try {
      // 1. Cek di koleksi users
      final userQuery = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      // 2. Jika tidak ada di users, cek di koleksi admins
      if (userQuery.docs.isEmpty) {
        final adminQuery = await _db
            .collection('admins')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        
        if (adminQuery.docs.isEmpty) {
          return 'user-not-found';
        }
      }

      // 3. Jika ditemukan di salah satu koleksi, kirim email reset
      await _auth.sendPasswordResetEmail(email: email);
      return 'success';
    } on FirebaseAuthException catch (e) {
      print("Error Firebase Auth Reset Password: ${e.code} - ${e.message}");
      return e.code;
    } catch (e) {
      print("Error forgotPassword: $e");
      return 'error';
    }
  }

  // ==================== DELETE ====================

  /// Menghapus akun dari Firebase Authentication.
  /// Karena Firebase Client SDK tidak mengizinkan menghapus user lain secara langsung,
  /// kita menggunakan teknik temporary Firebase App jika password diketahui (untuk Admin),
  /// atau hanya bisa menghapus diri sendiri.
  static Future<bool> deleteAdminAuth({required String email, required String password}) async {
    try {
      print("AuthController: Mencoba menghapus Auth untuk $email");
      
      // Gunakan Firebase App sementara agar tidak mengganggu login Admin yang sedang aktif
      String tempAppName = "DeleteUserApp_${DateTime.now().millisecondsSinceEpoch}";
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: tempAppName,
        options: Firebase.app().options,
      );
      
      FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      
      // 1. Login sebagai user yang akan dihapus
      UserCredential cred = await tempAuth.signInWithEmailAndPassword(email: email, password: password);
      
      // 2. Hapus akun
      await cred.user?.delete();
      
      // 3. Bersihkan app sementara
      await tempApp.delete();
      
      print("AuthController: Berhasil menghapus Auth user $email");
      return true;
    } catch (e) {
      print("AuthController ERROR (deleteAdminAuth): $e");
      return false;
    }
  }

  /// Memperbarui password di Firebase Authentication.
  static Future<bool> updateAdminAuth({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      print("AuthController: Memperbarui password Auth untuk $email");
      
      // Jika password tidak berubah, abaikan
      if (oldPassword == newPassword) return true;

      // Gunakan Firebase App sementara
      String tempAppName = "UpdateUserApp_${DateTime.now().millisecondsSinceEpoch}";
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: tempAppName,
        options: Firebase.app().options,
      );
      
      FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      
      // 1. Login dengan password lama
      UserCredential cred = await tempAuth.signInWithEmailAndPassword(email: email, password: oldPassword);
      
      // 2. Update password
      await cred.user?.updatePassword(newPassword);
      
      // 3. Bersihkan app sementara
      await tempApp.delete();
      
      print("AuthController: Berhasil memperbarui password Auth untuk $email");
      return true;
    } catch (e) {
      print("AuthController ERROR (updateAdminAuth): $e");
      return false;
    }
  }
}
