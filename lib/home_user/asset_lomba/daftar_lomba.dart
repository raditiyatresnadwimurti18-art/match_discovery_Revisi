import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:match_discovery/database/controllers/lomba.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/models/lomba_model.dart';
import 'package:match_discovery/util/app_theme.dart';
import 'package:match_discovery/home_user/asset_lomba/detail_lomba.dart';

class DaftarLomba extends StatefulWidget {
  const DaftarLomba({super.key});

  @override
  State<DaftarLomba> createState() => _DaftarLombaState();
}

class _DaftarLombaState extends State<DaftarLomba> {
  List<LombaModel> _lombaList = [];
  bool _isLoading = true;

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
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await LombaController.getAllLomba();
      if (!mounted) return;
      setState(() {
        _lombaList = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLombaDetailDialog(BuildContext context, LombaModel lomba) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.emoji_events, color: kAccentColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lomba.judul,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimaryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoPopup(Icons.people_outline, "Kuota", "${lomba.kuota}"),
              _infoPopup(Icons.calendar_today_outlined, "Tanggal", _formatTanggal(lomba.tanggal)),
              const SizedBox(height: 15),
              const Text(
                "Klik detail untuk melihat informasi lengkap dan mendaftar.",
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Tutup", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: kPrimaryButtonStyle(radius: 12),
              onPressed: () {
                Navigator.pop(dialogContext); // Tutup Pop up
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetailLomba(lomba: lomba)),
                ).then((_) => _loadData()); // Refresh data saat kembali
              },
              child: const Text("Detail"),
            ),
          ],
        );
      },
    );
  }

  Widget _infoPopup(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kPrimaryColor),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));

    if (_lombaList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 16)],
              ),
              child: const Icon(Icons.inbox_outlined, size: 48, color: kPrimaryColor),
            ),
            const SizedBox(height: 12),
            const Text("Tidak ada data lomba", style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _lombaList.length,
      itemBuilder: (context, index) {
        final lomba = _lombaList[index];
        return InkWell(
          onTap: () => _showLombaDetailDialog(context, lomba),
          child: Container(
            decoration: kCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(kBorderRadius)),
                    child: _buildItemImage(lomba.gambarPath),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lomba.judul,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.people_outline, size: 13, color: kPrimaryColor),
                          const SizedBox(width: 4),
                          Text("Kuota: ${lomba.kuota ?? 0}", style: TextStyle(color: Colors.grey[700], fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemImage(String? path) {
    if (path == null || path.isEmpty) {
      return Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey));
    }
    
    if (path.startsWith('data:image')) {
      return Image.memory(base64Decode(path.split(',').last), fit: BoxFit.cover, width: double.infinity);
    } else if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_,__,___) => const Icon(Icons.image));
    } else {
      return Image.file(File(path), fit: BoxFit.cover, width: double.infinity, errorBuilder: (_,__,___) => const Icon(Icons.image));
    }
  }
}
