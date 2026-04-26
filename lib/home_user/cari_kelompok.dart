import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/kelompok.dart';
import 'package:match_discovery/database/controllers/riwayat.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/home_user/detail_kelompok.dart';
import 'package:match_discovery/models/kelompok_model.dart';
import 'package:match_discovery/models/lomba_model.dart';
import 'package:match_discovery/util/app_theme.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CariKelompokPage extends StatefulWidget {
  final LombaModel lomba;
  const CariKelompokPage({super.key, required this.lomba});

  @override
  State<CariKelompokPage> createState() => _CariKelompokPageState();
}

class _CariKelompokPageState extends State<CariKelompokPage> {
  String? _myId;
  bool _isLoading = false;
  KelompokModel? _myKelompok;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final id = PreferenceHandler.getUserId();
    if (!mounted) return;
    setState(() => _myId = id);
    if (id != null) {
      _checkMyKelompok();
    }
  }

  Future<void> _checkMyKelompok() async {
    final k = await KelompokController.getMyKelompok(widget.lomba.id!, _myId!);
    if (mounted) setState(() => _myKelompok = k);
  }

  Future<Map<String, dynamic>> _getUserData(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data() ?? {};
  }

  Future<int> _getUserRiwayatCount(String uid) async {
    final riwayat = await RiwayatController.getRiwayatByUserId(uid);
    return riwayat.length;
  }

  void _buatKelompokBaru() async {
    if (_myId == null) return;
    
    setState(() => _isLoading = true);
    
    final kelompok = KelompokModel(
      idLomba: widget.lomba.id!,
      idLeader: _myId!,
      anggotaIds: [_myId!],
      maxAnggota: widget.lomba.jumlahAnggota ?? 0,
      status: 'mencari'
    );

    final res = await KelompokController.buatKelompok(kelompok);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil membuat pencarian kelompok"), backgroundColor: Colors.green));
      
      if (res['isFull'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DetailKelompokPage(idKelompok: res['id'], lomba: widget.lomba))
        );
      } else {
        _checkMyKelompok();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? "Gagal"), backgroundColor: Colors.red));
    }
  }

  void _gabungKelompok(String idKelompok) async {
    if (_myId == null) return;
    
    setState(() => _isLoading = true);
    final res = await KelompokController.gabungKelompok(idKelompok, _myId!);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil bergabung ke kelompok"), backgroundColor: Colors.green));
      
      // Jika setelah gabung langsung penuh, navigasi ke detail
      if (res['isFull'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DetailKelompokPage(idKelompok: idKelompok, lomba: widget.lomba))
        );
      } else {
        _checkMyKelompok();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? "Gagal"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: Text("Cari Partner - ${widget.lomba.judul}", style: kTitleStyle.copyWith(fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          if (_myKelompok != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_work_rounded, size: 80, color: kPrimaryColor),
                  const SizedBox(height: 16),
                  Text("Anda sudah berada dalam kelompok", style: kTitleStyle),
                  const SizedBox(height: 8),
                  Text("Status: ${_myKelompok!.status.toUpperCase()}", style: kSubtitleStyle),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DetailKelompokPage(idKelompok: _myKelompok!.id!, lomba: widget.lomba))
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text("Lihat Kelompok Saya"),
                    style: kPrimaryButtonStyle(),
                  )
                ],
              ),
            )
          else
            StreamBuilder<List<KelompokModel>>(
              stream: KelompokController.getKelompokTersedia(widget.lomba.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final list = snapshot.data ?? [];
                
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_add_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text("Belum ada yang mencari kelompok", style: kSubtitleStyle),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _buatKelompokBaru,
                          icon: const Icon(Icons.add),
                          label: const Text("Mulai Cari Partner"),
                          style: kPrimaryButtonStyle(),
                        )
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final k = list[index];
                    return FutureBuilder<Map<String, dynamic>>(
                      future: _getUserData(k.idLeader),
                      builder: (context, userSnap) {
                        final userData = userSnap.data ?? {};
                        return FadeInUp(
                          delay: Duration(milliseconds: index * 100),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: kCardDecoration(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: kPrimaryColor.withOpacity(0.1),
                                      child: Text(userData['nama']?[0].toUpperCase() ?? '?', style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(userData['nama'] ?? 'Loading...', style: kTitleStyle.copyWith(fontSize: 15)),
                                          Text("${k.anggotaIds.length}/${k.maxAnggota} Anggota Terkumpul", style: kSubtitleStyle.copyWith(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _gabungKelompok(k.id!),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text("Join", style: TextStyle(fontSize: 12)),
                                    )
                                  ],
                                ),
                                const Divider(height: 24),
                                FutureBuilder<int>(
                                  future: _getUserRiwayatCount(k.idLeader),
                                  builder: (context, countSnap) {
                                    return Row(
                                      children: [
                                        const Icon(Icons.history_rounded, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Track Record: ${countSnap.data ?? 0} Kompetisi diikuti",
                                          style: kSubtitleStyle.copyWith(fontSize: 11),
                                        ),
                                      ],
                                    );
                                  }
                                )
                              ],
                            ),
                          ),
                        );
                      }
                    );
                  },
                );
              },
            ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            )
        ],
      ),
      floatingActionButton: _myKelompok == null ? FloatingActionButton.extended(
        onPressed: _buatKelompokBaru,
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Cari Partner", style: TextStyle(color: Colors.white)),
      ) : null,
    );
  }
}

