import 'package:flutter/material.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/database/sql_lite.dart';

class HistoryUser extends StatefulWidget {
  const HistoryUser({super.key});

  @override
  State<HistoryUser> createState() => _HistoryUserState();
}

class _HistoryUserState extends State<HistoryUser> {
  Future<List<Map<String, dynamic>>>? _historyFuture;

  @override
  void initState() {
    super.initState();
    _initHistory();
  }

  void _initHistory() async {
    int? id = await PreferenceHandler.getId();
    if (id != null) {
      setState(() {
        // Panggil fungsi getRiwayat yang sudah diperbaiki di DBHelper
        _historyFuture = DBHelper.getRiwayatUser(id);
      });
    }
  }

  void _showConfirmationDialog(int lombaId) async {
    int? userId = await PreferenceHandler.getId();
    if (userId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Selesai"),
        content: const Text(
          "Apakah kamu sudah selesai mengikuti event ini? Data akan dipindahkan ke riwayat akhir.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              await DBHelper.konfirmasiSelesaiManual(userId, lombaId);
              Navigator.pop(context); // Tutup dialog
              _initHistory(); // Refresh list riwayat

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Event berhasil dikonfirmasi selesai!"),
                ),
              );
            },
            child: const Text(
              "Ya, Selesai",
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Saya"),
      ), // Tambahkan AppBar agar rapi
      body: _historyFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                // ... logic snapshot sama seperti kode Anda ...
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Terjadi kesalahan: ${snapshot.error}"),
                  );
                }

                // 2. Cek jika data masih loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 3. Cek jika data kosong
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("Belum ada riwayat pendaftaran."),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final item = snapshot.data![index];
                    final int lombaId = item['idLomba'];
                    return Card(
                      // Gunakan Card agar tampilannya lebih menarik
                      child: ListTile(
                        leading: const Icon(
                          Icons.event_available,
                          color: Colors.blue,
                        ),
                        title: Text(
                          item['judul'] ?? 'No Title',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "${item['lokasi']} • ${item['tanggal']}",
                        ),
                        isThreeLine: true,
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _showConfirmationDialog(lombaId),
                          child: const Text("Selesai"),
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
