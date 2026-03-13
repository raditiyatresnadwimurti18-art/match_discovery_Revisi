import 'package:match_discovery/database/sql_lite.dart';
import 'package:match_discovery/models/riwayat_model.dart';
import 'package:match_discovery/models/riwayat_selesai_user.dart';
import 'package:sqflite/sqflite.dart';

class RiwayatController {
  // ==================== PENDAFTARAN ====================

  static Future<void> ikutiLomba(RiwayatModel riwayat) async {
    final dbs = await DBHelper.db();
    try {
      await dbs.transaction((txn) async {
        final check = await txn.query(
          'riwayat',
          where: 'idUser = ? AND idLomba = ? AND status = ?',
          whereArgs: [riwayat.idUser, riwayat.idLomba, 'aktif'],
        );
        if (check.isNotEmpty) return;

        await txn.insert('riwayat', {
          'idUser': riwayat.idUser,
          'idLomba': riwayat.idLomba,
          'tanggalDaftar': riwayat.tanggalDaftar,
          'status': 'aktif',
        });

        await txn.rawUpdate('UPDATE lomba SET kuota = kuota - 1 WHERE id = ?', [
          riwayat.idLomba,
        ]);

        final res = await txn.query(
          'lomba',
          where: 'id = ?',
          whereArgs: [riwayat.idLomba],
        );

        if (res.isNotEmpty && (res.first['kuota'] as int) <= 0) {
          final cek = await txn.query(
            'riwayatEvent',
            where: 'idLombaAsli = ?',
            whereArgs: [riwayat.idLomba],
          );

          if (cek.isEmpty) {
            final lombaSelesai = Map<String, dynamic>.from(res.first);
            final idAsli = lombaSelesai['id'] as int;
            lombaSelesai
              ..remove('id')
              ..remove('kuota');
            lombaSelesai['idLombaAsli'] = idAsli;

            await txn.insert(
              'riwayatEvent',
              lombaSelesai,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            await txn.delete('lomba', where: 'id = ?', whereArgs: [idAsli]);
          }
        }
      });
    } catch (e) {
      print("Error ikutiLomba: $e");
    }
  }

  static Future<bool> isUserSedangIkutLomba(int userId, int lombaId) async {
    final dbs = await DBHelper.db();
    final result = await dbs.query(
      'riwayat',
      where: 'idUser = ? AND idLomba = ? AND status = ?',
      whereArgs: [userId, lombaId, 'aktif'],
    );
    return result.isNotEmpty;
  }

  static Future<int> konfirmasiSelesaiManual(int userId, int lombaId) async {
    final dbs = await DBHelper.db();

    final result = await dbs.update(
      'riwayat',
      {'status': 'selesai'},
      where: 'idUser = ? AND idLomba = ?',
      whereArgs: [userId, lombaId],
    );

    String? judulLomba;
    final lombaRes = await dbs.query(
      'lomba',
      where: 'id = ?',
      whereArgs: [lombaId],
    );
    if (lombaRes.isNotEmpty) {
      judulLomba = lombaRes.first['judul'] as String?;
    } else {
      final eventRes = await dbs.query(
        'riwayatEvent',
        where: 'idLombaAsli = ?',
        whereArgs: [lombaId],
      );
      if (eventRes.isNotEmpty) {
        judulLomba = eventRes.first['judul'] as String?;
      }
    }

    await dbs.insert(
      'riwayatSelesai',
      RiwayatSelesaiModel(
        idUser: userId,
        judulLomba: judulLomba ?? 'Tidak Diketahui',
        tanggalSelesai: DateTime.now().toIso8601String().split('T').first,
      ).toMap(),
    );

    return result;
  }

  // ==================== RIWAYAT USER ====================

  static Future<List<Map<String, dynamic>>> getRiwayatUser(int userId) async {
    final dbs = await DBHelper.db();
    return await dbs.rawQuery(
      '''
      SELECT
        riwayat.id          AS idRiwayat,
        riwayat.idLomba,
        riwayat.status,
        COALESCE(lomba.judul,         re.judul)      AS judul,
        COALESCE(lomba.lokasi,        re.lokasi)     AS lokasi,
        COALESCE(lomba.tanggal,       re.tanggal)    AS tanggal,
        COALESCE(lomba.gambarPath,    re.gambarPath) AS gambarPath
      FROM riwayat
      LEFT JOIN lomba        ON riwayat.idLomba = lomba.id
      LEFT JOIN riwayatEvent re ON riwayat.idLomba = re.idLombaAsli
      WHERE riwayat.idUser = ?
        AND riwayat.status = 'aktif'
      ORDER BY riwayat.id DESC
      ''',
      [userId],
    );
  }

  // ==================== TRACK RECORD ====================

  static Future<List<Map<String, dynamic>>> getTrackRecordUser(
    int userId,
  ) async {
    final dbs = await DBHelper.db();
    return await dbs.rawQuery(
      '''
      SELECT
        judulLomba,
        COUNT(*) AS jumlahIkut,
        MAX(tanggalSelesai) AS terakhirIkut
      FROM riwayatSelesai
      WHERE idUser = ?
      GROUP BY judulLomba
      ORDER BY jumlahIkut DESC
      ''',
      [userId],
    );
  }

  static Future<int> getTotalSelesaiUser(int userId) async {
    final dbs = await DBHelper.db();
    final res = await dbs.rawQuery(
      'SELECT COUNT(*) AS total FROM riwayatSelesai WHERE idUser = ?',
      [userId],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  // ==================== RIWAYAT EVENT ====================

  static Future<List<Map<String, dynamic>>> getRiwayatEvent() async {
    final dbs = await DBHelper.db();
    return await dbs.rawQuery(
      'SELECT DISTINCT id, judul, lokasi, tanggal, gambarPath, deskripsi '
      'FROM riwayatEvent ORDER BY id DESC',
    );
  }

  static Future<int> deleteRiwayatEvent(int id) async {
    final dbs = await DBHelper.db();
    return await dbs.delete('riwayatEvent', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteAllRiwayatEvent() async {
    final dbs = await DBHelper.db();
    return await dbs.delete('riwayatEvent');
  }
}
