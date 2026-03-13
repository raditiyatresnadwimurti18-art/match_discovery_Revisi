import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/laporan.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';

class DataUserLomba extends StatefulWidget {
  const DataUserLomba({super.key});

  @override
  State<DataUserLomba> createState() => _DataUserLombaState();
}

class _DataUserLombaState extends State<DataUserLomba> {
  Map<String, List<Map<String, dynamic>>> _groupedData = {};
  bool _isLoading = true;

  // Menyimpan status expand/collapse tiap lomba
  Map<String, bool> _expandedMap = {};

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() async {
    setState(() => _isLoading = true);
    final data = await LaporanController.getSemuaPendaftarGlobal();

    final grouped = groupBy(
      data,
      (Map obj) => (obj['judul_lomba'] as String?) ?? 'Tidak Diketahui',
    );

    // Default semua card tertutup
    final expanded = {for (var key in grouped.keys) key: false};

    setState(() {
      _groupedData = grouped;
      _expandedMap = expanded;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Daftar Peserta Event',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_groupedData.length} Lomba Aktif',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _groupedData.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 60,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Belum ada data pendaftaran.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
                      itemCount: _groupedData.length,
                      itemBuilder: (context, index) {
                        final entry = _groupedData.entries.elementAt(index);
                        final String judulLomba = entry.key;
                        final List<Map<String, dynamic>> pendaftar =
                            entry.value;
                        final bool isExpanded =
                            _expandedMap[judulLomba] ?? false;

                        return _buildLombaCard(
                          judulLomba: judulLomba,
                          pendaftar: pendaftar,
                          isExpanded: isExpanded,
                          nomor: index + 1,
                        );
                      },
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.blueAccent.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header Card ─────────────────────────────────────
          InkWell(
            borderRadius: isExpanded
                ? const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  )
                : BorderRadius.circular(16),
            onTap: () {
              setState(() {
                _expandedMap[judulLomba] = !isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Colors.blueAccent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: isExpanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      )
                    : BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Nomor urut
                  CircleAvatar(
                    radius: 16,
                    // ignore: deprecated_member_use
                    backgroundColor: Colors.white.withOpacity(0.25),
                    child: Text(
                      '$nomor',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Judul lomba
                  Expanded(
                    child: Text(
                      judulLomba.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  // Badge jumlah peserta
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${pendaftar.length} peserta',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Ikon expand/collapse
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

          // ── Daftar Peserta (collapsible) ─────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE3EAF5),
                ),
                ...pendaftar.asMap().entries.map((e) {
                  final int i = e.key;
                  final Map<String, dynamic> user = e.value;

                  final String namaUser = (user['nama_user'] as String?) ?? '-';
                  final String teleponUser =
                      (user['telepon_user'] as String?) ?? '-';
                  final String tanggal =
                      (user['tanggalDaftar'] as String?)?.split(' ').first ??
                      '-';

                  final bool isLast = i == pendaftar.length - 1;

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          radius: 18,
                          // ignore: deprecated_member_use
                          backgroundColor: Colors.blueAccent.withOpacity(0.15),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        title: Text(
                          namaUser,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 12,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              teleponUser,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Terdaftar',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              tanggal,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
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
                  // ignore: unnecessary_to_list_in_spreads
                }).toList(),
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
    );
  }
}
