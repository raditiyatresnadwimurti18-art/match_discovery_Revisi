import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/lomba.dart';
import 'package:match_discovery/database/controllers/riwayat.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/models/lomba_model.dart';
import 'package:match_discovery/models/riwayat_model.dart';
import 'package:match_discovery/util/app_theme.dart';

class DaftarLomba extends StatefulWidget {
  const DaftarLomba({super.key});

  @override
  State<DaftarLomba> createState() => _DaftarLombaState();
}

class _DaftarLombaState extends State<DaftarLomba> {
  List<LombaModel> _lombaList = [];
  bool _isLoading = true;

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

  void _konfirmasiIkutiLomba(String lombaId, BuildContext dialogContext) async {
    final userId = PreferenceHandler.getUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sesi berakhir, silakan login kembali")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await RiwayatController.ikutiLomba(
        RiwayatModel(
          idUser: userId,
          idLomba: lombaId,
          tanggalDaftar: DateTime.now().toIso8601String().split('T').first,
        ),
      );

      if (mounted) Navigator.pop(context); // Tutup loading

      if (result['success'] == true) {
        if (dialogContext.mounted) Navigator.pop(dialogContext); // Tutup detail

        if (mounted) {
          _showTokenDialog(
            result['token']?.toString() ?? "-",
            result['data'] as Map<String, dynamic>? ?? {},
          );
        }
        await _loadData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']?.toString() ?? "Gagal mendaftar"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Tutup loading jika error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showTokenDialog(String token, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 10),
            Text("Pendaftaran Berhasil!", textAlign: TextAlign.center),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Simpan token pendaftaran Anda:"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kPrimaryColor),
              ),
              child: Text(
                token,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: kPrimaryColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _infoRow(Icons.emoji_events, "Lomba", data['judul']?.toString()),
            _infoRow(Icons.location_on, "Lokasi", data['lokasi']?.toString()),
            _infoRow(Icons.calendar_today, "Tanggal", data['tanggal']?.toString()),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: kPrimaryButtonStyle(),
              onPressed: () => Navigator.pop(context),
              child: const Text("Selesai"),
            ),
          ),
        ],
      ),
    );
  }

  void _showLombaDetail(BuildContext context, LombaModel lomba) async {
    final userId = PreferenceHandler.getUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silahkan login terlebih dahulu")),
      );
      return;
    }

    final sedangIkut = await RiwayatController.isUserSedangIkutLomba(userId, lomba.id!);
    if (!mounted) return;

    final screenSize = MediaQuery.of(context).size;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: SizedBox(
            width: screenSize.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events, color: kAccentColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lomba.judul,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: kPrimaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: screenSize.height * 0.55),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (lomba.gambarPath != null && lomba.gambarPath!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: lomba.gambarPath!.startsWith('data:image')
                                ? Image.memory(
                                    base64Decode(lomba.gambarPath!.split(',').last),
                                    width: double.infinity,
                                    height: 160,
                                    fit: BoxFit.cover,
                                  )
                                : lomba.gambarPath!.startsWith('http')
                                    ? Image.network(
                                        lomba.gambarPath!,
                                        width: double.infinity,
                                        height: 160,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _placeholderImage(),
                                      )
                                    : Image.file(
                                        File(lomba.gambarPath!),
                                        width: double.infinity,
                                        height: 160,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _placeholderImage(),
                                      ),
                          )
                        else
                          _placeholderImage(),
                        const SizedBox(height: 14),
                        _infoRow(Icons.category_outlined, "Jenis", lomba.jenis),
                        _infoRow(Icons.calendar_today_outlined, "Tanggal", lomba.tanggal),
                        _infoRow(Icons.location_on_outlined, "Lokasi", lomba.lokasi),
                        _infoRow(Icons.people_outline, "Kuota", "${lomba.kuota ?? 0}"),
                        const Divider(height: 24),
                        const Text(
                          "Deskripsi:",
                          style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lomba.deskripsi ?? "Tidak ada deskripsi.",
                          style: kSubtitleStyle.copyWith(color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text("Tutup", style: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: sedangIkut ? null : () => _konfirmasiIkutiLomba(lomba.id!, dialogContext),
                        style: sedangIkut
                            ? ElevatedButton.styleFrom(backgroundColor: Colors.grey)
                            : kPrimaryButtonStyle(radius: 12),
                        child: Text(sedangIkut ? "Sudah Terdaftar" : "Daftar Sekarang"),
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

  Widget _placeholderImage() {
    return Container(
      height: 100,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
    );
  }

  Widget _infoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kPrimaryColor),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Expanded(child: Text(value ?? '-', style: const TextStyle(fontSize: 13, color: Colors.black87))),
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
          onTap: () => _showLombaDetail(context, lomba),
          child: Container(
            decoration: kCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(kBorderRadius)),
                    child: lomba.gambarPath != null && lomba.gambarPath!.isNotEmpty
                        ? (lomba.gambarPath!.startsWith('http')
                            ? Image.network(
                                lomba.gambarPath!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _placeholderImage(),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(child: CircularProgressIndicator());
                                },
                              )
                            : lomba.gambarPath!.startsWith('assets/')
                                ? Image.asset(lomba.gambarPath!, width: double.infinity, fit: BoxFit.cover)
                                : Image.file(File(lomba.gambarPath!), width: double.infinity, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _placeholderImage()))
                        : _placeholderImage(),
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
}
