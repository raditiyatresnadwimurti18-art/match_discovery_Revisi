import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/kelompok.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/home_user/detail_kelompok.dart';
import 'package:match_discovery/models/kelompok_model.dart';
import 'package:match_discovery/models/lomba_model.dart';
import 'package:match_discovery/util/app_theme.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DaftarKelompokSayaPage extends StatefulWidget {
  const DaftarKelompokSayaPage({super.key});

  @override
  State<DaftarKelompokSayaPage> createState() => _DaftarKelompokSayaPageState();
}

class _DaftarKelompokSayaPageState extends State<DaftarKelompokSayaPage> {
  String? _myId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final id = await PreferenceHandler.getUserId();
    if (mounted) {
      setState(() {
        _myId = id;
        _isLoading = false;
      });
    }
  }

  Future<LombaModel?> _getLombaData(String idLomba) async {
    final doc = await FirebaseFirestore.instance.collection('lomba').doc(idLomba).get();
    if (!doc.exists) {
      // Cek di riwayatEvent jika tidak ada di lomba (mungkin sudah penuh/selesai)
      final eventDoc = await FirebaseFirestore.instance.collection('riwayatEvent').doc(idLomba).get();
      if (!eventDoc.exists) return null;
      return LombaModel.fromMap(eventDoc.data()!, docId: eventDoc.id);
    }
    return LombaModel.fromMap(doc.data()!, docId: doc.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_myId == null) {
      return const Scaffold(body: Center(child: Text("Silahkan login terlebih dahulu")));
    }

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: Text("Kelompok Saya", style: kTitleStyle.copyWith(fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('kelompok')
            .where('anggotaIds', arrayContains: _myId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("Kamu belum bergabung dengan kelompok manapun", style: kSubtitleStyle),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final k = KelompokModel.fromMap(docs[index].data() as Map<String, dynamic>, docId: docs[index].id);
              
              return FutureBuilder<LombaModel?>(
                future: _getLombaData(k.idLomba),
                builder: (context, lombaSnap) {
                  final lomba = lombaSnap.data;
                  final judul = lomba?.judul ?? "Memuat...";
                  final isPenuh = k.status == 'penuh';

                  return FadeInUp(
                    delay: Duration(milliseconds: index * 100),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: kCardDecoration(),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.groups_rounded, color: kPrimaryColor),
                        ),
                        title: Text(judul, style: kTitleStyle.copyWith(fontSize: 15)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("${k.anggotaIds.length}/${k.maxAnggota} Anggota", style: kSubtitleStyle),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isPenuh ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isPenuh ? "Terdaftar" : "Mencari Partner",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isPenuh ? Colors.green : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                        onTap: lomba == null ? null : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailKelompokPage(idKelompok: k.id!, lomba: lomba),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
