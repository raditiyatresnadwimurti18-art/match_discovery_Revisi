import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/database/sql_lite.dart';
import 'package:match_discovery/models/admin_model.dart';
import 'package:match_discovery/models/login_model.dart';
import 'package:sqflite/sqflite.dart';

class AuthController {
  // ==================== USER ====================

  /// ✅ FIX: Return false jika email sudah terdaftar, true jika berhasil
  static Future<bool> registerUser(LoginModel user) async {
    final dbs = await DBHelper.db();

    // Cek apakah email sudah dipakai
    final existing = await dbs.query(
      'user',
      where: 'email = ?',
      whereArgs: [user.email],
    );

    // ✅ Jika sudah ada → tolak registrasi
    if (existing.isNotEmpty) return false;

    await dbs.insert(
      'user',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return true;
  }

  static Future<LoginModel?> loginUser({
    required String email,
    required String password,
  }) async {
    final dbs = await DBHelper.db();
    final result = await dbs.query(
      'user',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (result.isNotEmpty) {
      final data = LoginModel.fromMap(result.first);

      // ✅ Set role dulu sebelum simpan ID
      await PreferenceHandler.setRole('user');
      await PreferenceHandler.storingUserId(data.id!);
      await PreferenceHandler.storingIsLogin(true);

      return data;
    }
    return null;
  }

  // ==================== ADMIN ====================

  static Future<AdminModel?> loginAdminModel({
    required String username,
    required String password,
  }) async {
    final dbs = await DBHelper.db();
    final result = await dbs.query(
      'admin',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (result.isNotEmpty) {
      final admin = AdminModel.fromMap(result.first);
      await PreferenceHandler.setRole('admin');
      await PreferenceHandler.storingAdminId(admin.id!);
      await PreferenceHandler.storingIsLogin(true);
      return admin;
    }
    return null;
  }

  static Future<bool> loginAdmin({
    required String username,
    required String password,
  }) async {
    final dbs = await DBHelper.db();
    final result = await dbs.query(
      'admin',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (result.isNotEmpty) {
      await PreferenceHandler.setRole('admin');
      await PreferenceHandler.storingAdminId(result.first['id'] as int);
      await PreferenceHandler.storingIsLogin(true);
      return true;
    }
    return false;
  }
}
