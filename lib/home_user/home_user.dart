import 'package:flutter/foundation.dart';
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
  bool _pageLoaded = false;

  @override
  void initState() {
    super.initState();
    // Simulate loading
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _pageLoaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: Stack(
        children: [
          _pageLoaded
              ? const IsiHomeUser()
              : const Center(child: CircularProgressIndicator(color: kPrimaryColor)),
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Demo Mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
