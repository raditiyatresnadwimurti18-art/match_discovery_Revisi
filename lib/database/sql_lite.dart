import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Future<Database> db() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'Match_Discovery_v15_final_db'),
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
        await db.execute('''
          CREATE TABLE riwayatSelesai (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            idUser    INTEGER,
            judulLomba TEXT,
            tanggalSelesai TEXT
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
}
