import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/kelompok.dart';
import 'package:match_discovery/database/controllers/riwayat.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/util/app_theme.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    _userId = PreferenceHandler.getUserId();

    if (_userId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

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

  void _showConfirmationDialog(String lombaId, String judulLomba, {String? idKelompok}) {
    final outerContext = context;
    showDialog(
      context: outerContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.stars_rounded, color: idKelompok != null ? Colors.amber : Colors.green, size: 28),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                "Konfirmasi Selesai",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            idKelompok != null 
              ? 'Sebagai Ketua Kelompok, Anda akan mengonfirmasi status "Selesai" untuk seluruh anggota tim di lomba "$judulLomba". Lanjutkan?'
              : 'Apakah Anda sudah selesai mengikuti lomba "$judulLomba"?',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: idKelompok != null ? Colors.amber.shade700 : Colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              try {
                if (idKelompok != null) {
                  await RiwayatController.konfirmasiSelesaiKelompok(idKelompok, lombaId);
                } else {
                  await RiwayatController.konfirmasiSelesaiManual(_userId!, lombaId);
                }
                
                await _loadAllData();

                if (!mounted) return;
                ScaffoldMessenger.of(outerContext).showSnackBar(
                  SnackBar(
                    content: Text(idKelompok != null ? "Berhasil menyelesaikan lomba untuk seluruh tim!" : "Event berhasil dikonfirmasi selesai!"),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(outerContext).showSnackBar(
                  SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("Ya, Selesai", style: TextStyle(fontWeight: FontWeight.bold)),
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
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: TabBar(
              labelColor: kPrimaryColor,
              unselectedLabelColor: Colors.grey,
              indicator: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
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
        padding: const EdgeInsets.all(20),
        itemCount: _activeLomba.length,
        itemBuilder: (context, index) => FadeInUp(
          delay: Duration(milliseconds: index * 100),
          child: _buildActiveCard(_activeLomba[index]),
        ),
      ),
    );
  }

  Widget _buildActiveCard(Map<String, dynamic> item) {
    final judul = (item['judul'] as String?) ?? 'Tanpa Judul';
    final lokasi = (item['lokasi'] as String?) ?? '-';
    final tanggal = (item['tanggal'] as String?) ?? '-';
    final lombaId = item['idLomba'] as String;
    final idKelompok = item['idKelompok'] as String?;
    final isLeader = item['isLeader'] == true;
    final isPendingGroup = item['isPendingGroup'] == true;
    final gambar = item['gambarPath'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: kCardDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImage(gambar),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (idKelompok != null ? Colors.amber : Colors.blue).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          idKelompok != null ? (isPendingGroup ? "TEAM (SEARCHING)" : "TEAM MATCH") : "INDIVIDUAL",
                          style: TextStyle(
                            fontSize: 9, 
                            fontWeight: FontWeight.bold, 
                            color: idKelompok != null ? Colors.amber.shade900 : Colors.blue.shade900
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        judul,
                        style: kTitleStyle.copyWith(fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      _infoRow(Icons.location_on_rounded, lokasi),
                      const SizedBox(height: 4),
                      _infoRow(Icons.calendar_month_rounded, tanggal),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (idKelompok != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isLeader ? Colors.amber.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(kCardRadius), bottomRight: Radius.circular(kCardRadius)),
              ),
              child: Row(
                children: [
                  Icon(
                    isLeader ? Icons.stars_rounded : (isPendingGroup ? Icons.hourglass_top_rounded : Icons.info_outline_rounded), 
                    size: 16, 
                    color: isLeader ? Colors.amber.shade700 : (isPendingGroup ? Colors.orange : Colors.grey)
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isPendingGroup 
                        ? "Kelompok belum penuh. Menunggu anggota lain..."
                        : (isLeader ? "Anda adalah Ketua Kelompok" : "Menunggu Ketua mengonfirmasi selesai"),
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.w500,
                        color: isLeader ? Colors.amber.shade900 : (isPendingGroup ? Colors.orange.shade900 : Colors.grey.shade700)
                      ),
                    ),
                  ),
                  if (isLeader && !isPendingGroup)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showConfirmationDialog(lombaId, judul, idKelompok: idKelompok),
                      child: const Text("Selesai (Team)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  onPressed: () => _showConfirmationDialog(lombaId, judul),
                  label: const Text("Konfirmasi Selesai", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrackRecordList() {
    if (_finishedLomba.isEmpty) return _buildEmpty("Belum ada track record.");
    return RefreshIndicator(
      color: kPrimaryColor,
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _finishedLomba.length,
        itemBuilder: (context, index) => FadeInLeft(
          delay: Duration(milliseconds: index * 100),
          child: _buildTrackRecordCard(_finishedLomba[index]),
        ),
      ),
    );
  }

  Widget _buildTrackRecordCard(Map<String, dynamic> item) {
    final judul = (item['judulLomba'] as String?) ?? 'Tanpa Judul';
    final tglSelesai = (item['tanggalSelesai'] as String?) ?? '-';
    final jenisLomba = (item['jenisLomba'] as String?) ?? 'Individual';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: kCardDecoration(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (jenisLomba == 'Kelompok' ? Colors.amber : Colors.green).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            jenisLomba == 'Kelompok' ? Icons.groups_rounded : Icons.verified_rounded, 
            color: jenisLomba == 'Kelompok' ? Colors.amber.shade700 : Colors.green,
            size: 20,
          ),
        ),
        title: Text(
          judul,
          style: kTitleStyle.copyWith(fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Selesai: $tglSelesai", 
                    style: kSubtitleStyle.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (jenisLomba == 'Kelompok' ? Colors.amber : Colors.green).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            jenisLomba.toUpperCase(),
            style: TextStyle(
              fontSize: 8, 
              fontWeight: FontWeight.bold, 
              color: jenisLomba == 'Kelompok' ? Colors.amber.shade900 : Colors.green.shade900
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String? gambar) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        height: 80,
        color: Colors.grey.shade100,
        child: gambar != null && gambar.isNotEmpty
            ? (gambar.startsWith('data:image')
                ? Image.memory(
                    base64Decode(gambar.split(',').last),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, color: Colors.grey),
                  )
                : (gambar.startsWith('http') 
                    ? Image.network(
                        gambar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, color: Colors.grey),
                      )
                    : Image.file(
                        File(gambar),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, color: Colors.grey),
                      )))
            : const Icon(Icons.image_outlined, color: Colors.grey),
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: kSubtitleStyle),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) => Row(
    children: [
      Icon(icon, size: 14, color: Colors.grey),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          value,
          style: kSubtitleStyle,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
