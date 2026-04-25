import 'package:flutter/material.dart';
import 'package:match_discovery/util/app_theme.dart';
import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrackRecordUser extends StatefulWidget {
  const TrackRecordUser({super.key});

  @override
  State<TrackRecordUser> createState() => _TrackRecordUserState();
}

class _TrackRecordUserState extends State<TrackRecordUser> {
  // ✅ Data semua user yang sudah menyelesaikan lomba
  // Struktur: { namaUser: [ {judulLomba, tanggalSelesai, ...} ] }
  Map<String, List<Map<String, dynamic>>> _groupedData = {};
  int _totalSelesai = 0;
  bool _isLoading = true;
  Map<String, bool> _expandedMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Firestore doesn't support Joins, so we fetch riwayatSelesai then join with users
      final riwayatSelesaiSnap = await firestore.collection('riwayatSelesai')
          .orderBy('tanggalSelesai', descending: true)
          .get();

      List<Map<String, dynamic>> result = [];
      
      for (var doc in riwayatSelesaiSnap.docs) {
        Map<String, dynamic> rsData = doc.data();
        String userId = rsData['idUser'];

        DocumentSnapshot userSnap = await firestore.collection('users').doc(userId).get();
        if (userSnap.exists) {
          result.add({
            'nama_user': userSnap.get('nama'),
            'telepon_user': userSnap.get('tlpon'),
            'judulLomba': rsData['judulLomba'],
            'tanggalSelesai': rsData['tanggalSelesai'],
            'jenisLomba': rsData['jenisLomba'] ?? 'Individual',
            'idUser': userId,
          });
        }
      }

      // Group by nama user
      final grouped = groupBy(
        result,
        (Map obj) => (obj['nama_user'] as String?) ?? 'Tidak Diketahui',
      );

      final expanded = {for (var key in grouped.keys) key: false};

      if (!mounted) return;
      setState(() {
        _groupedData = grouped;
        _expandedMap = expanded;
        _totalSelesai = result.length;
        _isLoading = false;
      });
    } catch (e) {
      print("Error _loadData: $e");
      if (mounted) setState(() => _isLoading = false);
    }
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
                      const Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text('Track Record Peserta', style: kWhiteBoldStyle),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: kBadgeDecoration(),
                        child: Text(
                          '${_groupedData.length} Peserta',
                          style: kWhiteSubStyle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: kBadgeDecoration(),
                        child: Text(
                          '$_totalSelesai Total Selesai',
                          style: kWhiteSubStyle,
                        ),
                      ),
                    ],
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
                              Icons.workspace_premium_outlined,
                              size: 56,
                              color: kPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum ada peserta yang menyelesaikan lomba',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: kPrimaryColor,
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                        itemCount: _groupedData.length,
                        itemBuilder: (context, index) {
                          final entry = _groupedData.entries.elementAt(index);
                          return _buildUserCard(
                            namaUser: entry.key,
                            records: entry.value,
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

  Widget _buildUserCard({
    required String namaUser,
    required List<Map<String, dynamic>> records,
    required bool isExpanded,
    required int nomor,
  }) {
    final jumlah = records.length;

    // Warna badge berdasarkan jumlah penyelesaian
    final Color badgeColor = jumlah >= 3
        ? kAccentColor
        : jumlah == 2
        ? Colors.orange.shade600
        : kPrimaryColor;
    final Color badgeBg = jumlah >= 3
        ? kAccentColor.withOpacity(0.12)
        : jumlah == 2
        ? Colors.orange.withOpacity(0.1)
        : kPrimaryColor.withOpacity(0.08);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: kCardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kBorderRadius),
        child: Column(
          children: [
            // ── Header Card ──────────────────────────────────────
            InkWell(
              onTap: () => setState(() => _expandedMap[namaUser] = !isExpanded),
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
                            namaUser,
                            style: kWhiteBoldStyle.copyWith(fontSize: 14),
                          ),
                          Text(
                            (records.first['telepon_user'] as String?) ?? '-',
                            style: kWhiteSubStyle.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    // Badge jumlah selesai
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: kBadgeDecoration(),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 11,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$jumlah Selesai',
                            style: kWhiteBoldStyle.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge veteran
                    if (jumlah >= 3) ...[
                      const Icon(
                        Icons.emoji_events,
                        size: 16,
                        color: kAccentColor,
                      ),
                      const SizedBox(width: 4),
                    ],
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

            // ── Daftar Lomba yang Diselesaikan ───────────────────
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  ...records.asMap().entries.map((e) {
                    final int i = e.key;
                    final rec = e.value;
                    final judul = (rec['judulLomba'] as String?) ?? '-';
                    final tanggal = (rec['tanggalSelesai'] as String?) ?? '-';
                    final isLast = i == records.length - 1;

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: badgeBg,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: badgeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            judul,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tanggal,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: badgeColor,
                              ),
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
