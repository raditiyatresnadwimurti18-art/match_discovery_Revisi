import 'dart:io';
import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:match_discovery/database/controllers/user.dart';
import 'package:match_discovery/database/controllers/social.dart';
import 'package:match_discovery/database/controllers/riwayat.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/home_user/social/social_relation_page.dart';
import 'package:match_discovery/home_user/social/user_list_widget.dart';
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
  String? _myId;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final role = await PreferenceHandler.getRole();

    if (role == 'guest' || role == null) {
      if (!mounted) return;
      setState(() { _isGuest = true; _isLoading = false; });
      return;
    }

    final id = await PreferenceHandler.getUserId();
    _myId = id;
    if (id == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      final data = await UserController.getUserById(id);
      if (!mounted) return;
      setState(() { 
        _user = data; 
        _isGuest = false; 
        _isLoading = false; 
      });
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
        await _fetchInitialData();
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
                await _fetchInitialData();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: kPrimaryColor)));
    if (_isGuest) return _buildGuestView();

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: kModernAppBar(
        title: "Profil Saya",
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),
            _buildRealtimeStats(),
            const SizedBox(height: 24),
            _buildSectionHeader("Informasi Pribadi", Icons.person_outline_rounded),
            const SizedBox(height: 12),
            _buildInfoTile(Icons.alternate_email_rounded, "Email", _user?.email),
            _buildInfoTile(Icons.phone_iphone_rounded, "Telepon", _user?.tlpon),
            _buildInfoTile(Icons.location_on_rounded, "Asal Kota", _user?.asalKota),
            _buildInfoTile(Icons.school_rounded, "Pendidikan", "${_user?.pendidikanTerakhir ?? '-'} - ${_user?.asalSekolah ?? '-'}"),
            
            const SizedBox(height: 24),
            _buildSectionHeader("Riwayat Kompetisi", Icons.history_rounded),
            const SizedBox(height: 12),
            _buildRealtimeTrackRecord(),
            
            const SizedBox(height: 32),
            _buildActionButtons(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle),
                child: ClipOval(
                  child: Container(
                    color: Colors.white,
                    child: _user?.profilePath != null && _user!.profilePath!.isNotEmpty
                        ? (_user!.profilePath!.startsWith('data:image')
                            ? Image.memory(base64Decode(_user!.profilePath!.split(',').last), fit: BoxFit.cover)
                            : Image.file(File(_user!.profilePath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50, color: kPrimaryColor)))
                        : const Icon(Icons.person, size: 50, color: kPrimaryColor),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: kSecondaryColor, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _user?.nama ?? 'User',
            style: GoogleFonts.plusJakartaSans(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          Text(
            _user?.email ?? '',
            style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeStats() {
    return StreamBuilder<int>(
      stream: RiwayatController.getTotalSelesaiUserStream(_myId!),
      builder: (context, lombaSnap) {
        return StreamBuilder<int>(
          stream: SocialController.getFollowersCountStream(_myId!),
          builder: (context, followersSnap) {
            return StreamBuilder<int>(
              stream: SocialController.getFollowingCountStream(_myId!),
              builder: (context, followingSnap) {
                return Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem("Lomba", (lombaSnap.data ?? 0).toString(), null),
                        _buildStatDivider(),
                        _buildStatItem("Pengikut", (followersSnap.data ?? 0).toString(), 0),
                        _buildStatDivider(),
                        _buildStatItem("Mengikuti", (followingSnap.data ?? 0).toString(), 1),
                      ],
                    ),
                  ),
                );
              }
            );
          }
        );
      }
    );
  }

  Widget _buildStatItem(String label, String value, int? tabIndex) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: tabIndex == null ? null : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SocialRelationPage(userId: _user!.id!, initialIndex: tabIndex),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: kPrimaryColor)),
                Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 30, width: 1, color: Colors.grey.shade200);
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kPrimaryColor),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String? value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                Text(value ?? '-', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeTrackRecord() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: RiwayatController.getTrackRecordUserStream(_myId!),
      builder: (context, snapshot) {
        final trackRecord = snapshot.data ?? [];
        if (trackRecord.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
            child: const Center(child: Text("Belum ada riwayat kompetisi", style: TextStyle(fontSize: 12, color: Colors.grey))),
          );
        }
        return Column(
          children: trackRecord.take(3).map((item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.05), shape: BoxShape.circle),
                  child: const Icon(Icons.emoji_events_rounded, color: Colors.orange, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['judulLomba'], style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text("Diikuti ${item['jumlahIkut']} kali", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                Text(item['terakhirIkut'], style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          )).toList(),
        );
      }
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showEditProfileDialog,
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text("Edit Profil & Pengaturan"),
            style: kPrimaryButtonStyle(radius: 16),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () async {
              await PreferenceHandler.clearAll();
              if (!mounted) return;
              context.pushAndRemoveAll(const Login());
            },
            icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.red),
            label: const Text("Keluar Akun", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestView() {
    return Scaffold(
      appBar: kModernAppBar(title: "Profil"),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("Login untuk melihat profil lengkap", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pushAndRemoveAll(const Login1()),
              style: kPrimaryButtonStyle(radius: 12),
              child: const Text("Login Sekarang"),
            ),
          ],
        ),
      ),
    );
  }
}
