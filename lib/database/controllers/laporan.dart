import 'package:match_discovery/database/sql_lite.dart';

class LaporanController {
  static Future<List<Map<String, dynamic>>> getSemuaPendaftarGlobal() async {
    final dbs = await DBHelper.db();
    return await dbs.rawQuery('''
      SELECT
        COALESCE(lomba.judul, re.judul) AS judul_lomba,
        user.nama                       AS nama_user,
        user.tlpon                      AS telepon_user,
        riwayat.tanggalDaftar
      FROM riwayat
      INNER JOIN user            ON riwayat.idUser  = user.id
      LEFT JOIN  lomba           ON riwayat.idLomba = lomba.id
      LEFT JOIN  riwayatEvent re ON riwayat.idLomba = re.idLombaAsli
      WHERE COALESCE(lomba.judul, re.judul) IS NOT NULL
        AND riwayat.status = 'aktif'
      ORDER BY COALESCE(lomba.id, re.idLombaAsli) DESC
    ''');
  }

  static Future<List<Map<String, dynamic>>> getPendaftarByLomba(
    int idLomba,
  ) async {
    final dbs = await DBHelper.db();
    return await dbs.rawQuery(
      '''
      SELECT user.nama, user.tlpon, riwayat.tanggalDaftar
      FROM riwayat
      INNER JOIN user ON riwayat.idUser = user.id
      WHERE riwayat.idLomba = ?
        AND riwayat.status = 'aktif'
      ''',
      [idLomba],
    );
  }

  static Future<List<Map<String, dynamic>>>
  getAllLombaDenganJumlahPendaftar() async {
    final dbs = await DBHelper.db();
    return await dbs.rawQuery('''
      SELECT lomba.*, COUNT(riwayat.id) AS totalPendaftar
      FROM lomba
      LEFT JOIN riwayat ON lomba.id = riwayat.idLomba
        AND riwayat.status = 'aktif'
      GROUP BY lomba.id
      ORDER BY lomba.id DESC
    ''');
  }
}
