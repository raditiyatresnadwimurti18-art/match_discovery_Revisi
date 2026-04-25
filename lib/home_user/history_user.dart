import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/riwayat.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/util/app_theme.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryUser extends StatefulWidget {
  const HistoryUser({super.key});

  @override
  State<HistoryUser> createState() => _HistoryUserState();
}

class _HistoryUserState extends State<HistoryUser> {
  String? _myId;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _initId();
  }

  Future<void> _initId() async {
    _myId = await PreferenceHandler.getUserId();
    if (mounted) setState(() => _initializing = false);
  }

  void _showRiwayatDetail(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.qr_code_2_rounded, size: 40, color: kPrimaryColor),
            ),
            const SizedBox(height: 16),
            Text(item['judul'] ?? 'Detail Pendaftaran', style: kTitleStyle, textAlign: TextAlign.center),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Tunjukkan kode ini kepada panitia", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: kBgColor, borderRadius: BorderRadius.circular(16)),
              child: Text(
                item['idRiwayat']?.toString().toUpperCase() ?? 'TKN-UNKNOWN',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2, color: kPrimaryColor),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: kPrimaryButtonStyle(radius: 12),
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup"),
            ),
          ),
        ],
      ),
    );
  }

  void _handleKonfirmasiSelesai(Map<String, dynamic> item) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Selesai'),
        content: Text('Apakah Anda sudah benar-benar menyelesaikan lomba "${item['judul']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            style: kPrimaryButtonStyle(radius: 12),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sudah Selesai'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (item['idKelompok'] != null) {
          await RiwayatController.konfirmasiSelesaiKelompok(item['idKelompok'], item['idLomba']);
        } else {
          await RiwayatController.konfirmasiSelesaiManual(_myId!, item['idLomba']);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lomba berhasil diselesaikan!"), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
    if (_myId == null) return const Center(child: Text("Silakan login"));

    return Scaffold(
      backgroundColor: kBgColor,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: RiwayatController.getRiwayatUserStream(_myId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 3));
          }
          
          final activeLomba = snapshot.data ?? [];
          
          if (activeLomba.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            physics: const BouncingScrollPhysics(),
            itemCount: activeLomba.length,
            itemBuilder: (context, index) {
              final item = activeLomba[index];
              return FadeInUp(
                delay: Duration(milliseconds: 30 * index),
                child: _buildLombaCard(item),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLombaCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Colors.orange, size: 28),
            ),
            title: Text(item['judul'] ?? 'Lomba', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(item['lokasi'] ?? '-', style: const TextStyle(fontSize: 12, color: Colors.grey))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(item['tanggal'] ?? '-', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (item['idKelompok'] != null ? Colors.blue : Colors.green).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item['idKelompok'] != null ? 'Kelompok' : 'Individual',
                    style: TextStyle(
                      color: item['idKelompok'] != null ? Colors.blue.shade800 : Colors.green.shade800,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                if (item['idKelompok'] == null || item['isLeader'] == true)
                  ElevatedButton(
                    onPressed: () => _handleKonfirmasiSelesai(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('KONFIRMASI', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showRiwayatDetail(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('LIHAT KODE', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            'Belum ada aktivitas lomba',
            style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
