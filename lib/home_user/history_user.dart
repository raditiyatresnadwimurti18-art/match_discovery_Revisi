import 'dart:io';
import 'dart:convert';
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
  List<Map<String, dynamic>> _activeLomba = [];
  List<Map<String, dynamic>> _finishedLomba = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    _userId = await PreferenceHandler.getUserId();

    if (_userId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    // Load data aktif dan selesai secara paralel
    final results = await Future.wait([
      RiwayatController.getRiwayatUser(_userId!),
      RiwayatController.getTrackRecordPerLomba(_userId!),
    ]);

    if (!mounted) return;
    setState(() {
      _activeLomba = results[0];
      _finishedLomba = results[1];
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

              await RiwayatController.konfirmasiSelesaiManual(
                _userId!,
                lombaId,
              );
              await _loadAllData();

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kBgColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: kPrimaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: kPrimaryColor,
              indicatorWeight: 3,
              tabs: [
                Tab(text: "Lomba Aktif"),
                Tab(text: "Track Record"),
              ],
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : TabBarView(
                children: [
                  _buildActiveList(),
                  _buildTrackRecordList(),
                ],
              ),
      ),
    );
  }

  Widget _buildActiveList() {
    if (_activeLomba.isEmpty) return _buildEmpty("Belum ada lomba aktif.");
    return RefreshIndicator(
      color: kPrimaryColor,
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
        itemCount: _activeLomba.length,
        itemBuilder: (context, index) => _buildActiveCard(_activeLomba[index]),
      ),
    );
  }

  Widget _buildTrackRecordList() {
    if (_finishedLomba.isEmpty) return _buildEmpty("Belum ada track record.");
    return RefreshIndicator(
      color: kPrimaryColor,
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
        itemCount: _finishedLomba.length,
        itemBuilder: (context, index) => _buildTrackRecordCard(_finishedLomba[index]),
      ),
    );
  }

  Widget _buildEmpty(String message) {
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
          Text(
            message,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCard(Map<String, dynamic> item) {
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
            _buildImage(gambar),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _buildTrackRecordCard(Map<String, dynamic> item) {
    final judul = (item['judulLomba'] as String?) ?? 'Tanpa Judul';
    final tglSelesai = (item['tanggalSelesai'] as String?) ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: kCardDecoration(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, color: Colors.green),
        ),
        title: Text(
          judul,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text("Selesai pada: $tglSelesai", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            "Selesai",
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String? gambar) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(kBorderRadius),
        bottomLeft: Radius.circular(kBorderRadius),
      ),
      child: gambar != null && gambar.isNotEmpty
          ? (gambar.startsWith('data:image')
              ? Image.memory(
                  base64Decode(gambar.split(',').last),
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderBox(),
                )
              : (gambar.startsWith('http') 
                  ? Image.network(
                      gambar,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderBox(),
                    )
                  : Image.file(
                      File(gambar),
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderBox(),
                    )))
          : _placeholderBox(),
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
