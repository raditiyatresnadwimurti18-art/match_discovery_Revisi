import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/admin.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/extension/navigator.dart';
import 'package:match_discovery/home_admin/daftar_admin-user.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    String? id = await PreferenceHandler.getAdminId();
    if (id == null) {
       if (mounted) setState(() => _isLoading = false);
       return;
    }

    try {
      AdminModel? data = await AdminController.getAdminById(id);
      if (!mounted) return;
      setState(() {
        _admin = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetchAdminData: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && _admin != null) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      AdminModel updated = AdminModel(
        id: _admin!.id,
        username: _admin!.username,
        password: _admin!.password,
        nama: _admin!.nama,
        profilePath: image.path,
        role: _admin!.role,
      );
      bool success = await AdminController.updateAdminProfile(updated);

      if (mounted) Navigator.pop(context);

      if (success) {
        await _fetchAdminData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil admin berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui foto profil admin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddAdminDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_add, color: kPrimaryColor),
            SizedBox(width: 8),
            Flexible(child: Text("Tambah Admin Baru", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Daftarkan email dan password staff.", style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: decorationConstant(hintText: 'Email untuk Login', labelText: 'Email', prefixIcon: Icons.email_outlined),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: decorationConstant(hintText: 'Password', labelText: 'Password', prefixIcon: Icons.lock_outline),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: kPrimaryButtonStyle(radius: 12),
            onPressed: () async {
              if (emailCtrl.text.isNotEmpty && passCtrl.text.isNotEmpty) {
                showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
                String tempUsername = emailCtrl.text.split('@').first;
                var result = await AdminController.addAdmin(
                  AdminModel(nama: 'Admin Baru', username: tempUsername, email: emailCtrl.text, password: passCtrl.text, role: 'admin', profilePath: ''),
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                if (result == "success") {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Akses Admin berhasil didaftarkan!"), backgroundColor: Colors.green));
                  await _fetchAdminData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal mendaftar"), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text("Daftarkan"),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit, color: kPrimaryColor),
              SizedBox(width: 8),
              Text("Edit Profil Saya", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: decorationConstant(hintText: 'Nama Lengkap', labelText: 'Nama', prefixIcon: Icons.person_outline)),
                const SizedBox(height: 12),
                TextField(controller: userCtrl, decoration: decorationConstant(hintText: 'Username', labelText: 'Username', prefixIcon: Icons.alternate_email)),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: !isPasswordVisible,
                  decoration: decorationConstant(hintText: 'Password Baru', labelText: 'Password', prefixIcon: Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                      onPressed: () => setStateDialog(() => isPasswordVisible = !isPasswordVisible),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: kPrimaryButtonStyle(radius: 12),
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty && userCtrl.text.isNotEmpty && passCtrl.text.isNotEmpty) {
                  await AdminController.updateAdminDetail(_admin!.id!, nameCtrl.text, userCtrl.text, passCtrl.text);
                  if (!mounted) return;
                  Navigator.pop(context);
                  await _fetchAdminData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil berhasil diperbarui!")));
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: _buildAdminContent(),
                ),
              ],
            ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: kPrimaryColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [kPrimaryColor, kPrimaryLight]),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Hero(
                  tag: 'admin_profile',
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: ClipOval(
                          child: _admin?.role == 'super'
                              ? Image.asset('assets/images/logo.png', fit: BoxFit.cover)
                              : (_admin?.profilePath != null && _admin!.profilePath!.isNotEmpty
                                  ? (_admin!.profilePath!.startsWith('data:image')
                                      ? Image.memory(base64Decode(_admin!.profilePath!.split(',').last), fit: BoxFit.cover)
                                      : Image.file(File(_admin!.profilePath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 80, color: kPrimaryColor)))
                                  : const Icon(Icons.person, size: 80, color: kPrimaryColor)),
                        ),
                      ),
                      if (_admin?.role != 'super')
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: kSecondaryColor, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(_admin?.nama ?? 'Admin', style: kWhiteBoldStyle.copyWith(fontSize: 22)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: _admin?.role == 'super' ? kSecondaryColor : Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: Text(_admin?.role == 'super' ? 'SUPER ADMIN' : 'ADMIN STAFF', style: kWhiteBoldStyle.copyWith(fontSize: 11, letterSpacing: 1)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_admin?.role == 'super') ...[
            Text("Manajemen Staff", style: kTitleStyle.copyWith(fontSize: 16)),
            const SizedBox(height: 16),
            _buildAdminMenuTile(icon: Icons.person_add_alt_1_rounded, color: Colors.blue, title: "Tambah Admin Baru", subtitle: "Buat akun akses untuk staff admin", onTap: () => _showAddAdminDialog(context)),
            const SizedBox(height: 12),
            _buildAdminMenuTile(icon: Icons.manage_accounts_rounded, color: Colors.teal, title: "Kelola Daftar Admin", subtitle: "Lihat dan hapus staff admin", onTap: () => Navigator.push(context, PageTransition(child: const DaftarAdminPage())).then((_) => _fetchAdminData())),
            const SizedBox(height: 24),
          ],
          Text("Informasi Akun", style: kTitleStyle.copyWith(fontSize: 16)),
          const SizedBox(height: 16),
          _buildInfoTile(icon: Icons.badge_rounded, title: "Username", value: _admin?.username ?? "-", trailing: _admin?.role == 'super' ? null : IconButton(icon: const Icon(Icons.edit_note_rounded, color: kPrimaryColor), onPressed: _showEditSelfDialog)),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showLogoutConfirm,
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text("Keluar"),
              style: kSecondaryButtonStyle(radius: 18).copyWith(foregroundColor: MaterialStateProperty.all(Colors.red), side: MaterialStateProperty.all(const BorderSide(color: Colors.red, width: 1.5))),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAdminMenuTile({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      decoration: kCardDecoration(radius: 18),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 24)),
        title: Text(title, style: kTitleStyle.copyWith(fontSize: 15)),
        subtitle: Text(subtitle, style: kSubtitleStyle.copyWith(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String title, required String value, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: kCardDecoration(radius: 18),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: kPrimaryColor, size: 22)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: kSubtitleStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text(value, style: kBodyStyle.copyWith(fontWeight: FontWeight.w600, fontSize: 15))])),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(children: [Icon(Icons.logout_rounded, color: Colors.red), SizedBox(width: 12), Text("Logout Akun")]),
        content: const Text("Apakah Anda yakin ingin keluar dari sistem?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(style: kDangerButtonStyle(), onPressed: () async { await PreferenceHandler.clearAll(); if (!mounted) return; Navigator.pop(context); context.pushAndRemoveAll(const Login()); }, child: const Text("Keluar")),
        ],
      ),
    );
  }
}