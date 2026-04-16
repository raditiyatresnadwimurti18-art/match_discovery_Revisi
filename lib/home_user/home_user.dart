import 'dart:io';
import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/user.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/extension/navigator.dart';
import 'package:match_discovery/home_user/profil.dart';
import 'package:match_discovery/home_user/event_berlalu.dart';
import 'package:match_discovery/home_user/history_user.dart';
import 'package:match_discovery/home_user/isi_home_user.dart';
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
  ];

  int _selectIndex = 0;
  LoginModel? _user;
  bool _isGuest    = false;
  bool _pageLoaded = false; // ✅ Trigger animasi hanya sekali

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
      if (!mounted) return;
      setState(() {
        _user       = data;
        _isGuest    = false;
        _pageLoaded = true;
      });
    } catch (e) {
      debugPrint('Error fetchUserData: $e');
      if (!mounted) return;
      setState(() => _pageLoaded = true);
    }
  }

  void _onMenuTap(int index) {
    final bool guestAllowed = _menuItems[index]['guestAllowed'] as bool;

    if (_isGuest && !guestAllowed) {
      Navigator.pop(context);
      _showLoginRequiredDialog();
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
      // ✅ AppBar — slide dari atas
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(_currentTitle, style: kWhiteBoldStyle),
        backgroundColor: kPrimaryColor,
        centerTitle: true,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                if (_isGuest) {
                  _showLoginRequiredDialog();
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfilUser()),
                ).then((_) => _fetchUserData());
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: _isGuest
                      ? const Icon(Icons.person_outline, color: Colors.white)
                      : _user?.profilePath != null && _user!.profilePath!.isNotEmpty
                          ? (_user!.profilePath!.startsWith('data:image')
                              ? Image.memory(
                                  base64Decode(_user!.profilePath!.split(',').last),
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_user!.profilePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                                ))
                          : const Icon(Icons.person, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.white24, height: 1),
        ),
      ),

      drawer: Drawer(
        child: Column(
          children: [
            // ✅ Header drawer — slide dari atas
            FadeInDown(
              duration: const Duration(milliseconds: 400),
              child: _isGuest
                  ? _buildGuestDrawerHeader()
                  : _buildUserDrawerHeader(),
            ),

            // ✅ Banner guest — fade in
            if (_isGuest)
              FadeIn(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Login untuk akses semua fitur',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ✅ Tombol login guest — bounce in
            if (_isGuest)
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: kPrimaryButtonStyle(radius: 10),
                      onPressed: () {
                        Navigator.pop(context);
                        context.pushAndRemoveAll(Login1());
                      },
                      icon: const Icon(Icons.login, size: 16),
                      label: const Text('Login Sekarang'),
                    ),
                  ),
                ),
              ),

            const Divider(height: 1),

            // ✅ Menu items — masing-masing FadeInLeft bertahap
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final bool isSelected   = _selectIndex == index;
                  final bool guestAllowed = _menuItems[index]['guestAllowed'] as bool;
                  final bool isLocked     = _isGuest && !guestAllowed;

                  return FadeInLeft(
                    delay: Duration(milliseconds: 200 + (index * 100)),
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? kPrimaryColor.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        leading: Icon(
                          _menuItems[index]['icon'] as IconData,
                          color: isLocked
                              ? Colors.grey.shade400
                              : isSelected
                                  ? kPrimaryColor
                                  : Colors.grey[600],
                        ),
                        title: Text(
                          _menuItems[index]['label'] as String,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isLocked
                                ? Colors.grey.shade400
                                : isSelected
                                    ? kPrimaryColor
                                    : Colors.grey[800],
                          ),
                        ),
                        trailing: isLocked
                            ? Icon(Icons.lock_outline,
                                size: 16, color: Colors.grey.shade400)
                            : isSelected
                                ? Container(
                                    width: 4,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: kPrimaryColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  )
                                : null,
                        onTap: () => _onMenuTap(index),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ✅ Body — FadeIn saat halaman pertama dimuat
      body: _pageLoaded
          ? FadeIn(
              duration: const Duration(milliseconds: 500),
              child: _pages.elementAt(_selectIndex),
            )
          : const Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            ),
    );
  }

  Widget _buildGuestDrawerHeader() {
    return UserAccountsDrawerHeader(
      decoration: const BoxDecoration(color: kPrimaryColor),
      accountName: const Text(
        'Tamu',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      accountEmail: const Text(
        'Masuk sebagai tamu — akses terbatas',
        style: TextStyle(fontSize: 11),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white.withOpacity(0.2),
        child: const Icon(Icons.person_outline, size: 40, color: Colors.white),
      ),
    );
  }

  Widget _buildUserDrawerHeader() {
    return UserAccountsDrawerHeader(
      decoration: const BoxDecoration(color: kPrimaryColor),
      accountName: Text(
        _user?.nama ?? 'Pengguna',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      accountEmail: Text(
        _user?.email ?? '-',
        style: const TextStyle(fontSize: 12),
      ),
      currentAccountPicture: ClipOval(
        child: _user?.profilePath != null && _user!.profilePath!.isNotEmpty
            ? (_user!.profilePath!.startsWith('data:image')
                ? Image.memory(
                    base64Decode(_user!.profilePath!.split(',').last),
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(_user!.profilePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50, color: Colors.white),
                  ))
            : const Icon(Icons.person, size: 50, color: Colors.white),
      ),
    );
  }
}