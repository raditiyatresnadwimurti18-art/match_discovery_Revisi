import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/database/sql_lite.dart';
import 'package:match_discovery/models/admin_model.dart';
import 'package:match_discovery/models/login_model.dart';
import 'package:sqflite/sqflite.dart';

class AuthController {
  // ==================== USER ====================

  static Future<void> registerUser(LoginModel user) async {
    final dbs = await DBHelper.db();
    await dbs.insert(
      'user',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print(user.toMap());
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

      // ✅ FIX: Set role DULU sebelum menyimpan ID
      // Sebelumnya storingId dipanggil sebelum setRole,
      // sehingga role masih null/admin → ID user tersimpan di key yang salah
      await PreferenceHandler.setRole('user');
      await PreferenceHandler.storingUserId(
        data.id!,
      ); // ← pakai key khusus user
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

      // ✅ FIX: Set role DULU sebelum menyimpan ID
      await PreferenceHandler.setRole('admin');
      await PreferenceHandler.storingAdminId(
        admin.id!,
      ); // ← pakai key khusus admin
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
      // ✅ FIX: Set role DULU sebelum menyimpan ID
      await PreferenceHandler.setRole('admin');
      await PreferenceHandler.storingAdminId(result.first['id'] as int);
      await PreferenceHandler.storingIsLogin(true);
      return true;
    }
    return false;
  }
}
