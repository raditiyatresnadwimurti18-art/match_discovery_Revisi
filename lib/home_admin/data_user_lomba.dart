import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:match_discovery/database/controllers/laporan.dart';
import 'package:match_discovery/util/app_theme.dart';
import 'package:collection/collection.dart';

class DataUserLomba extends StatefulWidget {
  const DataUserLomba({super.key});

  @override
  State<DataUserLomba> createState() => _DataUserLombaState();
}

class _DataUserLombaState extends State<DataUserLomba> {
  Map<String, List<Map<String, dynamic>>> _groupedData = {};
  bool _isLoading = true;
  Map<String, bool> _expandedMap = {};

  String _formatTanggal(String tanggal) {
    try {
      DateTime dateTime = DateTime.parse(tanggal);
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dateTime);
    } catch (e) {
      return tanggal;
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final data = await LaporanController.getSemuaPendaftarGlobal();
    final grouped = groupBy(
      data,
      (Map obj) => (obj['judul_lomba'] as String?) ?? 'Tidak Diketahui',
    );
    final expanded = {for (var key in grouped.keys) key: false};
    if (!mounted) return;
    setState(() {
      _groupedData = grouped;
      _expandedMap = expanded;
      _isLoading = false;
    });
  }

  /// ✅ Deduplikasi berdasarkan idUser agar user yang sama tidak muncul berkali-kali di lomba yang sama,
  /// namun tetap menampilkan seluruh anggota kelompok yang berbeda.
  List<Map<String, dynamic>> _deduplikasi(
    List<Map<String, dynamic>> pendaftar,
  ) {
    final Map<String, Map<String, dynamic>> unique = {};

    for (final user in pendaftar) {
      final idUser = (user['idUser'] as String?) ?? (user['nama_user'] as String?) ?? '-';

      if (!unique.containsKey(idUser)) {
        unique[idUser] = Map<String, dynamic>.from(user);
      }
    }

    return unique.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              decoration: kHeaderDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.groups, color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      Text('Daftar Peserta Event', style: kWhiteBoldStyle),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: kBadgeDecoration(),
                    child: Text(
                      '${_groupedData.length} Lomba Aktif',
                      style: kWhiteSubStyle,
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: kPrimaryColor),
                    )
                  : _groupedData.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                              Icons.inbox_outlined,
                              size: 56,
                              color: kPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum ada data pendaftaran',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: kPrimaryColor,
                      onRefresh: _refreshData,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                        itemCount: _groupedData.length,
                        itemBuilder: (context, index) {
                          final entry = _groupedData.entries.elementAt(index);
                          return _buildLombaCard(
                            judulLomba: entry.key,
                            pendaftar: entry.value,
                            isExpanded: _expandedMap[entry.key] ?? false,
                            nomor: index + 1,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLombaCard({
    required String judulLomba,
    required List<Map<String, dynamic>> pendaftar,
    required bool isExpanded,
    required int nomor,
  }) {
    // ✅ Gunakan list yang sudah dideduplikasi berdasarkan idUser
    final uniquePendaftar = _deduplikasi(pendaftar);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: kCardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kBorderRadius),
        child: Column(
          children: [
            // Header Card
            InkWell(
              onTap: () =>
                  setState(() => _expandedMap[judulLomba] = !isExpanded),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(gradient: kPrimaryGradient),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        '$nomor',
                        style: kWhiteBoldStyle.copyWith(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            judulLomba.toUpperCase(),
                            style: kWhiteBoldStyle.copyWith(
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge jumlah peserta unik
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: kBadgeDecoration(),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 11,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            // ✅ Tampilkan jumlah peserta unik
                            '${uniquePendaftar.length}',
                            style: kWhiteBoldStyle.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Daftar Peserta (sudah unik)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  ...uniquePendaftar.asMap().entries.map((e) {
                    final int i = e.key;
                    final user = e.value;
                    final namaUser = (user['nama_user'] as String?) ?? '-';
                    final telepon = (user['telepon_user'] as String?) ?? '-';
                    final isLast = i == uniquePendaftar.length - 1;
                    final jenis = user['jenis'] ?? 'Individual';
                    final statusTim = user['status_tim'] ?? 'Terdaftar';

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: kPrimaryColor.withOpacity(0.08),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: kPrimaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  namaUser,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Badge Jenis
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (jenis == 'Kelompok' ? Colors.amber : Colors.blue).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  jenis.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: jenis == 'Kelompok' ? Colors.amber.shade900 : Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone_outlined,
                                    size: 12,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      telepon,
                                      style: kSubtitleStyle,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (jenis == 'Kelompok')
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    "Status: $statusTim",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                      color: statusTim == 'Terdaftar' ? Colors.green : Colors.orange.shade800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                          trailing: SizedBox(
                            width: 80,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  statusTim == 'Terdaftar' ? 'Terdaftar' : 'Pending',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: statusTim == 'Terdaftar' ? Colors.grey : Colors.orange,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _formatTanggal(user['tanggalDaftar'] ?? ''),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: kPrimaryColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isLast)
                          const Divider(
                            height: 1,
                            indent: 60,
                            endIndent: 16,
                            color: Color(0xFFEEF2FA),
                          ),
                      ],
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }
}
