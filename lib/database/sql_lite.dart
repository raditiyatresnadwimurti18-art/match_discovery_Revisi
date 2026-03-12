import 'package:match_discovery/database/preferences.dart';

import 'package:match_discovery/models/login_model.dart';
import 'package:match_discovery/models/riwayat_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Future<Database> db() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'Match_Discovery_db'),
      version: 6,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE user (id INTEGER PRIMARY KEY AUTOINCREMENT, nama TEXT, password TEXT, email TEXT, tlpon TEXT, profilePath TEXT)',
        );
        await db.execute('''
          CREATE TABLE lomba (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            judul TEXT,
            gambarPath TEXT,
            kuota INTEGER,
            jenis TEXT,
            tanggal TEXT,
            lokasi TEXT,
            deskripsi TEXT
          )
        ''');
        await db.execute('''
        CREATE TABLE riwayat (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          idUser INTEGER,
          idLomba INTEGER,
          tanggalDaftar TEXT
        )
      ''');
        // Tabel Admin (BARU)
        await db.execute('''
          CREATE TABLE admin (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT,
            password TEXT
          )
        ''');

        // Opsional: Masukkan 1 akun admin default saat database dibuat
        await db.insert('admin', {'username': '111', 'password': '222'});
        await db.execute('''
  CREATE TABLE riwayatEvent (
    id INTEGER PRIMARY KEY AUTOINCREMENT, -- Tambahkan AUTOINCREMENT
    idLombaAsli INTEGER,                  -- Simpan ID asli di kolom berbeda
    judul TEXT,
    jenis TEXT,
    tanggal TEXT,
    lokasi TEXT,
    gambarPath TEXT,
    deskripsi TEXT
  )
''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          // Command untuk menambah tabel jika user melakukan update app
          await db.execute('''
            CREATE TABLE IF NOT EXISTS lomba (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              judul TEXT,
              gambarPath TEXT,
              kuota INTEGER,
              jenis TEXT,
              tanggal TEXT,
              lokasi TEXT,
              deskripsi TEXT
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE user ADD COLUMN profilePath TEXT');
        }
        if (oldVersion < 4) {
          await db.execute('''
          CREATE TABLE IF NOT EXISTS riwayat (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            idUser INTEGER,
            idLomba INTEGER,
            tanggalDaftar TEXT
          )
        ''');
        }
        if (oldVersion < 5) {
          // Tambah tabel admin jika user melakukan update ke versi 5
          await db.execute('''
            CREATE TABLE IF NOT EXISTS admin (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT,
              password TEXT
            )
          ''');

          // Tambahkan admin default
          await db.insert('admin', {
            'username': 'admin123',
            'password': 'adminpassword',
          });
        }
        if (oldVersion < 6) {
          await db.execute('DROP TABLE IF EXISTS riwayatEvent');
          await db.execute('''
    CREATE TABLE riwayatEvent (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      idLombaAsli INTEGER,
      judul TEXT,
      jenis TEXT,
      tanggal TEXT,
      lokasi TEXT,
      gambarPath TEXT,
      deskripsi TEXT
    )
  ''');
        }
      },
    );
  }

  // static Future<void> registerUser(LoginModel user) async {
  //   final dbs = await db();
  //   await dbs.insert(
  //     'user',
  //     user.toMap(),
  //     conflictAlgorithm: ConflictAlgorithm.replace, // Tambahkan ini
  //   );
  // }

  // static Future<LoginModel?> loginUser({
  //   required String email,
  //   required String password,
  // }) async {
  //   final dbs = await db();
  //   final List<Map<String, dynamic>> result = await dbs.query(
  //     "user",
  //     where: 'email = ? AND password = ?',
  //     whereArgs: [email, password],
  //   );
  //   if (result.isNotEmpty) {
  //     // 1. Ambil data user dari hasil query
  //     final data = LoginModel.fromMap(result.first);

  //     // 2. SIMPAN KE PREFERENCES (Bagian yang kamu tanyakan)
  //     // Ini agar aplikasi ingat siapa yang login saat dibuka kembali
  //     await PreferenceHandler.storingId(data.id!);
  //     await PreferenceHandler.storingIsLogin(true);
  //     await PreferenceHandler.setRole('user'); // Menandai bahwa ini adalah USER

  //     return data; // Kembalikan data untuk diproses di UI
  //   } else {
  //     return null; // Login gagal
  //   }
  // }
  // --- FUNGSI KHUSUS ADMIN ---

  static Future<bool> loginAdmin({
    required String username,
    required String password,
  }) async {
    final dbs = await db();
    final List<Map<String, dynamic>> result = await dbs.query(
      "admin",
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (result.isNotEmpty) {
      // --- MULAI TARUH DI SINI ---
      await PreferenceHandler.storingId(result.first['id']);
      await PreferenceHandler.storingIsLogin(true); // Menandai sudah login
      await PreferenceHandler.setRole('admin'); // Menandai sebagai ADMIN
      // --- SELESAI ---

      return true;
    } else {
      return false;
    }
  }

  static Future<LoginModel?> getUserById(int id) async {
    final dbs = await db(); // Memanggil fungsi db() yang sudah ada
    final List<Map<String, dynamic>> result = await dbs.query(
      "user",
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return LoginModel.fromMap(
        result.first,
      ); // Mengonversi hasil query menjadi objek
    }
    return null;
  }

  static Future<int> updateLomba(int id, Map<String, dynamic> data) async {
    final dbs = await db();
    return await dbs.update('lomba', data, where: 'id = ?', whereArgs: [id]);
  }

  // Fungsi Simpan Lomba
  static Future<void> insertLomba(Map<String, dynamic> data) async {
    final dbs = await db();
    await dbs.insert(
      'lomba',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Fungsi Ambil Semua Lomba
  static Future<List<Map<String, dynamic>>> getAllLomba() async {
    final dbs = await db();
    return await dbs.query('lomba', orderBy: "id DESC");
  }

  static Future<int> deleteLomba(int id) async {
    final dbs = await db();
    return await dbs.delete('lomba', where: 'id = ?', whereArgs: [id]);
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

  //Fungsi untuk mengambil riwayat lomba berdasarkan User ID
  static Future<void> ikutiLomba(RiwayatModel riwayat) async {
    final db = await DBHelper.db();

    await db.transaction((txn) async {
      await txn.insert('riwayat', riwayat.toMap());

      await txn.rawUpdate('UPDATE lomba SET kuota = kuota - 1 WHERE id = ?', [
        riwayat.idLomba,
      ]);

      List<Map<String, dynamic>> res = await txn.query(
        'lomba',
        where: 'id = ?',
        whereArgs: [riwayat.idLomba],
      );

      if (res.isNotEmpty) {
        int kuotaSekarang = res.first['kuota'];

        if (kuotaSekarang == 0) {
          List<Map<String, dynamic>> cek = await txn.query(
            'riwayatEvent',
            where: 'idLombaAsli = ?',
            whereArgs: [riwayat.idLomba],
          );

          // Hanya masukkan jika belum ada
          if (cek.isEmpty) {
            Map<String, dynamic> lombaSelesai = Map.from(res.first);
            int idAsli = lombaSelesai['id'];
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
      }
    });
  }

  static Future<bool> isUserSedangIkutLomba(int userId, int lombaId) async {
    final dbs = await db();

    // Cek apakah user sudah ada di tabel riwayat untuk lomba ini
    final List<Map<String, dynamic>> result = await dbs.query(
      'riwayat',
      where: 'idUser = ? AND idLomba = ?',
      whereArgs: [userId, lombaId],
    );

    // Jika tidak kosong, berarti user sedang mengikuti event ini
    return result.isNotEmpty;
  }

  static Future<List<Map<String, dynamic>>> getRiwayatEvent() async {
    final db = await DBHelper.db();
    // Tambahkan 'id' ke dalam SELECT agar UI bisa menghapusnya
    return await db.rawQuery(
      'SELECT DISTINCT id, judul, lokasi, tanggal, gambarPath, deskripsi FROM riwayatEvent ORDER BY id DESC',
    );
  }

  static Future<List<Map<String, dynamic>>> getRiwayatUser(int userId) async {
    final db = await DBHelper.db();
    return await db.rawQuery(
      '''
    SELECT 
      COALESCE(lomba.judul, re.judul) as judul, 
      COALESCE(lomba.lokasi, re.lokasi) as lokasi, 
      COALESCE(lomba.tanggal, re.tanggal) as tanggal, 
      COALESCE(lomba.gambarPath, re.gambarPath) as gambarPath, 
      riwayat.idLomba
    FROM riwayat
    LEFT JOIN lomba ON riwayat.idLomba = lomba.id
    LEFT JOIN riwayatEvent re ON riwayat.idLomba = re.idLombaAsli
    WHERE riwayat.idUser = ?
    ''',
      [userId],
    );
  }

  static Future<void> konfirmasiSelesaiManual(int userId, int lombaId) async {
    final dbs = await db();

    await dbs.transaction((txn) async {
      await txn.delete(
        'riwayat',
        where: 'idUser = ? AND idLomba = ?',
        whereArgs: [userId, lombaId],
      );
    });
  }

  static Future<int> deleteRiwayatEvent(int id) async {
    final dbs = await db();
    return await dbs.delete('riwayatEvent', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteAllRiwayatEvent() async {
    final dbs = await db();
    return await dbs.delete('riwayatEvent');
  }

  // static Future<List<Map<String, dynamic>>> getSemuaPendaftarGlobal() async {
  //   final dbs = await db();
  //   return await dbs.rawQuery('''
  //     SELECT lomba.judul AS judul_lomba, user.nama AS nama_user, user.tlpon AS telepon_user, riwayat.tanggalDaftar
  //     FROM riwayat
  //     INNER JOIN user ON riwayat.idUser = user.id
  //     INNER JOIN lomba ON riwayat.idLomba = lomba.id
  //     ORDER BY lomba.id DESC
  //   ''');
  // }
}
