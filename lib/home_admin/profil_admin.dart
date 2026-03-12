import 'dart:io';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/database/sql_lite.dart';
import 'package:match_discovery/extension/navigator.dart';
import 'package:match_discovery/home_admin/daftar_admin.dart';
import 'package:match_discovery/login/login.dart';
import 'package:match_discovery/models/admin_model.dart'; // Ganti ke AdminModel
import 'package:image_picker/image_picker.dart';

class ProfilAdmin extends StatefulWidget {
  const ProfilAdmin({super.key});

  @override
  State<ProfilAdmin> createState() => _ProfilAdminState();
}

class _ProfilAdminState extends State<ProfilAdmin> {
  final ImagePicker _picker = ImagePicker();
  AdminModel? _admin; // Menggunakan AdminModel

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  // Ambil data admin dari DB
  Future<void> _fetchAdminData() async {
    int? id = await PreferenceHandler.getId();
    if (id != null) {
      AdminModel? data = await DBHelper.getAdminById(id);
      setState(() {
        _admin = data;
      });
    }
  }

  // Fungsi ganti foto profil
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null && _admin != null) {
      // Buat objek update dengan path foto baru
      AdminModel updatedAdmin = AdminModel(
        id: _admin!.id,
        username: _admin!.username,
        password: _admin!.password,
        nama: _admin!.nama,
        profilePath: image.path,
        role: _admin!.role,
      );

      // 1. Update ke Database (Gunakan fungsi update khusus admin)
      await DBHelper.updateAdminProfile(updatedAdmin);

      // 2. Refresh UI
      _fetchAdminData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil admin berhasil diperbarui')),
      );
    }
  }

  void _showAddAdminDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController userController = TextEditingController();
    final TextEditingController passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Admin Baru"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nama Lengkap"),
              ),
              TextField(
                controller: userController,
                decoration: const InputDecoration(labelText: "Username"),
              ),
              TextField(
                controller: passController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  userController.text.isNotEmpty &&
                  passController.text.isNotEmpty) {
                // Buat objek admin baru
                AdminModel newAdmin = AdminModel(
                  nama: nameController.text,
                  username: userController.text,
                  password: passController.text,
                  role: 'biasa', // Admin yang dibuat otomatis role 'biasa'
                  profilePath: '',
                );

                // Simpan ke database
                await DBHelper.addAdmin(newAdmin);

                if (!context.mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Admin baru berhasil ditambahkan!"),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Semua field harus diisi!")),
                );
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  // Tambahkan fungsi ini di dalam _DaftarAdminPageState
  void _showEditSelfDialog() {
    if (_admin == null) return;

    final nameController = TextEditingController(text: _admin!.nama);
    final userController = TextEditingController(text: _admin!.username);
    final passController = TextEditingController(text: _admin!.password);

    // Variabel lokal untuk mengontrol terlihatnya password
    bool isPasswordVisible = false;

    showDialog(
      context: context,
      builder: (context) {
        // Menggunakan StatefulBuilder agar UI di dalam dialog bisa di-refresh
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Edit Profil Saya"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Nama Lengkap",
                        icon: Icon(Icons.person),
                      ),
                    ),
                    TextField(
                      controller: userController,
                      decoration: const InputDecoration(
                        labelText: "Username",
                        icon: Icon(Icons.alternate_email),
                      ),
                    ),
                    TextField(
                      controller: passController,
                      obscureText: !isPasswordVisible, // Logika sensor
                      decoration: InputDecoration(
                        labelText: "Password Baru",
                        icon: const Icon(Icons.lock_outline),
                        // Tambahkan tombol mata di sini
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            // Gunakan setState milik StatefulBuilder
                            setStateDialog(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty &&
                        userController.text.isNotEmpty &&
                        passController.text.isNotEmpty) {
                      await DBHelper.updateAdminDetail(
                        _admin!.id!,
                        nameController.text,
                        userController.text,
                        passController.text,
                      );

                      if (!mounted) return;
                      Navigator.pop(context);
                      _fetchAdminData(); // Refresh tampilan profil

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Profil berhasil diperbarui!"),
                        ),
                      );
                    }
                  },
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xff0f2a55),
        title: const Text(
          'Profil Admin',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.fromARGB(255, 61, 77, 104), Colors.white],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 50),
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xff0f2a55),
                            width: 4.0,
                          ),
                        ),
                        child: ClipOval(
                          child:
                              _admin?.profilePath != null &&
                                  _admin!.profilePath!.isNotEmpty
                              ? Image.file(
                                  File(_admin!.profilePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.person, size: 80),
                                )
                              : const Icon(Icons.person, size: 80),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xff0f2a55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  _admin?.nama ?? 'Admin',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Chip Role (Menampilkan apakah dia Super Admin atau Admin Biasa)
                Container(
                  // margin: const EdgeInsets.top(5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _admin?.role == 'super'
                        ? Colors.amber
                        : Colors.blueGrey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _admin?.role == 'super' ? 'SUPER ADMIN' : 'ADMIN STAFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Informasi Akun
          if (_admin?.role == 'super') ...[
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.blue),
              title: const Text("Tambah Admin Baru"),
              subtitle: const Text("Buat akun akses untuk staff admin"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showAddAdminDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts, color: Colors.green),
              title: const Text("Kelola Daftar Admin"),
              subtitle: const Text("Lihat dan hapus staff admin"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DaftarAdminPage(),
                  ),
                ).then((_) => _fetchAdminData()); // Refresh data saat kembali
              },
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.badge),
            title: const Text("Username"),
            subtitle: Text(_admin?.username ?? "-"),
            trailing: IconButton(
              icon: const Icon(Icons.edit_note, color: Colors.blue),
              onPressed:
                  _showEditSelfDialog, // Panggil dialog edit diri sendiri
            ),
          ),
          const Spacer(),

          // Tombol Logout
          // Tombol Logout
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: 50,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Tampilkan Dialog Konfirmasi Logout
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Konfirmasi Logout"),
                      content: const Text(
                        "Apakah Anda yakin ingin keluar dari akun ini?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context), // Tutup dialog saja
                          child: const Text("Batal"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            // Jalankan proses logout
                            await PreferenceHandler.deleteIsLogin();
                            await PreferenceHandler.deleteId();

                            if (!mounted) return;
                            // Tutup dialog dan pindah ke halaman Login
                            Navigator.pop(context);
                            context.pushAndRemoveAll(const Login());
                          },
                          child: const Text("Keluar"),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Log Out'),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
