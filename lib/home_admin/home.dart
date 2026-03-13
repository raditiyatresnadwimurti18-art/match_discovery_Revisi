import 'dart:io';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/admin.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/extension/navigator.dart';
import 'package:match_discovery/home_admin/data_user_lomba.dart';
import 'package:match_discovery/home_admin/history_lomba.dart';
import 'package:match_discovery/home_admin/isihome.dart';
import 'package:match_discovery/home_admin/profil_admin.dart';
import 'package:match_discovery/home_admin/track_record_user.dart';
import 'package:match_discovery/models/admin_model.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectIndex = 0;
  AdminModel? _admin;

  static const List<Widget> _pages = <Widget>[
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
    int? id = await PreferenceHandler.getId();
    if (id != null) {
      AdminModel? data = await AdminController.getAdminById(id);
      setState(() => _admin = data);
    }
  }

  void _onMenuTap(int index) {
    setState(() => _selectIndex = index);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ── AppBar ──────────────────────────────────────────────
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        backgroundColor: const Color(0xff0f2a55),
        title: Text(
          _currentTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                context
                    .push(const ProfilAdmin())
                    .then((_) => _fetchAdminData());
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child:
                      _admin?.profilePath != null &&
                          _admin!.profilePath!.isNotEmpty
                      ? Image.file(
                          File(_admin!.profilePath!),
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

      // ── Drawer ──────────────────────────────────────────────
      drawer: Drawer(
        child: Column(
          children: [
            // Header
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xff0f2a55)),
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
                child:
                    _admin?.profilePath != null &&
                        _admin!.profilePath!.isNotEmpty
                    ? Image.file(
                        File(_admin!.profilePath!),
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

            // Menu Items
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
                          ? const Color(0xff0f2a55).withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      leading: Icon(
                        _menuItems[index]['icon'] as IconData,
                        color: isSelected
                            ? const Color(0xff0f2a55)
                            : Colors.grey[600],
                      ),
                      title: Text(
                        _menuItems[index]['label'] as String,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xff0f2a55)
                              : Colors.grey[800],
                        ),
                      ),
                      trailing: isSelected
                          ? Container(
                              width: 4,
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xff0f2a55),
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

      // ── Body ────────────────────────────────────────────────
      body: _pages.elementAt(_selectIndex),
    );
  }
}
