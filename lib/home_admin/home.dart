import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/admin.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/home_admin/data_user_lomba.dart';
import 'package:match_discovery/home_admin/history_lomba.dart';
import 'package:match_discovery/home_admin/isihome.dart';
import 'package:match_discovery/home_admin/profil_admin.dart';
import 'package:match_discovery/home_admin/track_record_user.dart';
import 'package:match_discovery/models/admin_model.dart';
import 'package:match_discovery/util/app_theme.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectIndex = 0;
  AdminModel? _admin;

  // ✅ FIX: Inisialisasi langsung di deklarasi (bukan late)
  // 'late final' menyebabkan LateInitializationError jika build()
  // dipanggil sebelum initState selesai mengisinya.
  // Karena semua widget di sini adalah const, aman diinisialisasi langsung.
  final List<Widget> _pages = const [
    IsiHome(),
    DataUserLomba(),
    HistoryLomba(),
    TrackRecordUser(),
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'label': 'Home', 'icon': Icons.home_rounded},
    {'label': 'Data User', 'icon': Icons.verified_user_rounded},
    {'label': 'History Lomba', 'icon': Icons.history_rounded},
    {'label': 'Track Record', 'icon': Icons.workspace_premium_rounded},
  ];

  String get _currentTitle => _menuItems[_selectIndex]['label'] as String;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    // ✅ FIX: Gunakan getAdminId() bukan getId()
    final id = await PreferenceHandler.getAdminId();
    if (id == null) return;
    try {
      final data = await AdminController.getAdminById(id);
      if (!mounted) return;
      setState(() => _admin = data);
    } catch (e) {
      debugPrint('Error fetchAdminData home: $e');
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
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        backgroundColor: kPrimaryColor,
        title: Text(_currentTitle, style: kWhiteBoldStyle),
        centerTitle: true,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilAdmin()),
              ).then((_) => _fetchAdminData()),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: _admin?.profilePath != null && _admin!.profilePath!.isNotEmpty
                      ? (_admin!.profilePath!.startsWith('data:image')
                          ? Image.memory(
                              base64Decode(_admin!.profilePath!.split(',').last),
                              fit: BoxFit.cover,
                            )
                          : _admin!.profilePath!.startsWith('http')
                              ? Image.network(
                                  _admin!.profilePath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                                )
                              : Image.file(
                                  File(_admin!.profilePath!),
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
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: kPrimaryColor),
              accountName: Text(
                _admin?.nama ?? 'Admin',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              accountEmail: Text(
                _admin?.role == 'super' ? 'Super Admin' : 'Admin Staff',
                style: const TextStyle(fontSize: 12),
              ),
              currentAccountPicture: ClipOval(
                child: _admin?.profilePath != null && _admin!.profilePath!.isNotEmpty
                    ? (_admin!.profilePath!.startsWith('data:image')
                        ? Image.memory(
                            base64Decode(_admin!.profilePath!.split(',').last),
                            fit: BoxFit.cover,
                          )
                        : _admin!.profilePath!.startsWith('http')
                            ? Image.network(
                                _admin!.profilePath!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50, color: Colors.white),
                              )
                            : Image.file(
                                File(_admin!.profilePath!),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50, color: Colors.white),
                              ))
                    : const Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final bool isSelected = _selectIndex == index;
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? kPrimaryColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                          color: isSelected ? kPrimaryColor : Colors.grey[800],
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
