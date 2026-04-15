import 'dart:io';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/admin.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/extension/navigator.dart';
import 'package:match_discovery/home_admin/daftar_admin.dart';
import 'package:match_discovery/login/login.dart';
import 'package:match_discovery/models/admin_model.dart';
import 'package:match_discovery/util/app_theme.dart';
import 'package:match_discovery/util/decoration_form.dart';
import 'package:image_picker/image_picker.dart';

class ProfilAdmin extends StatefulWidget {
  const ProfilAdmin({super.key});

  @override
  State<ProfilAdmin> createState() => _ProfilAdminState();
}

class _ProfilAdminState extends State<ProfilAdmin> {
  final ImagePicker _picker = ImagePicker();
  AdminModel? _admin;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    String? id = await PreferenceHandler.getAdminId();
    if (id == null) return;

    try {
      AdminModel? data = await AdminController.getAdminById(id);

      if (!mounted) return;

      if (data != null) {
        setState(() => _admin = data);
      } else {
        debugPrint('Admin dengan id $id tidak ditemukan');
      }
    } catch (e) {
      debugPrint('Error fetchAdminData: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && _admin != null) {
      AdminModel updated = AdminModel(
        id: _admin!.id,
        username: _admin!.username,
        password: _admin!.password,
        nama: _admin!.nama,
        profilePath: image.path,
        role: _admin!.role,
      );
      await AdminController.updateAdminProfile(updated);
      await _fetchAdminData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil admin berhasil diperbarui')),
      );
    }
  }

  void _showAddAdminDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_add, color: kPrimaryColor),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                "Tambah Admin Baru",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: decorationConstant(
                  hintText: 'Nama Lengkap',
                  labelText: 'Nama',
                  prefixIcon: Icons.person_outline,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: userCtrl,
                decoration: decorationConstant(
                  hintText: 'Username',
                  labelText: 'Username',
                  prefixIcon: Icons.alternate_email,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: decorationConstant(
                  hintText: 'Password',
                  labelText: 'Password',
                  prefixIcon: Icons.lock_outline,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: kPrimaryButtonStyle(radius: 12),
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty &&
                  userCtrl.text.isNotEmpty &&
                  passCtrl.text.isNotEmpty) {
                await AdminController.addAdmin(
                  AdminModel(
                    nama: nameCtrl.text,
                    username: userCtrl.text,
                    password: passCtrl.text,
                    role: 'admin',
                    profilePath: '',
                  ),
                );
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

  void _showEditSelfDialog() {
    if (_admin == null) return;
    final nameCtrl = TextEditingController(text: _admin!.nama);
    final userCtrl = TextEditingController(text: _admin!.username);
    final passCtrl = TextEditingController(text: _admin!.password);
    bool isPasswordVisible = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit, color: kPrimaryColor),
              SizedBox(width: 8),
              Text(
                "Edit Profil Saya",
                style: TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: decorationConstant(
                    hintText: 'Nama Lengkap',
                    labelText: 'Nama',
                    prefixIcon: Icons.person_outline,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: userCtrl,
                  decoration: decorationConstant(
                    hintText: 'Username',
                    labelText: 'Username',
                    prefixIcon: Icons.alternate_email,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: !isPasswordVisible,
                  decoration:
                      decorationConstant(
                        hintText: 'Password Baru',
                        labelText: 'Password',
                        prefixIcon: Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () => setStateDialog(
                            () => isPasswordVisible = !isPasswordVisible,
                          ),
                        ),
                      ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: kPrimaryButtonStyle(radius: 12),
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty &&
                    userCtrl.text.isNotEmpty &&
                    passCtrl.text.isNotEmpty) {
                  await AdminController.updateAdminDetail(
                    _admin!.id!,
                    nameCtrl.text,
                    userCtrl.text,
                    passCtrl.text,
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  await _fetchAdminData();
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: kPrimaryAppBar(title: 'Profil Admin', roundedBottom: false),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header Profil ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [kPrimaryColor, kBgColor],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: kAccentColor, width: 3.5),
                        ),
                        child: ClipOval(
                          child:
                              _admin?.profilePath != null &&
                                  _admin!.profilePath!.isNotEmpty
                              ? (_admin!.profilePath!.startsWith('http')
                                  ? Image.network(
                                      _admin!.profilePath!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 80),
                                    )
                                  : _admin!.profilePath!.startsWith('assets/')
                                      ? Image.asset(
                                          _admin!.profilePath!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 80),
                                        )
                                      : Image.file(
                                          File(_admin!.profilePath!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 80),
                                        ))
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
                              color: kAccentColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _admin?.nama ?? 'Admin',
                    style: kTitleStyle.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _admin?.role == 'super'
                          ? kAccentColor
                          : Colors.blueGrey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _admin?.role == 'super' ? 'SUPER ADMIN' : 'ADMIN STAFF',
                      style: kWhiteBoldStyle.copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            // ── Menu Super Admin ──────────────────────────────
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DaftarAdminPage()),
                ).then((_) => _fetchAdminData()),
              ),
              const Divider(),
            ],

            // ── Info ──────────────────────────────────────────
            ListTile(
              leading: const Icon(Icons.badge, color: kPrimaryColor),
              title: const Text("Username"),
              subtitle: Text(_admin?.username ?? "-"),
              trailing: IconButton(
                icon: const Icon(Icons.edit_note, color: kPrimaryColor),
                onPressed: _showEditSelfDialog,
              ),
            ),
            const SizedBox(height: 80),

            // ── Tombol Logout ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Konfirmasi Logout"),
                        ],
                      ),
                      content: const Text("Apakah Anda yakin ingin keluar?"),
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
                          onPressed: () async {
                            await PreferenceHandler.clearAll();
                            if (!mounted) return;
                            Navigator.pop(context);
                            context.pushAndRemoveAll(const Login());
                          },
                          child: const Text("Keluar"),
                        ),
                      ],
                    ),
                  ),
                  style: kDangerButtonStyle(radius: 16),
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
