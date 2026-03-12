import 'dart:io';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/sql_lite.dart';

class HistoryLomba extends StatefulWidget {
  const HistoryLomba({super.key});

  @override
  State<HistoryLomba> createState() => _HistoryLombaState();
}

class _HistoryLombaState extends State<HistoryLomba> {
  // 1. Tambahkan variabel untuk menyimpan future
  Future<List<Map<String, dynamic>>>? _historyFuture;

  @override
  void initState() {
    super.initState();
    // 2. Inisialisasi data pertama kali
    _refreshData();
  }

  // 3. Fungsi khusus untuk memuat ulang data
  void _refreshData() {
    setState(() {
      _historyFuture = DBHelper.getRiwayatEvent();
    });
  }

  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Hapus"),
          content: const Text(
            "Apakah kamu yakin ingin menghapus riwayat event ini?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () async {
                await DBHelper.deleteRiwayatEvent(id);
                if (mounted) {
                  Navigator.pop(context);
                  // 4. Panggil refresh data setelah hapus berhasil
                  _refreshData();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Riwayat telah dihapus")),
                  );
                }
              },
              child: const Text("Hapus", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Event Telah Berakhir"),
        centerTitle: true,
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // 5. Gunakan variabel _historyFuture
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  const Text(
                    "Belum ada event yang berakhir",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final listEvent = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listEvent.length,
            itemBuilder: (context, index) {
              final event = listEvent[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Opacity(
                  opacity: 0.7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: event['gambarPath'] != null
                            ? Image.file(
                                File(event['gambarPath']),
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(height: 150, color: Colors.grey[300]),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  // Tambahkan Expanded agar teks panjang tidak error
                                  child: Text(
                                    event['judul'] ?? "",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    "SELESAI",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text("Lokasi: ${event['lokasi']}"),
                            Text("Tanggal: ${event['tanggal']}"),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _showDeleteDialog(event['id']),
                              ),
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
      ),
    );
  }
}
