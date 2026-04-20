import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:match_discovery/database/controllers/admin.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/home_admin/widget_home/daftar_lomba.dart';
import 'package:match_discovery/home_admin/data_user_lomba.dart';
import 'package:match_discovery/home_admin/history_lomba.dart';
import 'package:match_discovery/home_admin/profil_admin.dart';
import 'package:match_discovery/home_admin/track_record_user.dart';
import 'package:match_discovery/home_admin/statistik_dashboard.dart';
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
  Uint8List? _profileBytes;

  List<Widget> get _pages => [
    const Widget2(),
    const DataUserLomba(),
    const HistoryLomba(),
    const TrackRecordUser(),
    const StatistikDashboard(),
  ];

  List<Map<String, dynamic>> get _menuItems => [
    {'label': 'Home', 'icon': Icons.home_rounded},
    {'label': 'Data User', 'icon': Icons.verified_user_rounded},
    {'label': 'History Lomba', 'icon': Icons.history_rounded},
    {'label': 'Track Record', 'icon': Icons.workspace_premium_rounded},
    {'label': 'Statistik', 'icon': Icons.analytics_rounded},
  ];

  String get _currentTitle => _menuItems[_selectIndex]['label'] as String;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    final id = await PreferenceHandler.getAdminId();
    if (id == null) return;
    try {
      final data = await AdminController.getAdminById(id);
      
      Uint8List? bytes;
      if (data?.profilePath != null && data!.profilePath!.startsWith('data:image')) {
        try {
          bytes = base64Decode(data.profilePath!.split(',').last);
        } catch (e) {
          debugPrint("Error decoding admin profile: $e");
        }
      }

      if (!mounted) return;
      setState(() {
        _admin = data;
        _profileBytes = bytes;
      });
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
              onTap: () => Navigator.push(
                context,
                PageTransition(child: const ProfilAdmin()),
              ).then((_) => _fetchAdminData()),
              child: Hero(
                tag: 'admin_profile',
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _admin?.role == 'super'
                        ? Image.asset('assets/images/logo.png', fit: BoxFit.cover)
                        : _profileBytes != null
                            ? Image.memory(_profileBytes!, fit: BoxFit.cover)
                            : (_admin?.profilePath != null && _admin!.profilePath!.isNotEmpty && !_admin!.profilePath!.startsWith('data:image'))
                                ? (_admin!.profilePath!.startsWith('http')
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
            _buildModernAdminHeader(),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final bool isSelected = _selectIndex == index;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? kPrimaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: kPrimaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ] : null,
                    ),
                    child: ListTile(
                      onTap: () => _onMenuTap(index),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      leading: Icon(
                        _menuItems[index]['icon'] as IconData,
                        color: isSelected ? Colors.white : kPrimaryColor,
                      ),
                      title: Text(
                        _menuItems[index]['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: Container(
          key: ValueKey<int>(_selectIndex),
          child: _pages.elementAt(_selectIndex),
        ),
      ),
    );
  }

  Widget _buildModernAdminHeader() {
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
              radius: 40,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: _admin?.role == 'super'
                    ? Image.asset('assets/images/logo.png', fit: BoxFit.cover, width: 80, height: 80)
                    : _profileBytes != null
                        ? Image.memory(_profileBytes!, fit: BoxFit.cover, width: 80, height: 80)
                        : (_admin?.profilePath != null && _admin!.profilePath!.isNotEmpty && !_admin!.profilePath!.startsWith('data:image'))
                            ? Image.file(
                                File(_admin!.profilePath!),
                                fit: BoxFit.cover,
                                width: 80, height: 80,
                                errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40, color: kPrimaryColor),
                              )
                            : const Icon(Icons.person, size: 40, color: kPrimaryColor),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _admin?.nama ?? 'Admin',
            style: kWhiteBoldStyle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _admin?.role == 'super' ? Colors.amber : Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _admin?.role == 'super' ? 'SUPER ADMIN' : 'ADMIN STAFF',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _admin?.role == 'super' ? kPrimaryColor : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
