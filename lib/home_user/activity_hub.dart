import 'package:flutter/material.dart';
import 'package:match_discovery/home_user/history_user.dart';
import 'package:match_discovery/home_user/riwayat_selesai_user_page.dart';
import 'package:match_discovery/util/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ActivityHubPage extends StatefulWidget {
  const ActivityHubPage({super.key});

  @override
  State<ActivityHubPage> createState() => _ActivityHubPageState();
}

class _ActivityHubPageState extends State<ActivityHubPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: kModernAppBar(
        title: 'Aktivitas Kamu',
      ),
      body: Column(
        children: [
          Container(
            color: kPrimaryColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: kSecondaryColor,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: 'Aktif'),
                Tab(text: 'Selesai'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                HistoryUser(),
                RiwayatSelesaiUserPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
