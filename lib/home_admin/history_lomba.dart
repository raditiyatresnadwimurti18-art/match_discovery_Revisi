import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/riwayat.dart';
import 'package:match_discovery/util/app_theme.dart';

class HistoryLomba extends StatefulWidget {
  const HistoryLomba({super.key});

  @override
  State<HistoryLomba> createState() => _HistoryLombaState();
}

class _HistoryLombaState extends State<HistoryLomba> {
  // ✅ FIX: Ganti FutureBuilder → List langsung agar refresh selalu akurat
  List<Map<String, dynamic>> _historyList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final data = await RiwayatController.getRiwayatEvent();

    if (!mounted) return;
    setState(() {
      _historyList = data;
      _isLoading = false;
    });
  }

  void _showDeleteDialog(String id) {
    final outerContext = context;
    showDialog(
      context: outerContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                "Hapus Riwayat?",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text("Riwayat event ini akan dihapus secara permanen."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: kDangerButtonStyle(),
            onPressed: () async {
              await RiwayatController.deleteRiwayatEvent(id);

              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);

              // ✅ Reload data — item yang dihapus langsung hilang
              await _loadData();

              if (!mounted) return;
              ScaffoldMessenger.of(outerContext).showSnackBar(
                const SnackBar(
                  content: Text("Riwayat berhasil dihapus"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: kPrimaryAppBar(
        title: 'Event Telah Berakhir',
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          // ── Loading ───────────────────────────────────────────
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          // ── Empty State ───────────────────────────────────────
          : _historyList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.event_busy_outlined,
                      size: 56,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada event yang berakhir',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          // ── List ──────────────────────────────────────────────
          : RefreshIndicator(
              color: kPrimaryColor,
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                itemCount: _historyList.length,
                itemBuilder: (context, index) =>
                    _buildHistoryCard(_historyList[index]),
              ),
            ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: kCardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kBorderRadius),
        child: Opacity(
          opacity: 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  event['gambarPath'] != null
                      ? (event['gambarPath']!.toString().startsWith('data:image')
                          ? Image.memory(
                              base64Decode(event['gambarPath']!.toString().split(',').last),
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(event['gambarPath']),
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ))
                      : Container(
                          height: 160,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'SELESAI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event['judul'] ?? '-', style: kTitleStyle),
                    const SizedBox(height: 8),
                    _infoRow(Icons.location_on_outlined, event['lokasi']),
                    const SizedBox(height: 4),
                    _infoRow(Icons.calendar_today_outlined, event['tanggal']),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFEEF2FA)),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _showDeleteDialog(event['id']),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text(
                          'Hapus Riwayat',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String? value) => Row(
    children: [
      Icon(icon, size: 14, color: Colors.grey),
      const SizedBox(width: 4),
      Expanded(child: Text(value ?? '-', style: kSubtitleStyle)),
    ],
  );
}
