import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/riwayat.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/util/app_theme.dart';

class TrackRecordUser extends StatefulWidget {
  const TrackRecordUser({super.key});

  @override
  State<TrackRecordUser> createState() => _TrackRecordUserState();
}

class _TrackRecordUserState extends State<TrackRecordUser> {
  List<Map<String, dynamic>> _records = [];
  Map<String, List<String>> _groupedRecords = {};
  int _totalSelesai = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final userId = await PreferenceHandler.getId();
    if (userId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    final records = await RiwayatController.getTrackRecordPerLomba(userId);
    final total   = await RiwayatController.getTotalSelesaiUser(userId);

    final Map<String, List<String>> grouped = {};
    for (final item in records) {
      final judul   = (item['judulLomba']    as String?) ?? 'Tidak Diketahui';
      final tanggal = (item['tanggalSelesai'] as String?) ?? '-';
      grouped.putIfAbsent(judul, () => []).add(tanggal);
    }

    if (!mounted) return;
    setState(() {
      _records        = records;
      _groupedRecords = grouped;
      _totalSelesai   = total;
      _isLoading      = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : RefreshIndicator(
              color: kPrimaryColor,
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                children: [
                  // ── Banner Statistik ──────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [kPrimaryColor, Color(0xFF1a4a8a)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                          color: kPrimaryColor.withOpacity(0.3),
                          blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.emoji_events, color: kAccentColor, size: 36),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Event Diselesaikan', style: kWhiteSubStyle),
                            Text('$_totalSelesai Lomba',
                                style: kWhiteBoldStyle.copyWith(fontSize: 28)),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          children: [
                            Text('${_groupedRecords.length}',
                                style: kWhiteBoldStyle.copyWith(fontSize: 22)),
                            const Text('Jenis\nLomba', style: kWhiteSubStyle, textAlign: TextAlign.center),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_groupedRecords.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('Riwayat Per Lomba', style: kTitleStyle),
                    ),

                  // ── Empty State ───────────────────────────────
                  if (_groupedRecords.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle,
                                boxShadow: [BoxShadow(
                                    color: Colors.grey.withOpacity(0.1), blurRadius: 20)],
                              ),
                              child: const Icon(Icons.history_edu_outlined, size: 56, color: kPrimaryColor),
                            ),
                            const SizedBox(height: 16),
                            const Text('Belum ada lomba yang diselesaikan',
                                style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),

                  // ── List Per Lomba ────────────────────────────
                  ..._groupedRecords.entries.toList().asMap().entries.map((entry) {
                    final int index          = entry.key;
                    final String judulLomba  = entry.value.key;
                    final List<String> dates = entry.value.value;
                    return _buildLombaCard(
                      nomor: index + 1,
                      judulLomba: judulLomba,
                      tanggalList: dates,
                      jumlah: dates.length,
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildLombaCard({
    required int nomor,
    required String judulLomba,
    required List<String> tanggalList,
    required int jumlah,
  }) {
    // Warna dinamis berdasarkan jumlah keikutsertaan
    final Color badgeColor = jumlah >= 3 ? kAccentColor
        : jumlah == 2 ? Colors.orange.shade600
        : kPrimaryColor;
    final Color badgeBg = jumlah >= 3 ? kAccentColor.withOpacity(0.12)
        : jumlah == 2 ? Colors.orange.withOpacity(0.1)
        : kPrimaryColor.withOpacity(0.08);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: kCardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kBorderRadius),
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────
            Container(
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
                  Expanded(child: Text(judulLomba, style: kWhiteBoldStyle)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: kBadgeDecoration(),
                    child: Row(
                      children: [
                        const Icon(Icons.repeat, size: 11, color: Colors.white),
                        const SizedBox(width: 3),
                        Text('$jumlah×', style: kWhiteBoldStyle.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── List Tanggal ────────────────────────────────────
            ...tanggalList.asMap().entries.map((e) {
              final int i      = e.key;
              final String tgl = e.value;
              final bool isLast = i == tanggalList.length - 1;

              return Column(
                children: [
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
                      child: Center(child: Icon(Icons.check_circle_outline, size: 18, color: badgeColor)),
                    ),
                    title: Text('Keikutsertaan ke-${i + 1}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                      child: Text(tgl,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: badgeColor)),
                    ),
                  ),
                  if (!isLast)
                    const Divider(height: 1, indent: 60, endIndent: 16, color: Color(0xFFEEF2FA)),
                ],
              );
            }),

            // ── Footer ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                  color: kBgColor, border: Border(top: BorderSide(color: Colors.grey.shade200))),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Terakhir selesai: ${tanggalList.first}', style: kSubtitleStyle.copyWith(fontSize: 11)),
                  const Spacer(),
                  if (jumlah >= 3)
                    Row(
                      children: [
                        const Icon(Icons.emoji_events, size: 14, color: kAccentColor),
                        const SizedBox(width: 2),
                        Text('Veteran', style: kAccentTextStyle.copyWith(fontSize: 11)),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}