import 'dart:io';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/lomba.dart';
import 'package:match_discovery/database/controllers/riwayat.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/models/lomba_model.dart';
import 'package:match_discovery/models/riwayat_model.dart';

class DaftarLomba extends StatefulWidget {
  const DaftarLomba({super.key});

  @override
  State<DaftarLomba> createState() => _DaftarLombaState();
}

class _DaftarLombaState extends State<DaftarLomba> {
  Future<List<LombaModel>> _lombaFuture = LombaController.getAllLomba();

  @override
  void initState() {
    super.initState();
  }

  void _refreshData() {
    setState(() {
      _lombaFuture = LombaController.getAllLomba();
    });
  }

  void _konfirmasiIkutiLomba(int lombaId) async {
    final userId = await PreferenceHandler.getId();
    if (userId == null) return;

    await RiwayatController.ikutiLomba(
      RiwayatModel(
        idUser: userId,
        idLomba: lombaId,
        tanggalDaftar: DateTime.now().toIso8601String().split('T').first,
      ),
    );

    _refreshData();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Berhasil mengikuti lomba!")));
    Navigator.pop(context);
  }

  void _showLombaDetail(BuildContext context, LombaModel lomba) async {
    final userId = await PreferenceHandler.getId();

    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silahkan login terlebih dahulu")),
      );
      return;
    }

    final sedangIkut = await RiwayatController.isUserSedangIkutLomba(
      userId,
      lomba.id!,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(lomba.judul ?? "Detail Lomba"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: lomba.gambarPath != null
                    ? Image.file(File(lomba.gambarPath!))
                    : Container(height: 100, color: Colors.grey),
              ),
              const SizedBox(height: 15),
              _infoRow(Icons.category, "Jenis", lomba.jenis),
              _infoRow(Icons.calendar_today, "Tanggal", lomba.tanggal),
              _infoRow(Icons.location_on, "Lokasi", lomba.lokasi),
              _infoRow(Icons.people, "Kuota", "${lomba.kuota ?? 0}"),
              const Divider(),
              const Text(
                "Deskripsi:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(lomba.deskripsi ?? "Tidak ada deskripsi."),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
          ElevatedButton(
            onPressed: sedangIkut
                ? null
                : () => _konfirmasiIkutiLomba(lomba.id!),
            style: ElevatedButton.styleFrom(
              backgroundColor: sedangIkut ? Colors.grey : Colors.blue,
            ),
            child: Text(sedangIkut ? "Sudah Terdaftar" : "Daftar Sekarang"),
          ),
        ],
      ),
    );
  }

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
    return FutureBuilder<List<LombaModel>>(
      future: _lombaFuture,
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
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: listLomba.length,
          itemBuilder: (context, index) {
            final lomba = listLomba[index];
            return InkWell(
              onTap: () => _showLombaDetail(context, lomba),
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
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child:
                            (lomba.gambarPath != null &&
                                lomba.gambarPath!.isNotEmpty)
                            ? Image.file(
                                File(lomba.gambarPath!),
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
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
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lomba.judul ?? "Tanpa Judul",
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
                                "Kuota: ${lomba.kuota ?? 0}",
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
