import 'package:flutter/material.dart';
import 'package:match_discovery/database/sql_lite.dart';
import 'package:collection/collection.dart';
import 'package:match_discovery/database/sqllite.dart'; // Tambahkan ini di pubspec.yaml atau gunakan cara manual

class DataUserLomba extends StatefulWidget {
  const DataUserLomba({super.key});

  @override
  State<DataUserLomba> createState() => _DataUserLombaState();
}

class _DataUserLombaState extends State<DataUserLomba> {
  // Kita ubah struktur datanya menjadi Map agar terkelompok
  Map<String, List<Map<String, dynamic>>> _groupedData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() async {
    setState(() => _isLoading = true);
    final data = await DBHelper1.getSemuaPendaftarGlobal();

    // Logika pengelompokan berdasarkan 'judul_lomba'
    final grouped = groupBy(data, (Map obj) => obj['judul_lomba'] as String);

    setState(() {
      _groupedData = grouped;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // Solusi: Pakai SingleChildScrollView untuk membungkus satu Column besar
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Daftar Event',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _groupedData.isEmpty
                  ? const Center(child: Text('Belum ada data pendaftaran.'))
                  : Column(
                      // Pakai Column biasa di sini, BUKAN ListView/Expanded
                      children: _groupedData.entries.map((entry) {
                        String judulLomba = entry.key;
                        List pendaftar = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.blueAccent.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Biru
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(15),
                                    topRight: Radius.circular(15),
                                  ),
                                ),
                                child: Text(
                                  ('Daftar peserta lomba: ${judulLomba.toUpperCase()}'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              // Daftar Pendaftar (menggunakan Column, bukan ListView lagi)
                              Column(
                                children: pendaftar.map((user) {
                                  return ListTile(
                                    leading: const CircleAvatar(
                                      radius: 15,
                                      backgroundColor: Colors.blueAccent,
                                      child: Icon(
                                        Icons.person,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      user['nama_user'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "Telp: ${user['telepon_user']}",
                                    ),
                                    trailing: Text(
                                      (user['tanggalDaftar'] as String).split(
                                        ' ',
                                      )[0],
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
