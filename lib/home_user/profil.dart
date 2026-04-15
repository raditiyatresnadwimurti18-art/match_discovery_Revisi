import 'dart:io';
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
              Flexible(child: Text("Edit Profil",
                  style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: namaCtrl,
                  decoration: decorationConstant(hintText: 'Nama Lengkap', labelText: 'Nama', prefixIcon: Icons.person_outline)),
              const SizedBox(height: 12),
              TextField(controller: emailCtrl,
                  decoration: decorationConstant(hintText: 'Email', labelText: 'Email', prefixIcon: Icons.email_outlined)),
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

  // ──────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : _isGuest
              ? _buildGuestView()
              : _buildUserView(),
    );
  }

  // ── Tampilan tamu ──────────────────────────────
  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Ikon — zoom in
            ZoomIn(
              duration: const Duration(milliseconds: 600),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_off_outlined,
                    size: 72, color: kPrimaryColor),
              ),
            ),
            const SizedBox(height: 24),

            // ✅ Teks — fade in dari bawah
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: const Text('Kamu Belum Login',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor)),
            ),
            const SizedBox(height: 8),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: const Text(
                'Login untuk mengakses profil, riwayat lomba, dan fitur lengkap lainnya.',
                style: kSubtitleStyle,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),

            // ✅ Tombol — bounce in
            BounceInUp(
              delay: const Duration(milliseconds: 500),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => context.pushAndRemoveAll(Login1()),
                  style: kPrimaryButtonStyle(),
                  icon: const Icon(Icons.login),
                  label: const Text('Login Sekarang'),
                ),
              ),
            ),
            const SizedBox(height: 12),

            FadeInUp(
              delay: const Duration(milliseconds: 650),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => context.pushAndRemoveAll(const Login()),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kPrimaryColor),
                    foregroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius - 2)),
                  ),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Kembali ke Beranda'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tampilan user login ────────────────────────
  Widget _buildUserView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ✅ Header — slide dari atas
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: _buildHeader(),
          ),
          const SizedBox(height: 12),

          // ✅ Info tiles — fade in dari kiri bertahap
          FadeInLeft(delay: const Duration(milliseconds: 200),
              child: _buildInfoTile(Icons.email_outlined, "Email", _user?.email)),
          FadeInLeft(delay: const Duration(milliseconds: 300),
              child: _buildInfoTile(Icons.phone_outlined, "Telepon", _user?.tlpon)),
          FadeInLeft(delay: const Duration(milliseconds: 400),
              child: _buildInfoTile(Icons.location_city_outlined, "Asal Kota", _user?.asalKota)),
          FadeInLeft(delay: const Duration(milliseconds: 500),
              child: _buildInfoTile(Icons.school_outlined, "Asal Sekolah", _user?.asalSekolah)),
          FadeInLeft(delay: const Duration(milliseconds: 600),
              child: _buildInfoTile(Icons.history_edu_outlined, "Pendidikan", _user?.pendidikanTerakhir)),

          const SizedBox(height: 20),

          // ✅ Tombol — bounce in dari bawah
          BounceInUp(
            delay: const Duration(milliseconds: 600),
            child: _buildEditButton(),
          ),
          FadeInUp(
            delay: const Duration(milliseconds: 700),
            child: _buildLogoutButton(),
          ),
          const SizedBox(height: 40),
        ],
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
          // ✅ Foto profil — zoom in
          ZoomIn(
            duration: const Duration(milliseconds: 500),
            child: Stack(
              children: [
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kAccentColor, width: 3.5),
                  ),
                  child: ClipOval(
                    child: _user?.profilePath != null && _user!.profilePath!.isNotEmpty
                        ? (_user!.profilePath!.startsWith('http')
                            ? Image.network(
                                _user!.profilePath!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 60, color: kPrimaryColor),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(child: CircularProgressIndicator());
                                },
                              )
                            : _user!.profilePath!.startsWith('assets/')
                                ? Image.asset(
                                    _user!.profilePath!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 60, color: kPrimaryColor),
                                  )
                                : Image.file(
                                    File(_user!.profilePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 60, color: kPrimaryColor),
                                  ))
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
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ✅ Nama — fade in
          FadeIn(
            delay: const Duration(milliseconds: 300),
            child: Text(_user?.nama ?? 'Memuat...',
                style: kTitleStyle.copyWith(fontSize: 20)),
          ),
          FadeIn(
            delay: const Duration(milliseconds: 400),
            child: const Text("Peserta Lomba", style: kSubtitleStyle),
          ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    ),
  );
}