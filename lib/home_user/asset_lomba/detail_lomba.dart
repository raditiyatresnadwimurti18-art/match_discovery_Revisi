import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

    // Tampilkan loading
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
    
    if (context.mounted) Navigator.pop(context); // Tutup loading

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 10),
            Text("Berhasil Daftar!", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Anda telah terdaftar di $judul", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            const Text("Token Pendaftaran:", style: TextStyle(color: Colors.grey)),
            Text(token, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kPrimaryColor)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: kPrimaryButtonStyle(radius: 12),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Kembali ke home
              },
              child: const Text("Tutup"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Header dengan Gambar Penuh
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeaderImage(),
            ),
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.arrow_back, color: Colors.black),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          lomba.jenis,
                          style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.people, size: 18, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("Kuota: ${lomba.kuota}", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    lomba.judul,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  _infoItem(Icons.calendar_today, "Tanggal", _formatTanggal(lomba.tanggal)),
                  _infoItem(Icons.location_on, "Lokasi", lomba.lokasi),
                  
                  const Divider(height: 40),
                  const Text(
                    "Deskripsi Lomba",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lomba.deskripsi,
                    style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
                  ),
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: ElevatedButton(
          style: kPrimaryButtonStyle(radius: 15),
          onPressed: () => _daftarLomba(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Text("Daftar Sekarang", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderImage() {
    return Container(
      color: Colors.black87, // Latar belakang gelap agar gambar kontras
      child: Center(
        child: _getImageWidget(),
      ),
    );
  }

  Widget _getImageWidget() {
    if (lomba.gambarPath == null || lomba.gambarPath!.isEmpty) {
      return const Icon(Icons.image, size: 100, color: Colors.grey);
    }
    
    if (lomba.gambarPath!.startsWith('data:image')) {
      return Image.memory(
        base64Decode(lomba.gambarPath!.split(',').last),
        fit: BoxFit.contain, // Gambar terlihat sepenuhnya
      );
    } else if (lomba.gambarPath!.startsWith('http')) {
      return Image.network(
        lomba.gambarPath!,
        fit: BoxFit.contain,
      );
    } else {
      return Image.file(
        File(lomba.gambarPath!),
        fit: BoxFit.contain,
      );
    }
  }

  Widget _infoItem(IconData icon, String title, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: kPrimaryColor, size: 20),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
