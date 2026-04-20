import 'dart:io';
import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/user.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/extension/navigator.dart';
import 'package:match_discovery/login/login.dart';
import 'package:match_discovery/login/login1.dart';
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
  bool _isGuest   = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final role = await PreferenceHandler.getRole();

    if (role == 'guest' || role == null) {
      if (!mounted) return;
      setState(() { _isGuest = true; _isLoading = false; });
      return;
    }

    final id = await PreferenceHandler.getUserId();
    if (id == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      final data = await UserController.getUserById(id);
      if (!mounted) return;
      setState(() { _user = data; _isGuest = false; _isLoading = false; });
    } catch (e) {
      debugPrint('Error fetchUserData: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && _user != null) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      Map<String, dynamic> result = await UserController.updateUserProfile(_user!.id!, image.path);
      
      if (mounted) Navigator.pop(context);

      if (result['success'] == true) {
        await _fetchUserData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal memperbarui foto profil.'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
              Flexible(child: Text("Edit Profil",
                  style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: namaCtrl,
                  decoration: decorationConstant(hintText: 'Nama Lengkap', labelText: 'Nama', prefixIcon: Icons.person_outline)),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                readOnly: true,
                style: const TextStyle(color: Colors.grey),
                decoration: decorationConstant(
                  hintText: 'Email',
                  labelText: 'Email (Tidak dapat diubah)',
                  prefixIcon: Icons.email_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextField(controller: telpCtrl, keyboardType: TextInputType.phone,
                  decoration: decorationConstant(hintText: 'No. Telepon', labelText: 'Telepon', prefixIcon: Icons.phone_outlined)),
              const SizedBox(height: 12),
              TextField(controller: kotaCtrl,
                  decoration: decorationConstant(hintText: 'Asal Kota', labelText: 'Kota', prefixIcon: Icons.location_city_outlined)),
              const SizedBox(height: 12),
              TextField(controller: sekolahCtrl,
                  decoration: decorationConstant(hintText: 'Asal Sekolah/Univ', labelText: 'Sekolah', prefixIcon: Icons.school_outlined)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: listPendidikan.contains(selectedPendidikan) ? selectedPendidikan : null,
                decoration: decorationConstant(hintText: 'Pilih pendidikan', labelText: 'Pendidikan Terakhir', prefixIcon: Icons.history_edu_outlined),
                borderRadius: BorderRadius.circular(16),
                items: listPendidikan.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setStateDialog(() => selectedPendidikan = val),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Batal", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: kPrimaryButtonStyle(radius: 12),
              onPressed: () async {
                await UserController.updateUserDetail(
                  id: _user!.id!, nama: namaCtrl.text, email: emailCtrl.text,
                  tlpon: telpCtrl.text, asalKota: kotaCtrl.text,
                  pendidikanTerakhir: selectedPendidikan ?? "", asalSekolah: sekolahCtrl.text,
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                await _fetchUserData();
                if (!mounted) return;
                ScaffoldMessenger.of(outerContext).showSnackBar(
                    const SnackBar(content: Text("Profil diperbarui!")));
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

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
            Flexible(child: Text("Konfirmasi Keluar",
                style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: const Text("Apakah kamu yakin ingin keluar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: kDangerButtonStyle(),
            onPressed: () async {
              await PreferenceHandler.clearAll();
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
                  child: _isGuest ? _buildGuestView() : _buildUserView(),
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
            // Background Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [kPrimaryColor, kPrimaryLight],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
            // User Profile Info
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Hero(
                  tag: 'profile_pic',
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: ClipOval(
                          child: _user?.profilePath != null && _user!.profilePath!.isNotEmpty
                              ? (_user!.profilePath!.startsWith('data:image')
                                  ? Image.memory(base64Decode(_user!.profilePath!.split(',').last), fit: BoxFit.cover)
                                  : Image.file(File(_user!.profilePath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 80, color: kPrimaryColor)))
                              : const Icon(Icons.person, size: 80, color: kPrimaryColor),
                        ),
                      ),
                      if (!_isGuest)
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
                Text(
                  _isGuest ? 'Halo, Tamu!' : (_user?.nama ?? 'User'),
                  style: kWhiteBoldStyle.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    _isGuest ? "Guest Access" : "Peserta Kompetisi",
                    style: kWhiteSubStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        children: [
          const SizedBox(height: 20),
          FadeInUp(
            child: Text(
              'Masuk untuk mengelola profil dan melihat riwayat kompetisi kamu.',
              style: kSubtitleStyle.copyWith(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          BounceInUp(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pushAndRemoveAll(Login1()),
                style: kPrimaryButtonStyle(radius: 20),
                child: const Text('Login Sekarang'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Informasi Pribadi", style: kTitleStyle.copyWith(fontSize: 16)),
          const SizedBox(height: 16),
          FadeInLeft(delay: const Duration(milliseconds: 100), child: _buildInfoTile(Icons.alternate_email_rounded, "Email", _user?.email)),
          FadeInLeft(delay: const Duration(milliseconds: 200), child: _buildInfoTile(Icons.phone_iphone_rounded, "Telepon", _user?.tlpon)),
          FadeInLeft(delay: const Duration(milliseconds: 300), child: _buildInfoTile(Icons.location_on_rounded, "Asal Kota", _user?.asalKota)),
          FadeInLeft(delay: const Duration(milliseconds: 400), child: _buildInfoTile(Icons.school_rounded, "Asal Sekolah", _user?.asalSekolah)),
          FadeInLeft(delay: const Duration(milliseconds: 500), child: _buildInfoTile(Icons.history_edu_rounded, "Pendidikan", _user?.pendidikanTerakhir)),
          
          const SizedBox(height: 32),
          
          BounceInUp(
            delay: const Duration(milliseconds: 600),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showEditProfileDialog,
                icon: const Icon(Icons.edit_rounded, size: 20),
                label: const Text("Edit Profil"),
                style: kPrimaryButtonStyle(radius: 18),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeInUp(
            delay: const Duration(milliseconds: 700),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showLogoutDialog,
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text("Keluar"),
                style: kSecondaryButtonStyle(radius: 18).copyWith(
                  foregroundColor: WidgetStateProperty.all(Colors.red),
                  side: WidgetStateProperty.all(const BorderSide(color: Colors.red, width: 1.5)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String? value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: kCardDecoration(radius: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: kPrimaryColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: kPrimaryColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: kSubtitleStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  (value == null || value.isEmpty) ? "-" : value,
                  style: kBodyStyle.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}