import 'dart:io';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/database/sql_lite.dart';
import 'package:match_discovery/models/riwayat_model.dart';

class DaftarLomba extends StatefulWidget {
  const DaftarLomba({super.key});

  @override
  State<DaftarLomba> createState() => _DaftarLombaState();
}

class _DaftarLombaState extends State<DaftarLomba> {
  late Future<List<Map<String, dynamic>>> _lombaFuture;
  @override
  void _refreshData() {
    setState(() {
      _lombaFuture = DBHelper.getAllLomba();
    });
  }

  void _konfirmasiIkutiLomba(int lombaId) async {
    int? userId = await PreferenceHandler.getId();

    if (userId != null) {
      await DBHelper.ikutiLomba(RiwayatModel(idUser: userId, idLomba: lombaId));

      _refreshData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Berhasil mengikuti lomba!")),
      );
      Navigator.pop(context); // Tutup Dialog
    }
  }

  void _showLombaDetail(
    BuildContext context,
    Map<String, dynamic> lomba,
  ) async {
    int? userId = await PreferenceHandler.getId();
    int lombaId = lomba['id'];
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silahkan login terlebih dahulu")),
      );
      return;
    }
    bool sedangIkut = await DBHelper.isUserSedangIkutLomba(userId, lombaId);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(lomba['judul'] ?? "Detail Lomba"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Menyesuaikan tinggi dengan isi
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar di dalam pop-up
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: lomba['gambarPath'] != null
                      ? Image.file(File(lomba['gambarPath']))
                      : Container(height: 100, color: Colors.grey),
                ),
                const SizedBox(height: 15),

                // Informasi Detail
                _infoRow(Icons.category, "Jenis", lomba['jenis']),
                _infoRow(Icons.calendar_today, "Tanggal", lomba['tanggal']),
                _infoRow(Icons.location_on, "Lokasi", lomba['lokasi']),
                _infoRow(Icons.people, "Kuota", "${lomba['kuota']}"),
                const Divider(),
                const Text(
                  "Deskripsi:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(lomba['deskripsi'] ?? "Tidak ada deskripsi."),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup"),
            ),
            // 3. Logika Tombol: Jika sedang ikut, tombol jadi Non-aktif/Berbeda
            ElevatedButton(
              onPressed: sedangIkut
                  ? null
                  : () => _konfirmasiIkutiLomba(lombaId),
              style: ElevatedButton.styleFrom(
                backgroundColor: sedangIkut ? Colors.grey : Colors.blue,
              ),
              child: Text(sedangIkut ? "Sudah Terdaftar" : "Daftar Sekarang"),
            ),
          ],
        );
      },
    );
  }

  // Widget kecil untuk merapikan baris informasi
  Widget _infoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text("$label: ${value ?? '-'}")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      // Memanggil fungsi dari DBHelper
      future: DBHelper.getAllLomba(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Tidak ada data lomba"));
        }

        final listLomba = snapshot.data!;

        return GridView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 kolom
            childAspectRatio: 0.8, // Mengatur rasio tinggi kotak
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: listLomba.length,
          itemBuilder: (context, index) {
            // Di sini kita mendefinisikan variabel 'lomba' dari list
            final lomba = listLomba[index];

            return InkWell(
              onTap: () {
                _showLombaDetail(context, lomba);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Gambar di Atas
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child:
                            (lomba['gambarPath'] != null &&
                                lomba['gambarPath'].isNotEmpty)
                            ? Image.file(
                                File(lomba['gambarPath']),
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image),
                                    ),
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image),
                              ),
                      ),
                    ),

                    // 2. Tulisan di Bawah
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lomba['judul'] ?? "Tanpa Judul",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.people,
                                size: 14,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Kuota: ${lomba['kuota']}",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
