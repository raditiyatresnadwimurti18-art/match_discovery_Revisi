import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/kelompok.dart';
import 'package:match_discovery/database/controllers/riwayat.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/models/kelompok_model.dart';
import 'package:match_discovery/models/lomba_model.dart';
import 'package:match_discovery/util/app_theme.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailKelompokPage extends StatefulWidget {
  final String idKelompok;
  final LombaModel lomba;

  const DetailKelompokPage({
    super.key,
    required this.idKelompok,
    required this.lomba,
  });

  @override
  State<DetailKelompokPage> createState() => _DetailKelompokPageState();
}

class _DetailKelompokPageState extends State<DetailKelompokPage> {
  String? _myId;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _myId = PreferenceHandler.getUserId();
  }

  Future<Map<String, dynamic>> _getUserData(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.data() ?? {};
  }

  void _konfirmasiSelesai() async {
    setState(() => _isProcessing = true);
    try {
      await RiwayatController.konfirmasiSelesaiKelompok(
        widget.idKelompok,
        widget.lomba.id!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Berhasil mengonfirmasi selesai untuk seluruh anggota"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: Text("Kelompok Saya", style: kTitleStyle.copyWith(fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<KelompokModel?>(
        stream: KelompokController.streamKelompokById(widget.idKelompok),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final kelompok = snapshot.data;
          if (kelompok == null) {
            return const Center(child: Text("Kelompok tidak ditemukan"));
          }

          bool isLeader = kelompok.idLeader == _myId;
          bool isPenuh = kelompok.status == 'penuh';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInDown(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: kCardDecoration(),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.groups_rounded,
                                color: kPrimaryColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.lomba.judul ?? 'Lomba',
                                    style: kTitleStyle,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isPenuh
                                        ? "Status: Terdaftar"
                                        : "Status: Mencari Anggota",
                                    style: kSubtitleStyle.copyWith(
                                      color: isPenuh
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Progres Kelompok", style: kSubtitleStyle),
                            Text(
                              "${kelompok.anggotaIds.length}/${kelompok.maxAnggota}",
                              style: kTitleStyle.copyWith(color: kPrimaryColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value:
                                kelompok.anggotaIds.length /
                                kelompok.maxAnggota,
                            backgroundColor: Colors.grey.shade200,
                            color: kPrimaryColor,
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text("Daftar Anggota", style: kTitleStyle),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: kelompok.anggotaIds.length,
                  itemBuilder: (context, index) {
                    final uid = kelompok.anggotaIds[index];
                    return FutureBuilder<Map<String, dynamic>>(
                      future: _getUserData(uid),
                      builder: (context, userSnap) {
                        final userData = userSnap.data ?? {};
                        final isMe = uid == _myId;
                        final isAnggotaLeader = uid == kelompok.idLeader;

                        return FadeInUp(
                          delay: Duration(milliseconds: index * 100),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: kCardDecoration(),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: kPrimaryColor.withOpacity(
                                    0.1,
                                  ),
                                  child: Text(
                                    userData['nama']?[0].toUpperCase() ?? '?',
                                    style: const TextStyle(
                                      color: kPrimaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${userData['nama'] ?? 'Loading...'} ${isMe ? '(Saya)' : ''}",
                                        style: kTitleStyle.copyWith(
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        isAnggotaLeader
                                            ? "Ketua Kelompok"
                                            : "Anggota",
                                        style: kSubtitleStyle.copyWith(
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isAnggotaLeader)
                                  const Icon(
                                    Icons.stars_rounded,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),
                if (isLeader && isPenuh)
                  FadeInUp(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _konfirmasiSelesai,
                        style: kPrimaryButtonStyle().copyWith(
                          backgroundColor: WidgetStateProperty.all(
                            Colors.green,
                          ),
                        ),
                        child: _isProcessing
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text("Konfirmasi Selesai (Semua Anggota)"),
                      ),
                    ),
                  )
                else if (isPenuh)
                  const Center(
                    child: Text(
                      "Menunggu Ketua Kelompok Mengonfirmasi Selesai",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
