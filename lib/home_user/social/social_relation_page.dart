import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:match_discovery/home_user/social/user_list_widget.dart';
import 'package:match_discovery/util/app_theme.dart';

class SocialRelationPage extends StatefulWidget {
  final String userId;
  final int initialIndex;
  const SocialRelationPage({super.key, required this.userId, this.initialIndex = 0});

  @override
  State<SocialRelationPage> createState() => _SocialRelationPageState();
}

class _SocialRelationPageState extends State<SocialRelationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: kModernAppBar(
        title: 'Eksplorasi Koneksi',
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
                Tab(text: 'Pengikut'),
                Tab(text: 'Mengikuti'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                UserListWidget(userId: widget.userId, mode: 'followers'),
                UserListWidget(userId: widget.userId, mode: 'following'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
