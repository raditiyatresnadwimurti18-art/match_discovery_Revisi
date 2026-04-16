import 'dart:io';
import 'package:flutter/material.dart';
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
  // ✅ Hapus: LoginModel? _user — tidak dipakai
  List<LombaModel> _allLomba = [];
  String? _imagePath;

  final _judulCtrl = TextEditingController();
  final _lokasiCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  final _kuotaCtrl = TextEditingController();
  final _jenisCtrl = TextEditingController();
  final _tanggalCtrl = TextEditingController();

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
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
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
                // Handle bar
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

                // Preview Gambar
                _imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _imagePath!.startsWith('http')
                            ? Image.network(
                                _imagePath!,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                              )
                            : _imagePath!.startsWith('assets/')
                                ? Image.asset(
                                    _imagePath!,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                  )
                                : Image.file(
                                    File(_imagePath!),
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                  ),
                      )
                    : Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 36,
                              color: Colors.grey,
                            ),
                            Text('Belum ada gambar', style: kSubtitleStyle),
                          ],
                        ),
                      ),
                const SizedBox(height: 8),

                // Tombol Pilih Gambar
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.image_outlined),
                    label: Text(id == null ? 'Pilih Gambar' : 'Update Gambar'),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _judulCtrl,
                  decoration: decorationConstant(
                    hintText: 'Judul Lomba',
                    labelText: 'Judul',
                    prefixIcon: Icons.emoji_events_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lokasiCtrl,
                  decoration: decorationConstant(
                    hintText: 'Lokasi',
                    labelText: 'Lokasi',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _jenisCtrl,
                  decoration: decorationConstant(
                    hintText: 'Jenis Lomba',
                    labelText: 'Jenis',
                    prefixIcon: Icons.category_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _kuotaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: decorationConstant(
                    hintText: 'Kuota Peserta',
                    labelText: 'Kuota',
                    prefixIcon: Icons.people_outline,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _deskripsiCtrl,
                  maxLines: 3,
                  decoration: decorationConstant(
                    hintText: 'Deskripsi lomba...',
                    labelText: 'Deskripsi',
                    prefixIcon: Icons.description_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tanggalCtrl,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration:
                      decorationConstant(
                        hintText: 'Pilih tanggal lomba',
                        labelText: 'Tanggal',
                        prefixIcon: Icons.calendar_today_outlined,
                      ).copyWith(
                        suffixIcon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey,
                        ),
                      ),
                ),
                const SizedBox(height: 20),

                // Tombol Simpan / Update
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: kPrimaryButtonStyle(),
                    onPressed: () async {
                      // Tampilkan loading
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

                      if (id == null) {
                        await LombaController.insertLomba(lomba);
                      } else {
                        await LombaController.updateLomba(lomba);
                      }

                      await _refreshLomba();
                      
                      if (!mounted) return;
                      Navigator.of(context).pop(); // Tutup loading
                      Navigator.of(context).pop(); // Tutup bottom sheet
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(id == null ? 'Lomba berhasil ditambahkan' : 'Lomba berhasil diperbarui'),
                          backgroundColor: Colors.green,
                        ),
                      );
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Berhasil menghapus data'),
        backgroundColor: Colors.red,
      ),
    );
    _refreshLomba();
  }

  void _showDetailDialog(BuildContext context, LombaModel lomba) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        // ✅ Flexible agar title tidak overflow
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: kAccentColor),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                "Detail Kompetisi",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (lomba.gambarPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: lomba.gambarPath!.startsWith('http')
                      ? Image.network(lomba.gambarPath!, height: 200)
                      : lomba.gambarPath!.startsWith('assets/')
                          ? Image.asset(lomba.gambarPath!, height: 200)
                          : Image.file(File(lomba.gambarPath!), height: 200),
                ),
              const SizedBox(height: 10),
              _detailRow(Icons.emoji_events_outlined, "Judul", lomba.judul),
              _detailRow(Icons.location_on_outlined, "Lokasi", lomba.lokasi),
              _detailRow(Icons.category_outlined, "Jenis", lomba.jenis),
              _detailRow(
                Icons.people_outline,
                "Kuota",
                lomba.kuota?.toString(),
              ),
              _detailRow(
                Icons.description_outlined,
                "Deskripsi",
                lomba.deskripsi,
              ),
              _detailRow(
                Icons.calendar_today_outlined,
                "Tanggal",
                lomba.tanggal,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup", style: TextStyle(color: kPrimaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(value ?? '-', style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Daftar Kompetisi",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () => _showForm(null),
              icon: const Icon(
                Icons.add_circle,
                color: kPrimaryColor,
                size: 30,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _allLomba.isEmpty
            ? const Center(child: Text("Belum ada data lomba."))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _allLomba.length,
                itemBuilder: (context, index) {
                  final lomba = _allLomba[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: kCardDecoration(),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(kBorderRadius),
                      child: ListTile(
                        leading: InkWell(
                          onTap: () => _showDetailDialog(context, lomba),
                          child: lomba.gambarPath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: lomba.gambarPath!.startsWith('http')
                                      ? Image.network(
                                          lomba.gambarPath!,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        )
                                      : lomba.gambarPath!.startsWith('assets/')
                                          ? Image.asset(
                                              lomba.gambarPath!,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.file(
                                              File(lomba.gambarPath!),
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            ),
                                )
                              : const Icon(Icons.image_not_supported),
                        ),
                        title: Text(
                          lomba.judul ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          lomba.lokasi ?? '-',
                          style: kSubtitleStyle,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.orange,
                              ),
                              onPressed: () => _showForm(lomba.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  // ✅ Flexible pada dialog hapus
                                  title: const Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Flexible(child: Text("Konfirmasi Hapus")),
                                    ],
                                  ),
                                  content: const Text(
                                    "Apakah Anda yakin ingin menghapus lomba ini?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                        "Batal",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: kDangerButtonStyle(),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteLomba(lomba.id!);
                                      },
                                      child: const Text("Hapus"),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}
