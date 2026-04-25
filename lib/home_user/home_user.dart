import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:match_discovery/database/controllers/user.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/extension/navigator.dart';
import 'package:match_discovery/home_user/profil.dart';
import 'package:match_discovery/home_user/event_berlalu.dart';
import 'package:match_discovery/home_user/history_user.dart';
import 'package:match_discovery/home_user/isi_home_user.dart';
import 'package:match_discovery/home_user/daftar_kelompok_saya.dart';
import 'package:match_discovery/login/login1.dart';
import 'package:match_discovery/models/login_model.dart';
import 'package:match_discovery/util/app_theme.dart';

class HomeUser extends StatefulWidget {
  const HomeUser({super.key});

  @override
  State<HomeUser> createState() => _HomeUserState();
}

class _HomeUserState extends State<HomeUser> {
  final List<Widget> _pages = const [
    IsiHomeUser(),
    HistoryUser(),
    EventBerlalu(),
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'label': 'Home',          'icon': Icons.home_rounded,    'guestAllowed': true },
    {'label': 'History',       'icon': Icons.history_rounded, 'guestAllowed': false},
    {'label': 'Event Terlewat','icon': Icons.event_rounded,   'guestAllowed': false},
    {'label': 'Kelompok Saya', 'icon': Icons.groups_rounded,  'guestAllowed': false, 'isNewPage': true},
  ];

  int _selectIndex = 0;
  LoginModel? _user;
  Uint8List? _profileBytes;
  bool _isGuest    = false;
  bool _pageLoaded = false;

  String get _currentTitle => _menuItems[_selectIndex]['label'] as String;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final role = await PreferenceHandler.getRole();

    if (role == 'guest' || role == null) {
      if (!mounted) return;
      setState(() {
        _isGuest    = true;
        _pageLoaded = true;
      });
      return;
    }

    final id = await PreferenceHandler.getUserId();
    if (id == null) return;
    try {
      final data = await UserController.getUserById(id);
      
      // Decode bytes once outside build
      Uint8List? bytes;
      if (data?.profilePath != null && data!.profilePath!.startsWith('data:image')) {
        try {
          bytes = base64Decode(data.profilePath!.split(',').last);
        } catch (e) {
          debugPrint("Error decoding profile image: $e");
        }
      }

      if (!mounted) return;
      setState(() {
        _user        = data;
        _profileBytes = bytes;
        _isGuest     = false;
        _pageLoaded  = true;
      });
    } catch (e) {
      debugPrint('Error fetchUserData: $e');
      if (!mounted) return;
      setState(() => _pageLoaded = true);
    }
  }

  void _onMenuTap(int index) {
    final bool guestAllowed = _menuItems[index]['guestAllowed'] as bool;
    final bool isNewPage    = _menuItems[index]['isNewPage'] ?? false;

    if (_isGuest && !guestAllowed) {
      Navigator.pop(context);
      _showLoginRequiredDialog();
      return;
    }

    if (isNewPage) {
      Navigator.pop(context);
      if (_menuItems[index]['label'] == 'Kelompok Saya') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const DaftarKelompokSayaPage()));
      }
      return;
    }

    setState(() => _selectIndex = index);
    Navigator.pop(context);
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: kPrimaryColor),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Fitur Terbatas',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: kPrimaryColor),
              ),
            ),
          ],
        ),
        content: const Text(
          'Kamu perlu login untuk mengakses fitur ini.\n\n'
          'Login sekarang untuk menikmati semua fitur aplikasi.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Nanti Saja',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: kPrimaryButtonStyle(radius: 12),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.pushAndRemoveAll(Login1());
            },
            icon: const Icon(Icons.login, size: 16),
            label: const Text('Login Sekarang'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: kModernAppBar(
        title: _currentTitle,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                if (_isGuest) {
                  _showLoginRequiredDialog();
                  return;
                }
                Navigator.push(
                  context,
                  PageTransition(child: const ProfilUser()),
                ).then((_) => _fetchUserData());
              },
              child: Hero(
                tag: 'profile_pic',
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _isGuest
                        ? const Icon(Icons.person_outline, color: Colors.white)
                        : _profileBytes != null
                            ? Image.memory(_profileBytes!, fit: BoxFit.cover)
                            : (_user?.profilePath != null && _user!.profilePath!.isNotEmpty && !_user!.profilePath!.startsWith('data:image'))
                                ? Image.file(
                                    File(_user!.profilePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                                  )
                                : const Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      drawer: Drawer(
        backgroundColor: kSurfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            _buildModernDrawerHeader(),

            if (_isGuest)
              FadeIn(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_rounded, color: Colors.amber.shade800, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Akses Terbatas',
                              style: kTitleStyle.copyWith(fontSize: 14, color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Login untuk melihat riwayat dan mengikuti event seru lainnya!',
                        style: kSubtitleStyle.copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: kPrimaryButtonStyle(radius: 12),
                          onPressed: () {
                            Navigator.pop(context);
                            context.pushAndRemoveAll(Login1());
                          },
                          child: const Text('Login Sekarang'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(thickness: 1),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final bool isSelected   = _selectIndex == index;
                  final bool guestAllowed = _menuItems[index]['guestAllowed'] as bool;
                  final bool isLocked     = _isGuest && !guestAllowed;

                  return FadeInLeft(
                    delay: Duration(milliseconds: 100 + (index * 50)),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? kPrimaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: kPrimaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ] : null,
                      ),
                      child: ListTile(
                        onTap: () => _onMenuTap(index),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        leading: Icon(
                          _menuItems[index]['icon'] as IconData,
                          color: isSelected ? Colors.white : (isLocked ? Colors.grey.shade400 : kPrimaryColor),
                        ),
                        title: Text(
                          _menuItems[index]['label'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : (isLocked ? Colors.grey.shade400 : Colors.black87),
                          ),
                        ),
                        trailing: isLocked 
                          ? Icon(Icons.lock_outline_rounded, size: 18, color: Colors.grey.shade400)
                          : isSelected 
                            ? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      body: _pageLoaded
          ? AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: animation.drive(Tween(begin: const Offset(0.05, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutQuart))),
                    child: child,
                  ),
                );
              },
              child: Container(
                key: ValueKey<int>(_selectIndex),
                child: _pages.elementAt(_selectIndex),
              ),
            )
          : const Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            ),
    );
  }

  Widget _buildModernDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: const BoxDecoration(
        gradient: kPrimaryGradient,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: kPrimaryLight,
              child: ClipOval(
                child: _isGuest
                    ? const Icon(Icons.person_outline, size: 40, color: Colors.white)
                    : _profileBytes != null
                        ? Image.memory(_profileBytes!, fit: BoxFit.cover, width: 70, height: 70)
                        : (_user?.profilePath != null && _user!.profilePath!.isNotEmpty && !_user!.profilePath!.startsWith('data:image'))
                            ? Image.file(
                                File(_user!.profilePath!),
                                fit: BoxFit.cover,
                                width: 70, height: 70,
                                errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40, color: Colors.white),
                              )
                            : const Icon(Icons.person, size: 40, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isGuest ? 'Halo, Tamu!' : (_user?.nama ?? 'Pengguna'),
            style: kWhiteBoldStyle.copyWith(fontSize: 20),
          ),
          Text(
            _isGuest ? 'Selamat Datang' : (_user?.email ?? '-'),
            style: kWhiteSubStyle,
          ),
        ],
      ),
    );
  }

}
