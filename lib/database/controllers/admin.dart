import 'package:match_discovery/database/sql_lite.dart';
import 'package:match_discovery/models/admin_model.dart';
import 'package:sqflite/sqflite.dart';

class AdminController {
  // ==================== CREATE ====================

  static Future<int> addAdmin(AdminModel newAdmin) async {
    final dbs = await DBHelper.db();
    try {
      return await dbs.insert(
        'admin',
        newAdmin.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print("Error saat menambah admin: $e");
      return -1;
    }
  }

  // ==================== READ ====================

  static Future<AdminModel?> getAdminById(int id) async {
    final dbs = await DBHelper.db();
    final result = await dbs.query('admin', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) return AdminModel.fromMap(result.first);
    return null;
  }

  static Future<List<AdminModel>> getSemuaAdmin() async {
    final dbs = await DBHelper.db();
    final maps = await dbs.query('admin', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => AdminModel.fromMap(maps[i]));
  }

  // ==================== UPDATE ====================

  static Future<int> updateAdminProfile(AdminModel admin) async {
    final dbs = await DBHelper.db();
    return await dbs.update(
      'admin',
      {
        'nama': admin.nama ?? 'Admin',
        'profilePath': admin.profilePath,
        'role': admin.role,
      },
      where: 'id = ?',
      whereArgs: [admin.id],
    );
  }

  static Future<int> updateAdminDetail(
    int id,
    String nama,
    String username,
    String password,
  ) async {
    final dbs = await DBHelper.db();
    return await dbs.update(
      'admin',
      {'nama': nama, 'username': username, 'password': password},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== DELETE ====================

  static Future<int> deleteAdmin(int id) async {
    final dbs = await DBHelper.db();
    return await dbs.delete('admin', where: 'id = ?', whereArgs: [id]);
  }
}
