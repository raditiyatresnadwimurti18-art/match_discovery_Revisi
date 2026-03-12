import 'dart:io';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/database/sql_lite.dart';
import 'package:match_discovery/models/login_model.dart';
import 'package:image_picker/image_picker.dart';

class Widget2 extends StatefulWidget {
  const Widget2({super.key});

  @override
  State<Widget2> createState() => _Widget2State();
}

class _Widget2State extends State<Widget2> {
  LoginModel? _user;
  List<Map<String, dynamic>> _allLomba = [];

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
    _refreshLomba(); // Ambil data lomba saat start
  }

  Future<void> _fetchUserData() async {
    int? id = await PreferenceHandler.getId();
    if (id != null) {
      LoginModel? data = await DBHelper.getUserById(id);
      setState(() {
        _user = data;
      });
    }
  }

  // Ambil data dari database lomba
  void _refreshLomba() async {
    final data = await DBHelper.getAllLomba();
    setState(() {
      _allLomba = data;
    });
  }

  // --- FUNGSI CRUD UI ---

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        // Format tanggal sesuai keinginan (YYYY-MM-DD)
        _tanggalController.text =
            "${picked.year}-${picked.month}-${picked.day}";
      });
    }
  }

  void _showForm(int? id) async {
    if (id != null) {
      final existingData = _allLomba.firstWhere(
        (element) => element['id'] == id,
      );
      _judulController.text = existingData['judul'];
      _lokasiController.text = existingData['lokasi'];
      _deskripsiController.text = existingData['deskripsi'];
      _kuotaController.text = existingData['kuota']?.toString() ?? "0";
      _jenisController.text = existingData['jenis'];
      _tanggalController.text =
          existingData['tanggal'] ?? "Tanggal belum diatur";
    } else {
      _judulController.clear();
      _lokasiController.clear();
      _deskripsiController.clear();
      _kuotaController.clear();
      _jenisController.clear();
      _tanggalController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              id == null ? 'Tambah Lomba' : 'Edit Lomba',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _imagePath == null
                ? const Text("Belum ada gambar")
                : Image.file(
                    File(_imagePath!),
                    height: 100,
                  ), // Tampilkan preview
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: Text(id == null ? 'Pilih gambar' : 'Update gambar'),
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
              decoration: const InputDecoration(labelText: 'jenis'),
            ),
            TextField(
              controller: _kuotaController,
              decoration: const InputDecoration(labelText: 'kuota'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _deskripsiController,
              decoration: const InputDecoration(labelText: 'deskripsi'),
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
                final data = {
                  'judul': _judulController.text,
                  'lokasi': _lokasiController.text,
                  'gambarPath': _imagePath,
                  'kuota': int.tryParse(_kuotaController.text) ?? 0,
                  'jenis': _jenisController.text,
                  'deskripsi': _deskripsiController.text,
                  'tanggal': _tanggalController.text,
                };

                if (id == null) {
                  await DBHelper.insertLomba(data);
                } else {
                  await DBHelper.updateLomba(id, data);
                }

                _refreshLomba();
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
    );
  }

  void _deleteLomba(int id) async {
    await DBHelper.deleteLomba(id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Berhasil menghapus data')));
    _refreshLomba();
  }

  // late int id;

  void _showDetailDialog(
    BuildContext context,
    int id,
    String judul,
    String lokasi,
    String _imagePath,
    String jenis,
    int kuota,
    String deskripsi,
    String tanggal,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Detail Kompetisi",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Image.file(File(_imagePath), height: 400)),
              Row(
                children: [
                  Text(
                    "Judul:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(width: 3),
                  Text(judul, style: const TextStyle(fontSize: 16)),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    "Lokasi:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(width: 3),
                  Text(lokasi, style: const TextStyle(fontSize: 16)),
                ],
              ),
              Row(
                children: [
                  Text(
                    "Jenis:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(width: 3),
                  Text(jenis, style: const TextStyle(fontSize: 16)),
                ],
              ),
              Row(
                children: [
                  Text(
                    "Kuota:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(width: 3),
                  Text(
                    kuota?.toString() ?? "0",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    "Deskripsi:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(width: 3),
                  Text(deskripsi, style: const TextStyle(fontSize: 16)),
                ],
              ),
              Row(
                children: [
                  Text(
                    "Tanggal::",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(width: 3),
                  Text(
                    tanggal?.toString() ?? "0",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
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
        );
      },
    );
  }

  String? _imagePath;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baris Header & Tombol Tambah
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

        // List Data Lomba dari Database
        _allLomba.isEmpty
            ? const Center(child: Text("Belum ada data lomba."))
            : ListView.builder(
                shrinkWrap: true, // Agar bisa masuk ke dalam Column
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _allLomba.length,
                itemBuilder: (context, index) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: InkWell(
                      onTap: () {
                        // Fungsi untuk menampilkan pop up
                        _showDetailDialog(
                          context,
                          _allLomba[index]['id'],
                          _allLomba[index]['judul'],
                          _allLomba[index]['lokasi'],
                          _allLomba[index]['gambarPath'],
                          _allLomba[index]['jenis'],
                          _allLomba[index]['kuota'],
                          _allLomba[index]['deskripsi'],
                          _allLomba[index]['tanggal'],
                        );
                      },
                      child: _allLomba[index]['gambarPath'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_allLomba[index]['gambarPath']),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(Icons.image_not_supported),
                    ),
                    title: Text(
                      _allLomba[index]['judul'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(_allLomba[index]['lokasi']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _showForm(_allLomba[index]['id']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteLomba(_allLomba[index]['id']),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}
