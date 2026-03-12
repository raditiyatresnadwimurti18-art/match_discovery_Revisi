import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/models/admin_model.dart';
import 'package:match_discovery/models/login_model.dart';
import 'package:match_discovery/models/riwayat_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  // ==================== INISIALISASI DATABASE ====================

  static Future<Database> db() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'Match_Discovery_v14_final_db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE user (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama TEXT, password TEXT, email TEXT, tlpon TEXT,
            profilePath TEXT, asalKota TEXT, pendidikanTerakhir TEXT, asalSekolah TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE lomba (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            judul TEXT, gambarPath TEXT, kuota INTEGER,
            jenis TEXT, tanggal TEXT, lokasi TEXT, deskripsi TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE riwayat (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            idUser INTEGER, idLomba INTEGER,
            tanggalDaftar TEXT, status TEXT DEFAULT 'aktif'
          )
        ''');
        await db.execute('''
          CREATE TABLE admin (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT, password TEXT,
            nama TEXT, profilePath TEXT, role TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE riwayatEvent (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            idLombaAsli INTEGER, judul TEXT, jenis TEXT,
            tanggal TEXT, lokasi TEXT, gambarPath TEXT, deskripsi TEXT
          )
        ''');
        await db.insert('admin', {
          'username': '111',
          'password': '222',
          'nama': 'Super Admin',
          'role': 'super',
          'profilePath': '',
        });
      },
    );
  }

  // ==================== AUTHENTICATION ====================

  static Future<void> registerUser(LoginModel user) async {
    final dbs = await db();
    await dbs.insert(
      'user',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<LoginModel?> loginUser({
    required String email,
    required String password,
  }) async {
    final dbs = await db();
    final result = await dbs.query(
      "user",
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (result.isNotEmpty) {
      final data = LoginModel.fromMap(result.first);
      await PreferenceHandler.storingId(data.id!);
      await PreferenceHandler.storingIsLogin(true);
      await PreferenceHandler.setRole('user');
      return data;
    }
    return null;
  }

  static Future<AdminModel?> loginAdminModel({
    required String username,
    required String password,
  }) async {
    final dbs = await db();
    final result = await dbs.query(
      "admin",
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (result.isNotEmpty) {
      AdminModel admin = AdminModel.fromMap(result.first);
      await PreferenceHandler.storingId(admin.id!);
      await PreferenceHandler.storingIsLogin(true);
      await PreferenceHandler.setRole('admin');
      return admin;
    }
    return null;
  }

  static Future<bool> loginAdmin({
    required String username,
    required String password,
  }) async {
    final dbs = await db();
    final result = await dbs.query(
      "admin",
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (result.isNotEmpty) {
      await PreferenceHandler.storingId(result.first['id'] as int);
      await PreferenceHandler.storingIsLogin(true);
      await PreferenceHandler.setRole('admin');
      return true;
    }
    return false;
  }

  // ==================== MANAJEMEN ADMIN ====================

  static Future<int> addAdmin(AdminModel newAdmin) async {
    final dbs = await db();
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

  static Future<AdminModel?> getAdminById(int id) async {
    final dbs = await db();
    final result = await dbs.query('admin', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) return AdminModel.fromMap(result.first);
    return null;
  }

  static Future<int> updateAdminProfile(AdminModel admin) async {
    final dbs = await db();
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

  static Future<List<AdminModel>> getSemuaAdmin() async {
    final dbs = await db();
    final maps = await dbs.query('admin', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => AdminModel.fromMap(maps[i]));
  }

  static Future<int> deleteAdmin(int id) async {
    final dbs = await db();
    return await dbs.delete('admin', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> updateAdminDetail(
    int id,
    String nama,
    String username,
    String password,
  ) async {
    final dbs = await db();
    return await dbs.update(
      'admin',
      {'nama': nama, 'username': username, 'password': password},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== MANAJEMEN USER ====================

  static Future<LoginModel?> getUserById(int id) async {
    final dbs = await db();
    final result = await dbs.query("user", where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) return LoginModel.fromMap(result.first);
    print("User dengan ID $id tidak ditemukan di DB");
    return null;
  }

  static Future<int> updateUserProfile(int id, String imagePath) async {
    final dbs = await db();
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
    final dbs = await db();
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

  // ==================== MANAJEMEN LOMBA ====================

  static Future<void> insertLomba(Map<String, dynamic> data) async {
    final dbs = await db();
    await dbs.insert(
      'lomba',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getAllLomba() async {
    final dbs = await db();
    return await dbs.query('lomba', orderBy: "id DESC");
  }

  static Future<int> updateLomba(int id, Map<String, dynamic> data) async {
    final dbs = await db();
    return await dbs.update('lomba', data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteLomba(int id) async {
    final dbs = await db();
    return await dbs.delete('lomba', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== LOGIKA PENDAFTARAN ====================

  static Future<void> ikutiLomba(RiwayatModel riwayat) async {
    final dbs = await db();
    try {
      await dbs.transaction((txn) async {
        List<Map> check = await txn.query(
          'riwayat',
          where: 'idUser = ? AND idLomba = ?',
          whereArgs: [riwayat.idUser, riwayat.idLomba],
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

        List<Map<String, dynamic>> res = await txn.query(
          'lomba',
          where: 'id = ?',
          whereArgs: [riwayat.idLomba],
        );

        if (res.isNotEmpty && (res.first['kuota'] as int) <= 0) {
          List<Map<String, dynamic>> cek = await txn.query(
            'riwayatEvent',
            where: 'idLombaAsli = ?',
            whereArgs: [riwayat.idLomba],
          );

          if (cek.isEmpty) {
            Map<String, dynamic> lombaSelesai = Map.from(res.first);
            int idAsli = lombaSelesai['id'] as int;
            lombaSelesai.remove('id');
            lombaSelesai.remove('kuota');
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
    final dbs = await db();
    final result = await dbs.query(
      'riwayat',
      where: 'idUser = ? AND idLomba = ?',
      whereArgs: [userId, lombaId],
    );
    return result.isNotEmpty;
  }

  /// Update status riwayat menjadi 'selesai'.
  static Future<int> konfirmasiSelesaiManual(int userId, int lombaId) async {
    final dbs = await db();
    return await dbs.update(
      'riwayat',
      {'status': 'selesai'},
      where: 'idUser = ? AND idLomba = ?',
      whereArgs: [userId, lombaId],
    );
  }

  // ==================== RIWAYAT USER ====================

  /// FIX 1: Tambah filter WHERE status = 'aktif' agar item yang sudah
  /// dikonfirmasi selesai tidak muncul lagi di halaman riwayat aktif.
  /// FIX 2: Query debug — pastikan JOIN benar antara lomba & riwayatEvent.
  static Future<List<Map<String, dynamic>>> getRiwayatUser(int userId) async {
    final dbs = await db();
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
      LEFT JOIN lomba
        ON riwayat.idLomba = lomba.id
      LEFT JOIN riwayatEvent re
        ON riwayat.idLomba = re.idLombaAsli
      WHERE riwayat.idUser = ?
        AND riwayat.status = 'aktif'
      ORDER BY riwayat.id DESC
    ''',
      [userId],
    );
  }

  // ==================== RIWAYAT EVENT ====================

  static Future<List<Map<String, dynamic>>> getRiwayatEvent() async {
    final dbs = await db();
    return await dbs.rawQuery(
      'SELECT DISTINCT id, judul, lokasi, tanggal, gambarPath, deskripsi FROM riwayatEvent ORDER BY id DESC',
    );
  }

  static Future<int> deleteRiwayatEvent(int id) async {
    final dbs = await db();
    return await dbs.delete('riwayatEvent', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteAllRiwayatEvent() async {
    final dbs = await db();
    return await dbs.delete('riwayatEvent');
  }

  // ==================== LAPORAN ADMIN ====================

  static Future<List<Map<String, dynamic>>> getSemuaPendaftarGlobal() async {
    final dbs = await db();
    return await dbs.rawQuery('''
      SELECT
        COALESCE(lomba.judul, re.judul) AS judul_lomba,
        user.nama                       AS nama_user,
        user.tlpon                      AS telepon_user,
        riwayat.tanggalDaftar
      FROM riwayat
      INNER JOIN user ON riwayat.idUser = user.id
      LEFT JOIN  lomba ON riwayat.idLomba = lomba.id
      LEFT JOIN  riwayatEvent re ON riwayat.idLomba = re.idLombaAsli
      WHERE COALESCE(lomba.judul, re.judul) IS NOT NULL
      ORDER BY COALESCE(lomba.id, re.idLombaAsli) DESC
    ''');
  }

  static Future<List<Map<String, dynamic>>> getPendaftarByLomba(
    int idLomba,
  ) async {
    final dbs = await db();
    return await dbs.rawQuery(
      '''
      SELECT user.nama, user.tlpon, riwayat.tanggalDaftar
      FROM riwayat
      INNER JOIN user ON riwayat.idUser = user.id
      WHERE riwayat.idLomba = ?
    ''',
      [idLomba],
    );
  }

  static Future<List<Map<String, dynamic>>>
  getAllLombaDenganJumlahPendaftar() async {
    final dbs = await db();
    return await dbs.rawQuery('''
      SELECT lomba.*, COUNT(riwayat.id) AS totalPendaftar
      FROM lomba
      LEFT JOIN riwayat ON lomba.id = riwayat.idLomba
      GROUP BY lomba.id
      ORDER BY lomba.id DESC
    ''');
  }
}
