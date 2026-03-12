import '../models/login_model.dart';
import 'sql_lite.dart';

class LoginController {
  static Future<void> registerUser(LoginModel user) async {
    final dbs = await DBHelper.db();
    await dbs.insert('user', user.toMap());
    print(user.toMap());
  }

  static Future<List<LoginModel>> getAlluser() async {
    final dbs = await DBHelper.db();
    final List<Map<String, dynamic>> result = await dbs.query("user");
    print(result.map((e) => LoginModel.fromMap(e)).toList());
    return result.map((e) => LoginModel.fromMap(e)).toList();
  }

  static Future<int> updateuser(LoginModel user) async {
    final dbs = await DBHelper.db();
    if (user.id == null) {
      throw Exception("ID Wajid ada");
    }
    return dbs.update(
      'user',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  static Future<int> deleteuser(int id) async {
    final dbs = await DBHelper.db();
    return dbs.delete('user', where: 'id = ?', whereArgs: [id]);
  }
}
