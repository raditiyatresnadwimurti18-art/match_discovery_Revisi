import 'package:flutter/material.dart';
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
        data, (Map obj) => (obj['judul_lomba'] as String?) ?? 'Tidak Diketahui');
    final expanded = {for (var key in grouped.keys) key: false};
    if (!mounted) return;
    setState(() {
      _groupedData = grouped;
      _expandedMap = expanded;
      _isLoading = false;
    });
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
                  const Row(
                    children: [
                      Icon(Icons.groups, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text('Daftar Peserta Event', style: kWhiteBoldStyle),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: kBadgeDecoration(),
                    child: Text('${_groupedData.length} Lomba Aktif', style: kWhiteSubStyle),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
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
                                    boxShadow: [BoxShadow(
                                        color: Colors.grey.withOpacity(0.1), blurRadius: 20)]),
                                child: const Icon(Icons.inbox_outlined, size: 56, color: kPrimaryColor),
                              ),
                              const SizedBox(height: 16),
                              const Text('Belum ada data pendaftaran',
                                  style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500)),
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
              onTap: () => setState(() => _expandedMap[judulLomba] = !isExpanded),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(gradient: kPrimaryGradient),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text('$nomor', style: kWhiteBoldStyle.copyWith(fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(judulLomba.toUpperCase(),
                          style: kWhiteBoldStyle.copyWith(fontSize: 13, letterSpacing: 0.5)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: kBadgeDecoration(),
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 11, color: Colors.white),
                          const SizedBox(width: 3),
                          Text('${pendaftar.length}',
                              style: kWhiteBoldStyle.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            // Daftar Peserta
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  ...pendaftar.asMap().entries.map((e) {
                    final int i = e.key;
                    final user = e.value;
                    final namaUser   = (user['nama_user']   as String?) ?? '-';
                    final telepon    = (user['telepon_user'] as String?) ?? '-';
                    final tanggal    = (user['tanggalDaftar'] as String?)?.split(' ').first ?? '-';
                    final isLast     = i == pendaftar.length - 1;

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: kPrimaryColor.withOpacity(0.08),
                            child: Text('${i + 1}',
                                style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          title: Text(namaUser,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(telepon, style: kSubtitleStyle),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Terdaftar',
                                  style: TextStyle(fontSize: 10, color: Colors.grey)),
                              Text(tanggal,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kPrimaryColor)),
                            ],
                          ),
                        ),
                        if (!isLast)
                          const Divider(height: 1, indent: 60, endIndent: 16, color: Color(0xFFEEF2FA)),
                      ],
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }
}