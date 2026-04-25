import 'package:flutter/material.dart';
import 'package:match_discovery/home_user/social/find_friends.dart';
import 'package:match_discovery/home_user/social/following_list.dart';
import 'package:match_discovery/util/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SocialHubPage extends StatefulWidget {
  const SocialHubPage({super.key});

  @override
  State<SocialHubPage> createState() => _SocialHubPageState();
}

class _SocialHubPageState extends State<SocialHubPage> with SingleTickerProviderStateMixin {
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
        title: 'Eksplorasi Sosial',
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
                Tab(text: 'Cari Teman'),
                Tab(text: 'Mengikuti'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                FindFriendsPage(),
                FollowingListPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
