import 'dart:io';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/user.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/home_user/profil.dart';
import 'package:match_discovery/home_user/event_berlalu.dart';
import 'package:match_discovery/home_user/history_user.dart';
import 'package:match_discovery/home_user/isi_home_user.dart';
import 'package:match_discovery/models/login_model.dart';
import 'package:match_discovery/util/app_theme.dart';

class HomeUser extends StatefulWidget {
  const HomeUser({super.key});

  @override
  State<HomeUser> createState() => _HomeUserState();
}

class _HomeUserState extends State<HomeUser> {
  static const List<Widget> _pages = <Widget>[
    IsiHomeUser(),
    HistoryUser(),
    EventBerlalu(),
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'label': 'Home',          'icon': Icons.home_rounded},
    {'label': 'History',       'icon': Icons.history_rounded},
    {'label': 'Event Terlewat','icon': Icons.event_rounded},
  ];

  int _selectIndex = 0;
  LoginModel? _user;

  String get _currentTitle => _menuItems[_selectIndex]['label'] as String;

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

  void _onMenuTap(int index) {
    setState(() => _selectIndex = index);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ✅ Tombol hamburger drawer
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
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfilUser()),
              ).then((_) => _fetchUserData()),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: _user?.profilePath != null &&
                          _user!.profilePath!.isNotEmpty
                      ? Image.file(
                          File(_user!.profilePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person, color: Colors.white),
                        )
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

      // ✅ Drawer
      drawer: Drawer(
        child: Column(
          children: [
            // Header drawer
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: kPrimaryColor),
              accountName: Text(
                _user?.nama ?? 'Pengguna',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: Text(
                _user?.email ?? '-',
                style: const TextStyle(fontSize: 12),
              ),
              currentAccountPicture: ClipOval(
                child: _user?.profilePath != null &&
                        _user!.profilePath!.isNotEmpty
                    ? Image.file(
                        File(_user!.profilePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),

            // Menu items
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final bool isSelected = _selectIndex == index;
                  return Container(
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
                        color: isSelected ? kPrimaryColor : Colors.grey[600],
                      ),
                      title: Text(
                        _menuItems[index]['label'] as String,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? kPrimaryColor
                              : Colors.grey[800],
                        ),
                      ),
                      trailing: isSelected
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
                  );
                },
              ),
            ),
          ],
        ),
      ),

      body: _pages.elementAt(_selectIndex),
    );
  }
}