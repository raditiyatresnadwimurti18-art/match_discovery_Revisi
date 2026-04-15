import 'dart:io';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/riwayat.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/util/app_theme.dart';

class HistoryUser extends StatefulWidget {
  const HistoryUser({super.key});

  @override
  State<HistoryUser> createState() => _HistoryUserState();
}

class _HistoryUserState extends State<HistoryUser> {
  List<Map<String, dynamic>> _historyList = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // ✅ FIX: Gunakan getUserId() agar tidak terkontaminasi ID admin
    _userId = await PreferenceHandler.getUserId();

    if (_userId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }
    final data = await RiwayatController.getRiwayatUser(_userId!);
    if (!mounted) return;
    setState(() {
      _historyList = data;
      _isLoading = false;
    });
  }

  void _showConfirmationDialog(String lombaId, String judulLomba) {
    final outerContext = context;
    showDialog(
      context: outerContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                "Konfirmasi Selesai",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text('Apakah kamu sudah selesai mengikuti\n"$judulLomba"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);

              // ✅ FIX: Gunakan _userId yang sudah pasti ID user biasa
              await RiwayatController.konfirmasiSelesaiManual(
                _userId!,
                lombaId,
              );
              await _loadHistory();

              if (!mounted) return;
              ScaffoldMessenger.of(outerContext).showSnackBar(
                SnackBar(
                  content: const Text("Event berhasil dikonfirmasi selesai!"),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
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
      backgroundColor: kBgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : _historyList.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              color: kPrimaryColor,
              onRefresh: _loadHistory,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
                itemCount: _historyList.length,
                itemBuilder: (context, index) =>
                    _buildCard(_historyList[index]),
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 20),
              ],
            ),
            child: const Icon(
              Icons.history_toggle_off,
              size: 56,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada riwayat pendaftaran.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text('Daftar lomba dulu yuk!', style: kSubtitleStyle),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final judul = (item['judul'] as String?) ?? 'Tanpa Judul';
    final lokasi = (item['lokasi'] as String?) ?? '-';
    final tanggal = (item['tanggal'] as String?) ?? '-';
    final lombaId = item['idLomba'] as String;
    final gambar = item['gambarPath'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: kCardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kBorderRadius),
        child: Row(
          children: [
            // Gambar kiri
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(kBorderRadius),
                bottomLeft: Radius.circular(kBorderRadius),
              ),
              child: gambar != null && gambar.isNotEmpty
                  ? Image.file(
                      File(gambar),
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderBox(),
                    )
                  : _placeholderBox(),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _infoRow(Icons.location_on_outlined, lokasi),
                    const SizedBox(height: 2),
                    _infoRow(Icons.calendar_today_outlined, tanggal),
                  ],
                ),
              ),
            ),
            // Tombol selesai
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _showConfirmationDialog(lombaId, judul),
                child: const Text("Selesai", style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderBox() => Container(
    width: 90,
    height: 90,
    color: Colors.grey.shade200,
    child: const Icon(Icons.image_outlined, color: Colors.grey),
  );

  Widget _infoRow(IconData icon, String value) => Row(
    children: [
      Icon(icon, size: 12, color: Colors.grey),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          value,
          style: kSubtitleStyle.copyWith(fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
