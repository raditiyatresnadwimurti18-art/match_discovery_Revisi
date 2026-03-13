import 'dart:io';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/lomba.dart';
import 'package:match_discovery/database/controllers/user.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/models/login_model.dart';
import 'package:match_discovery/models/lomba_model.dart';
import 'package:image_picker/image_picker.dart';

class Widget2 extends StatefulWidget {
  const Widget2({super.key});

  @override
  State<Widget2> createState() => _Widget2State();
}

class _Widget2State extends State<Widget2> {
  LoginModel? _user;
  List<LombaModel> _allLomba = [];
  String? _imagePath;

  // Controller untuk Form
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _kuotaController = TextEditingController();
  final TextEditingController _jenisController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _refreshLomba();
  }

  Future<void> _fetchUserData() async {
    final id = await PreferenceHandler.getId();
    if (id != null) {
      final data = await UserController.getUserById(id);
      setState(() => _user = data);
    }
  }

  Future<void> _refreshLomba() async {
    final data = await LombaController.getAllLomba();
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
        _tanggalController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imagePath = image.path);
    }
  }

  void _showForm(int? id) async {
    LombaModel? existing;
    if (id != null) {
      existing = _allLomba.firstWhere((e) => e.id == id);
      _judulController.text = existing.judul ?? '';
      _lokasiController.text = existing.lokasi ?? '';
      _deskripsiController.text = existing.deskripsi ?? '';
      _kuotaController.text = existing.kuota?.toString() ?? '0';
      _jenisController.text = existing.jenis ?? '';
      _tanggalController.text = existing.tanggal ?? '';
      _imagePath = existing.gambarPath;
    } else {
      _judulController.clear();
      _lokasiController.clear();
      _deskripsiController.clear();
      _kuotaController.clear();
      _jenisController.clear();
      _tanggalController.clear();
      _imagePath = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                Text(
                  id == null ? 'Tambah Lomba' : 'Edit Lomba',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _imagePath == null
                    ? const Text("Belum ada gambar")
                    : Image.file(File(_imagePath!), height: 100),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _pickImage();
                    setModalState(() {});
                  },
                  icon: const Icon(Icons.image),
                  label: Text(id == null ? 'Pilih Gambar' : 'Update Gambar'),
                ),
                TextField(
                  controller: _judulController,
                  decoration: const InputDecoration(labelText: 'Judul Lomba'),
                ),
                TextField(
                  controller: _lokasiController,
                  decoration: const InputDecoration(labelText: 'Lokasi'),
                ),
                TextField(
                  controller: _jenisController,
                  decoration: const InputDecoration(labelText: 'Jenis'),
                ),
                TextField(
                  controller: _kuotaController,
                  decoration: const InputDecoration(labelText: 'Kuota'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _deskripsiController,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                ),
                TextField(
                  controller: _tanggalController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Lomba',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                  ),
                  onPressed: () async {
                    final lomba = LombaModel(
                      id: id,
                      judul: _judulController.text,
                      lokasi: _lokasiController.text,
                      gambarPath: _imagePath,
                      kuota: int.tryParse(_kuotaController.text) ?? 0,
                      jenis: _jenisController.text,
                      deskripsi: _deskripsiController.text,
                      tanggal: _tanggalController.text,
                    );

                    if (id == null) {
                      await LombaController.insertLomba(lomba);
                    } else {
                      await LombaController.updateLomba(lomba);
                    }

                    await _refreshLomba();
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    id == null ? 'Simpan' : 'Update',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteLomba(int id) async {
    await LombaController.deleteLomba(id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Berhasil menghapus data')));
    _refreshLomba();
  }

  void _showDetailDialog(BuildContext context, LombaModel lomba) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Detail Kompetisi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (lomba.gambarPath != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(lomba.gambarPath!), height: 200),
                  ),
                ),
              const SizedBox(height: 10),
              _detailRow("Judul", lomba.judul),
              _detailRow("Lokasi", lomba.lokasi),
              _detailRow("Jenis", lomba.jenis),
              _detailRow("Kuota", lomba.kuota?.toString()),
              _detailRow("Deskripsi", lomba.deskripsi),
              _detailRow("Tanggal", lomba.tanggal),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Tutup",
              style: TextStyle(color: Color(0xFF6366F1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                color: Color(0xFF6366F1),
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
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: InkWell(
                        onTap: () => _showDetailDialog(context, lomba),
                        child: lomba.gambarPath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
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
                      subtitle: Text(lomba.lokasi ?? '-'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => _showForm(lomba.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Konfirmasi"),
                                content: const Text(
                                  "Apakah Anda yakin ingin menghapus lomba ini?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Batal"),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
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
                  );
                },
              ),
      ],
    );
  }
}
