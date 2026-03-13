import 'dart:io';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/user.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/extension/navigator.dart';
import 'package:match_discovery/login/login.dart';
import 'package:match_discovery/models/login_model.dart';
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
    if (id != null) {
      LoginModel? data = await UserController.getUserById(id);
      setState(() {
        _user = data;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && _user != null) {
      await UserController.updateUserProfile(_user!.id!, image.path);
      _fetchUserData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil diperbarui')),
      );
    }
  }

  // Fungsi Dialog Edit Profil User
  void _showEditProfileDialog() {
    if (_user == null) return;

    final namaController = TextEditingController(text: _user!.nama);
    final emailController = TextEditingController(text: _user!.email);
    final telpController = TextEditingController(text: _user!.tlpon);
    final kotaController = TextEditingController(text: _user!.asalKota);
    final sekolahController = TextEditingController(text: _user!.asalSekolah);
    String? selectedPendidikan = _user!.pendidikanTerakhir;

    final List<String> listPendidikan = ['SMP', 'SMA/SMK', 'D3', 'S1', 'S2'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Edit Profil"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(namaController, "Nama Lengkap", Icons.person),
                _buildTextField(emailController, "Email", Icons.email),
                _buildTextField(telpController, "No. Telepon", Icons.phone),
                _buildTextField(
                  kotaController,
                  "Asal Kota",
                  Icons.location_city,
                ),
                _buildTextField(
                  sekolahController,
                  "Asal Sekolah/Univ",
                  Icons.school,
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: listPendidikan.contains(selectedPendidikan)
                      ? selectedPendidikan
                      : null,
                  decoration: const InputDecoration(
                    labelText: "Pendidikan Terakhir",
                    icon: Icon(Icons.history_edu),
                  ),
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
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                await UserController.updateUserDetail(
                  id: _user!.id!,
                  nama: namaController.text,
                  email: emailController.text,
                  tlpon: telpController.text,
                  asalKota: kotaController.text,
                  pendidikanTerakhir: selectedPendidikan ?? "",
                  asalSekolah: sekolahController.text,
                );
                if (!mounted) return;
                Navigator.pop(context);
                _fetchUserData();
                ScaffoldMessenger.of(context).showSnackBar(
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, icon: Icon(icon)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xff0f2a55),
        title: const Text('Profil Saya', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Profile
            _buildHeader(),
            const SizedBox(height: 20),

            // Detail Information
            _buildInfoTile(Icons.email, "Email", _user?.email),
            _buildInfoTile(Icons.phone, "Telepon", _user?.tlpon),
            _buildInfoTile(Icons.location_city, "Asal Kota", _user?.asalKota),
            _buildInfoTile(Icons.school, "Asal Sekolah", _user?.asalSekolah),
            _buildInfoTile(
              Icons.history_edu,
              "Pendidikan",
              _user?.pendidikanTerakhir,
            ),

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
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.fromARGB(255, 61, 77, 104), Colors.white],
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xff0f2a55),
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      _user?.profilePath != null &&
                          _user!.profilePath!.isNotEmpty
                      ? FileImage(File(_user!.profilePath!))
                      : null,
                  child:
                      _user?.profilePath == null || _user!.profilePath!.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 60,
                          color: Color(0xff0f2a55),
                        )
                      : null,
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
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            _user?.nama ?? 'Memuat...',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Peserta Lomba",
            style: TextStyle(color: Colors.blueGrey, letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String? value) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xff0f2a55)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      subtitle: Text(
        value == null || value.isEmpty ? "-" : value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildEditButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showEditProfileDialog,
          icon: const Icon(Icons.edit),
          label: const Text("Edit Profil"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showLogoutDialog(),
          icon: const Icon(Icons.logout),
          label: const Text("Keluar"),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await PreferenceHandler.deleteIsLogin();
              await PreferenceHandler.deleteId();
              if (!mounted) return;
              Navigator.pop(context);
              context.pushAndRemoveAll(const Login());
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
