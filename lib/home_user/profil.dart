import 'dart:io';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/user.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/extension/navigator.dart';
import 'package:match_discovery/login/login.dart';
import 'package:match_discovery/models/login_model.dart';
import 'package:match_discovery/util/app_theme.dart';
import 'package:match_discovery/util/decoration_form.dart';
import 'package:image_picker/image_picker.dart';

class ProfilUser extends StatefulWidget {
  const ProfilUser({super.key});

  @override
  State<ProfilUser> createState() => _ProfilUserState();
}

class _ProfilUserState extends State<ProfilUser> {
  final ImagePicker _picker = ImagePicker();
  LoginModel? _user;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    int? id = await PreferenceHandler.getId();
    if (id == null) return;
    try {
      LoginModel? data = await UserController.getUserById(id);
      if (!mounted) return;
      setState(() => _user = data);
    } catch (e) {
      debugPrint('Error fetchUserData: $e');
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && _user != null) {
      await UserController.updateUserProfile(_user!.id!, image.path);
      await _fetchUserData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil diperbarui')),
      );
    }
  }

  void _showEditProfileDialog() {
    if (_user == null) return;

    final namaCtrl    = TextEditingController(text: _user!.nama);
    final emailCtrl   = TextEditingController(text: _user!.email);
    final telpCtrl    = TextEditingController(text: _user!.tlpon);
    final kotaCtrl    = TextEditingController(text: _user!.asalKota);
    final sekolahCtrl = TextEditingController(text: _user!.asalSekolah);
    String? selectedPendidikan = _user!.pendidikanTerakhir;
    const listPendidikan = ['SMP', 'SMA/SMK', 'D3', 'S1', 'S2'];
    final outerContext = context;

    showDialog(
      context: outerContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit, color: kPrimaryColor),
              SizedBox(width: 8),
              Flexible(
                child: Text("Edit Profil",
                    style: TextStyle(
                        color: kPrimaryColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: namaCtrl,
                    decoration: decorationConstant(hintText: 'Nama Lengkap', labelText: 'Nama', prefixIcon: Icons.person_outline)),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl,
                    decoration: decorationConstant(hintText: 'Email', labelText: 'Email', prefixIcon: Icons.email_outlined)),
                const SizedBox(height: 12),
                TextField(controller: telpCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: decorationConstant(hintText: 'No. Telepon', labelText: 'Telepon', prefixIcon: Icons.phone_outlined)),
                const SizedBox(height: 12),
                TextField(controller: kotaCtrl,
                    decoration: decorationConstant(hintText: 'Asal Kota', labelText: 'Kota', prefixIcon: Icons.location_city_outlined)),
                const SizedBox(height: 12),
                TextField(controller: sekolahCtrl,
                    decoration: decorationConstant(hintText: 'Asal Sekolah/Univ', labelText: 'Sekolah', prefixIcon: Icons.school_outlined)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: listPendidikan.contains(selectedPendidikan)
                      ? selectedPendidikan
                      : null,
                  decoration: decorationConstant(
                    hintText: 'Pilih pendidikan',
                    labelText: 'Pendidikan Terakhir',
                    prefixIcon: Icons.history_edu_outlined,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  items: listPendidikan
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) =>
                      setStateDialog(() => selectedPendidikan = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: kPrimaryButtonStyle(radius: 12),
              onPressed: () async {
                await UserController.updateUserDetail(
                  id: _user!.id!,
                  nama: namaCtrl.text,
                  email: emailCtrl.text,
                  tlpon: telpCtrl.text,
                  asalKota: kotaCtrl.text,
                  pendidikanTerakhir: selectedPendidikan ?? "",
                  asalSekolah: sekolahCtrl.text,
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                await _fetchUserData();
                if (!mounted) return;
                ScaffoldMessenger.of(outerContext).showSnackBar(
                  const SnackBar(content: Text("Profil diperbarui!")),
                );
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
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text('Profil Saya', style: kWhiteBoldStyle),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildInfoTile(Icons.email_outlined,         "Email",       _user?.email),
            _buildInfoTile(Icons.phone_outlined,         "Telepon",     _user?.tlpon),
            _buildInfoTile(Icons.location_city_outlined, "Asal Kota",   _user?.asalKota),
            _buildInfoTile(Icons.school_outlined,        "Asal Sekolah",_user?.asalSekolah),
            _buildInfoTile(Icons.history_edu_outlined,   "Pendidikan",  _user?.pendidikanTerakhir),
            const SizedBox(height: 20),
            _buildEditButton(),
            _buildLogoutButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kPrimaryColor, kBgColor],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 28),
          Stack(
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kAccentColor, width: 3.5),
                ),
                child: ClipOval(
                  child: _user?.profilePath != null &&
                          _user!.profilePath!.isNotEmpty
                      ? Image.file(File(_user!.profilePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.person, size: 60, color: kPrimaryColor))
                      : const Icon(Icons.person, size: 60, color: kPrimaryColor),
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                        color: kAccentColor, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_user?.nama ?? 'Memuat...',
              style: kTitleStyle.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          const Text("Peserta Lomba", style: kSubtitleStyle),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String? value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: kCardDecoration(),
      child: ListTile(
        leading: Icon(icon, color: kPrimaryColor),
        title: Text(title, style: kSubtitleStyle.copyWith(fontSize: 12)),
        subtitle: Text(
          (value == null || value.isEmpty) ? "-" : value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildEditButton() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: SizedBox(
          width: double.infinity, height: 48,
          child: ElevatedButton.icon(
            onPressed: _showEditProfileDialog,
            icon: const Icon(Icons.edit),
            label: const Text("Edit Profil"),
            style: kPrimaryButtonStyle(),
          ),
        ),
      );

  Widget _buildLogoutButton() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: SizedBox(
          width: double.infinity, height: 48,
          child: OutlinedButton.icon(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout),
            label: const Text("Keluar"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      );

  void _showLogoutDialog() {
    final outerContext = context;
    showDialog(
      context: outerContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Flexible(
              child: Text("Konfirmasi Keluar",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: const Text("Apakah kamu yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: kDangerButtonStyle(),
            onPressed: () async {
              await PreferenceHandler.deleteIsLogin();
              await PreferenceHandler.deleteId();
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (!mounted) return;
              outerContext.pushAndRemoveAll(const Login());
            },
            child: const Text("Keluar"),
          ),
        ],
      ),
    );
  }
}