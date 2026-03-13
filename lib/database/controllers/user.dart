import 'package:match_discovery/database/sql_lite.dart';
import 'package:match_discovery/models/login_model.dart';

class UserController {
  // ==================== READ ====================

  static Future<LoginModel?> getUserById(int id) async {
    final dbs = await DBHelper.db();
    final result = await dbs.query('user', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) return LoginModel.fromMap(result.first);
    print("User dengan ID $id tidak ditemukan di DB");
    return null;
  }

  static Future<List<LoginModel>> getAllUser() async {
    final dbs = await DBHelper.db();
    final result = await dbs.query('user');
    final users = result.map((e) => LoginModel.fromMap(e)).toList();
    print(users);
    return users;
  }

  // ==================== UPDATE ====================

  static Future<int> updateUserProfile(int id, String imagePath) async {
    final dbs = await DBHelper.db();
    return await dbs.update(
      'user',
      {'profilePath': imagePath},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> updateUserDetail({
    required int id,
    required String nama,
    required String email,
    required String tlpon,
    required String asalKota,
    required String pendidikanTerakhir,
    required String asalSekolah,
  }) async {
    final dbs = await DBHelper.db();
    return await dbs.update(
      'user',
      {
        'nama': nama,
        'email': email,
        'tlpon': tlpon,
        'asalKota': asalKota,
        'pendidikanTerakhir': pendidikanTerakhir,
        'asalSekolah': asalSekolah,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> updateUser(LoginModel user) async {
    final dbs = await DBHelper.db();
    if (user.id == null) throw Exception("ID wajib ada");
    return await dbs.update(
      'user',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // ==================== DELETE ====================

  static Future<int> deleteUser(int id) async {
    final dbs = await DBHelper.db();
    return await dbs.delete('user', where: 'id = ?', whereArgs: [id]);
  }
}
