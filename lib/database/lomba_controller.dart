import 'package:match_discovery/database/sql_lite.dart';
import 'package:match_discovery/models/lomba_model.dart';

import 'package:sqflite/sqflite.dart';

class LombaControler {
  // 1. Fungsi Simpan Lomba (Create)
  static Future<void> insertLomba(LombaModel data) async {
    final dbs = await DBHelper.db();

    await dbs.insert(
      'lomba',
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm
          .replace, // Jika ID sama, akan ditimpa (update otomatis)
    );
  }

  // 2. Fungsi Ambil Semua Lomba (Read)
  static Future<List<LombaModel>> getAllLomba() async {
    final dbs = await DBHelper.db();

    // Mengambil data dari tabel 'lomba' diurutkan dari yang terbaru
    final List<Map<String, dynamic>> result = await dbs.query(
      "lomba",
      orderBy: "id DESC",
    );

    // Mengonversi List Map menjadi List Model
    return result.map((e) => LombaModel.fromMap(e)).toList();
  }

  // 3. Fungsi Update Lomba (Update)
  static Future<int> updateLomba(LombaModel data) async {
    final dbs = await DBHelper.db();

    if (data.id == null) {
      throw Exception("Gagal Update: ID Lomba tidak ditemukan");
    }

    return await dbs.update(
      'lomba',
      data.toMap(),
      where: 'id = ?',
      whereArgs: [data.id],
    );
  }

  // 4. Fungsi Hapus Lomba (Delete)
  static Future<int> deleteLomba(int id) async {
    final dbs = await DBHelper.db();

    return await dbs.delete('lomba', where: 'id = ?', whereArgs: [id]);
  }
}
