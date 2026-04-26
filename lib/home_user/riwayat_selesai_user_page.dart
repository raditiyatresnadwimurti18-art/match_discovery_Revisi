import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:match_discovery/database/controllers/riwayat.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/util/app_theme.dart';
import 'package:animate_do/animate_do.dart';

class RiwayatSelesaiUserPage extends StatefulWidget {
  const RiwayatSelesaiUserPage({super.key});

  @override
  State<RiwayatSelesaiUserPage> createState() => _RiwayatSelesaiUserPageState();
}

class _RiwayatSelesaiUserPageState extends State<RiwayatSelesaiUserPage> {
  String? _myId;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _initId();
  }

  Future<void> _initId() async {
    _myId = PreferenceHandler.getUserId();
    if (mounted) setState(() => _initializing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
    if (_myId == null) return const Center(child: Text("Silakan login"));

    return Scaffold(
      backgroundColor: kBgColor,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: RiwayatController.getTrackRecordPerLombaStream(_myId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 3));
          }
          
          final finishedLomba = snapshot.data ?? [];
          
          if (finishedLomba.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            physics: const BouncingScrollPhysics(),
            itemCount: finishedLomba.length,
            itemBuilder: (context, index) {
              final item = finishedLomba[index];
              return FadeInUp(
                delay: Duration(milliseconds: 30 * index),
                child: _buildFinishedCard(item),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFinishedCard(Map<String, dynamic> item) {
    final bool isKelompok = item['jenisLomba'] == 'Kelompok';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
        ),
        title: Text(
          item['judulLomba'] ?? 'Lomba Selesai',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "Selesai: ${item['tanggalSelesai'] ?? '-'}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isKelompok ? Colors.blue : Colors.orange).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isKelompok ? 'TIM' : 'INDIVIDU',
                style: TextStyle(
                  color: isKelompok ? Colors.blue.shade700 : Colors.orange.shade700,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.verified_rounded, color: kPrimaryColor, size: 20),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            'Belum ada lomba yang diselesaikan',
            style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
