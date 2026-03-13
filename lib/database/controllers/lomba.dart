import 'package:match_discovery/database/sql_lite.dart';
import 'package:match_discovery/models/lomba_model.dart';
import 'package:sqflite/sqflite.dart';

class LombaController {
  // ==================== CREATE ====================

  static Future<void> insertLomba(LombaModel data) async {
    final dbs = await DBHelper.db();
    await dbs.insert(
      'lomba',
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==================== READ ====================

  static Future<List<LombaModel>> getAllLomba() async {
    final dbs = await DBHelper.db();
    final result = await dbs.query('lomba', orderBy: 'id DESC');
    return result.map((e) => LombaModel.fromMap(e)).toList();
  }

  // ==================== UPDATE ====================

  static Future<int> updateLomba(LombaModel data) async {
    final dbs = await DBHelper.db();
    if (data.id == null)
      throw Exception("Gagal Update: ID Lomba tidak ditemukan");
    return await dbs.update(
      'lomba',
      data.toMap(),
      where: 'id = ?',
      whereArgs: [data.id],
    );
  }

  // ==================== DELETE ====================

  static Future<int> deleteLomba(int id) async {
    final dbs = await DBHelper.db();
    return await dbs.delete('lomba', where: 'id = ?', whereArgs: [id]);
  }
}
