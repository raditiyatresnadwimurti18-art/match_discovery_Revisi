import 'package:flutter/material.dart';
import 'package:match_discovery/database/notification_service.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/home_user/profil.dart';
import 'package:match_discovery/home_user/isi_home_user.dart';
import 'package:match_discovery/home_user/daftar_kelompok_saya.dart';
import 'package:match_discovery/home_user/social/social_hub.dart';
import 'package:match_discovery/home_user/activity_hub.dart';
import 'package:match_discovery/util/app_theme.dart';

class HomeUser extends StatefulWidget {
  const HomeUser({super.key});

  @override
  State<HomeUser> createState() => _HomeUserState();
}

class _HomeUserState extends State<HomeUser> {
  int _selectedIndex = 0;
  bool _pageLoaded = false;

  final List<Widget> _pages = [
    const IsiHomeUser(),
    const SocialHubPage(),
    const DaftarKelompokSayaPage(),
    const ActivityHubPage(),
    const ProfilUser(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final role = PreferenceHandler.getRole();
    if (role == 'guest' || role == null) {
      if (!mounted) return;
      setState(() => _pageLoaded = true);
      return;
    }

    final id = PreferenceHandler.getUserId();
    if (id == null) {
      if (!mounted) return;
      setState(() => _pageLoaded = true);
      return;
    }
    
    try {
      // Pemicu notifikasi
      NotificationService.listenToUserNotifications(id);
      if (!mounted) return;
      setState(() => _pageLoaded = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _pageLoaded = true);
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: _pageLoaded
          ? IndexedStack(
              index: _selectedIndex,
              children: _pages,
            )
          : const Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              selectedItemColor: kPrimaryColor,
              unselectedItemColor: Colors.grey.shade400,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Sosial'),
                BottomNavigationBarItem(icon: Icon(Icons.groups_rounded), label: 'Kelompok'),
                BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Aktivitas'),
                BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
