import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:match_discovery/models/lomba_model.dart';
import 'package:match_discovery/database/controllers/riwayat.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/models/riwayat_model.dart';
import 'package:match_discovery/util/app_theme.dart';

class DetailLomba extends StatelessWidget {
  final LombaModel lomba;

  const DetailLomba({super.key, required this.lomba});

  String _formatTanggal(String tanggal) {
    try {
      DateTime dateTime = DateTime.parse(tanggal);
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dateTime);
    } catch (e) {
      return tanggal;
    }
  }

  Future<void> _daftarLomba(BuildContext context) async {
    final userId = await PreferenceHandler.getUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan login terlebih dahulu untuk mendaftar.")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final riwayat = RiwayatModel(
      idUser: userId,
      idLomba: lomba.id!,
      tanggalDaftar: DateTime.now().toIso8601String(),
    );

    final result = await RiwayatController.ikutiLomba(riwayat);
    
    if (context.mounted) Navigator.pop(context); 

    if (result['success']) {
      if (context.mounted) {
        _showSuccessDialog(context, result['token'], result['data']['judul']);
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog(BuildContext context, String token, String judul) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            const Icon(Icons.check_circle_rounded, color: kSuccessColor, size: 80),
            const SizedBox(height: 16),
            Text("Berhasil Daftar!", style: kTitleStyle.copyWith(fontSize: 22)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Anda telah terdaftar di\n$judul", textAlign: TextAlign.center, style: kBodyStyle),
            const SizedBox(height: 24),
            Text("TOKEN PENDAFTARAN", style: kSubtitleStyle.copyWith(letterSpacing: 2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
              ),
              child: Text(token, style: kDisplayStyle.copyWith(fontSize: 28, letterSpacing: 4, color: kPrimaryColor)),
            ),
          ],
        ),
        actions: [
          Center(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: kPrimaryButtonStyle(radius: 16),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text("Tutup"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: kPrimaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'lomba_img_${lomba.id}',
                child: _buildHeaderImage(),
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: kBgColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: kSecondaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              lomba.jenis.toUpperCase(),
                              style: kAccentTextStyle.copyWith(fontSize: 10, letterSpacing: 1),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.group_rounded, size: 16, color: kPrimaryColor),
                                const SizedBox(width: 6),
                                Text("${lomba.kuota} Peserta", style: kSubtitleStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeInUp(
                      delay: const Duration(milliseconds: 100),
                      child: Text(
                        lomba.judul,
                        style: kDisplayStyle.copyWith(fontSize: 26),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: _infoItem(Icons.calendar_today_rounded, "Tanggal Pelaksanaan", _formatTanggal(lomba.tanggal)),
                    ),
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: _infoItem(Icons.location_on_rounded, "Lokasi Kompetisi", lomba.lokasi),
                    ),
                    
                    const SizedBox(height: 32),
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.description_rounded, color: kPrimaryColor, size: 20),
                              const SizedBox(width: 10),
                              Text("Deskripsi Kompetisi", style: kTitleStyle.copyWith(fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: kCardDecoration(radius: 20),
                            child: Text(
                              lomba.deskripsi,
                              style: kBodyStyle.copyWith(height: 1.6, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: FadeInUp(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: kPrimaryButtonStyle(radius: 18),
              onPressed: () => _daftarLomba(context),
              child: const Text(
                "Daftar Sekarang",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderImage() {
    return Stack(
      children: [
        Positioned.fill(
          child: _getImageWidget(),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getImageWidget() {
    if (lomba.gambarPath == null || lomba.gambarPath!.isEmpty) {
      return Container(
        color: kPrimaryColor,
        child: const Icon(Icons.image_rounded, size: 100, color: Colors.white24),
      );
    }
    
    if (lomba.gambarPath!.startsWith('data:image')) {
      return Image.memory(
        base64Decode(lomba.gambarPath!.split(',').last),
        fit: BoxFit.cover,
      );
    } else if (lomba.gambarPath!.startsWith('http')) {
      return Image.network(
        lomba.gambarPath!,
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File(lomba.gambarPath!),
        fit: BoxFit.cover,
      );
    }
  }

  Widget _infoItem(IconData icon, String title, String val) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: kCardDecoration(radius: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: kPrimaryColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: kSubtitleStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(val, style: kBodyStyle.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
