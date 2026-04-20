import 'dart:io';
import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:match_discovery/database/controllers/lomba.dart';
import 'package:match_discovery/models/lomba_model.dart';
import 'package:match_discovery/util/app_theme.dart';
import 'package:match_discovery/util/decoration_form.dart';
import 'package:image_picker/image_picker.dart';

class Widget2 extends StatefulWidget {
  const Widget2({super.key});

  @override
  State<Widget2> createState() => _Widget2State();
}

class _Widget2State extends State<Widget2> {
  List<LombaModel> _allLomba = [];
  String? _imagePath;

  final _judulCtrl = TextEditingController();
  final _lokasiCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  final _kuotaCtrl = TextEditingController();
  final _jenisCtrl = TextEditingController();
  final _tanggalCtrl = TextEditingController();

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
    _refreshLomba();
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _lokasiCtrl.dispose();
    _deskripsiCtrl.dispose();
    _kuotaCtrl.dispose();
    _jenisCtrl.dispose();
    _tanggalCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshLomba() async {
    final data = await LombaController.getAllLomba();
    if (!mounted) return;
    setState(() => _allLomba = data);
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _tanggalCtrl.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) setState(() => _imagePath = image.path);
  }

  void _showForm(String? id) {
    if (id != null) {
      final e = _allLomba.firstWhere((e) => e.id == id);
      _judulCtrl.text = e.judul ?? '';
      _lokasiCtrl.text = e.lokasi ?? '';
      _deskripsiCtrl.text = e.deskripsi ?? '';
      _kuotaCtrl.text = e.kuota.toString();
      _jenisCtrl.text = e.jenis ?? '';
      _tanggalCtrl.text = e.tanggal ?? '';
      _imagePath = e.gambarPath;
    } else {
      _judulCtrl.clear();
      _lokasiCtrl.clear();
      _deskripsiCtrl.clear();
      _kuotaCtrl.clear();
      _jenisCtrl.clear();
      _tanggalCtrl.clear();
      _imagePath = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModal) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  id == null ? 'Tambah Lomba' : 'Edit Lomba',
                  style: kTitleStyle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 12),
                _buildImagePreview(id, _imagePath),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _pickImage();
                      setModal(() {});
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryColor,
                      side: const BorderSide(color: kPrimaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.image_outlined),
                    label: Text(id == null ? 'Pilih Gambar' : 'Update Gambar'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _judulCtrl,
                  decoration: decorationConstant(hintText: 'Judul Lomba', labelText: 'Judul', prefixIcon: Icons.emoji_events_outlined),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lokasiCtrl,
                  decoration: decorationConstant(hintText: 'Lokasi', labelText: 'Lokasi', prefixIcon: Icons.location_on_outlined),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _jenisCtrl,
                  decoration: decorationConstant(hintText: 'Jenis Lomba', labelText: 'Jenis', prefixIcon: Icons.category_outlined),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _kuotaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: decorationConstant(hintText: 'Kuota Peserta', labelText: 'Kuota', prefixIcon: Icons.people_outline),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _deskripsiCtrl,
                  maxLines: 3,
                  decoration: decorationConstant(hintText: 'Deskripsi lomba...', labelText: 'Deskripsi', prefixIcon: Icons.description_outlined),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tanggalCtrl,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: decorationConstant(hintText: 'Pilih tanggal lomba', labelText: 'Tanggal', prefixIcon: Icons.calendar_today_outlined).copyWith(
                    suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: kPrimaryButtonStyle(),
                    onPressed: () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(child: CircularProgressIndicator()),
                      );

                      final lomba = LombaModel(
                        id: id,
                        judul: _judulCtrl.text,
                        lokasi: _lokasiCtrl.text,
                        gambarPath: _imagePath,
                        kuota: int.tryParse(_kuotaCtrl.text) ?? 0,
                        jenis: _jenisCtrl.text,
                        deskripsi: _deskripsiCtrl.text,
                        tanggal: _tanggalCtrl.text,
                      );

                      Map<String, dynamic> result;
                      if (id == null) {
                        result = await LombaController.insertLomba(lomba);
                      } else {
                        result = await LombaController.updateLomba(lomba);
                      }

                      await _refreshLomba();
                      if (!mounted) return;
                      Navigator.of(context).pop();
                      
                      if (result['success'] == true) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(id == null ? 'Berhasil tambah' : 'Berhasil update'), backgroundColor: Colors.green));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Gagal'), backgroundColor: Colors.red));
                      }
                    },
                    child: Text(id == null ? 'Simpan' : 'Update'),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteLomba(String id) async {
    await LombaController.deleteLomba(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil hapus'), backgroundColor: Colors.red));
    _refreshLomba();
  }

  Widget _buildImage(String? id, String? path, {double? width, double? height, double radius = 8}) {
    if (path == null || path.isEmpty) {
      return Container(
        width: width, height: height,
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(radius)),
        child: Icon(Icons.image, color: Colors.grey.shade400, size: 24),
      );
    }

    if (path.startsWith('data:image')) {
      try {
        final base64String = path.split(',').last;
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.memory(
            base64Decode(base64String),
            width: width, height: height,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
          ),
        );
      } catch (e) {
        return Container(width: width, height: height, color: Colors.grey.shade200, child: const Icon(Icons.broken_image));
      }
    }

    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: path.startsWith('http') 
          ? Image.network(path, width: width, height: height, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
          : Image.file(File(path), width: width, height: height, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
      );
    } catch (e) {
      return Container(width: width, height: height, color: Colors.grey.shade200, child: const Icon(Icons.broken_image));
    }
  }

  Widget _buildImagePreview(String? id, String? path) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _buildImage(id, path, height: 120, width: double.infinity, radius: 12),
    );
  }

  void _confirmDelete(LombaModel lomba) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 8), Flexible(child: Text("Konfirmasi Hapus"))]),
        content: Text("Apakah Anda yakin ingin menghapus lomba \"${lomba.judul}\"?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(style: kDangerButtonStyle(), onPressed: () { Navigator.pop(context); _deleteLomba(lomba.id!); }, child: const Text("Hapus")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: kPrimaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Manajemen Kompetisi", style: kTitleStyle),
                      Text("Kelola semua daftar lomba aktif", style: kSubtitleStyle),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _allLomba.isEmpty
                ? Center(
                    child: FadeIn(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.layers_clear_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text("Belum ada data lomba", style: kSubtitleStyle),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshLomba,
                    color: kPrimaryColor,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: _allLomba.length,
                      itemBuilder: (context, index) {
                        final lomba = _allLomba[index];
                        return FadeInRight(
                          delay: Duration(milliseconds: index * 50),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: kCardDecoration(),
                            child: InkWell(
                              onTap: () => _showForm(lomba.id),
                              borderRadius: BorderRadius.circular(kCardRadius),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Hero(
                                      tag: 'lomba_${lomba.id}',
                                      child: _buildImage(lomba.id, lomba.gambarPath, width: 80, height: 80, radius: 16),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            lomba.judul ?? '-',
                                            style: kTitleStyle.copyWith(fontSize: 15),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on_rounded, size: 14, color: kSecondaryColor),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(lomba.lokasi ?? '-', style: kSubtitleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: kPrimaryColor.withValues(alpha: 0.05),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _formatTanggal(lomba.tanggal),
                                              style: kSubtitleStyle.copyWith(fontSize: 10, color: kPrimaryColor, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                          onPressed: () => _confirmDelete(lomba),
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                                        ),
                                        const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(null),
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Tambah Lomba", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
