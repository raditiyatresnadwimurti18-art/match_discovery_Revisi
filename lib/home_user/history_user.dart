import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/riwayat.dart';
import 'package:match_discovery/database/preferences.dart';

class HistoryUser extends StatefulWidget {
  const HistoryUser({super.key});

  @override
  State<HistoryUser> createState() => _HistoryUserState();
}

class _HistoryUserState extends State<HistoryUser> {
  List<Map<String, dynamic>> _historyList = [];
  bool _isLoading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// FIX: Gunakan setState + list biasa (bukan FutureBuilder) agar
  /// refresh setelah tombol Selesai langsung terasa tanpa rebuild tree.
  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    _userId = await PreferenceHandler.getId();
    if (_userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    // getRiwayatUser sudah difilter: hanya status = 'aktif'
    final data = await RiwayatController.getRiwayatUser(_userId!);

    setState(() {
      _historyList = data;
      _isLoading = false;
    });
  }

  void _showConfirmationDialog(int lombaId, String judulLomba) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 8),
            Text("Konfirmasi Selesai"),
          ],
        ),
        content: Text('Apakah kamu sudah selesai mengikuti\n"$judulLomba"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              // Update status → 'selesai' di database
              await RiwayatController.konfirmasiSelesaiManual(
                _userId!,
                lombaId,
              );

              // FIX: Refresh list — item dengan status 'selesai'
              // tidak akan muncul karena query sudah filter status = 'aktif'
              await _loadHistory();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Event berhasil dikonfirmasi selesai!"),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            child: const Text("Ya, Selesai"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyList.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
                itemCount: _historyList.length,
                itemBuilder: (context, index) {
                  final item = _historyList[index];
                  return _buildCard(item);
                },
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_toggle_off, size: 70, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Belum ada riwayat pendaftaran.',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
          SizedBox(height: 4),
          Text(
            'Daftar lomba dulu yuk!',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final String judul = (item['judul'] as String?) ?? 'Tanpa Judul';
    final String lokasi = (item['lokasi'] as String?) ?? '-';
    final String tanggal = (item['tanggal'] as String?) ?? '-';
    final int lombaId = item['idLomba'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Ikon kiri
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.event_available,
                color: Colors.blueAccent,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),

            // Info lomba
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          lokasi,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        tanggal,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Tombol selesai
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _showConfirmationDialog(lombaId, judul),
              child: const Text("Selesai", style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
