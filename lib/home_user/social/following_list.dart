import 'dart:convert';
import 'dart:typed_data';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/social.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/home_user/social/user_profile_view.dart';
import 'package:match_discovery/models/login_model.dart';
import 'package:match_discovery/util/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class FollowingListPage extends StatefulWidget {
  const FollowingListPage({super.key});

  @override
  State<FollowingListPage> createState() => _FollowingListPageState();
}

class _FollowingListPageState extends State<FollowingListPage> {
  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initUserId();
  }

  Future<void> _initUserId() async {
    _currentUserId = await PreferenceHandler.getUserId();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: kPrimaryColor)));
    }

    if (_currentUserId == null) {
      return const Scaffold(body: Center(child: Text('Silahkan login terlebih dahulu')));
    }

    return Scaffold(
      backgroundColor: kBgColor,
      body: StreamBuilder<List<LoginModel>>(
        stream: SocialController.getFollowingStream(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          }
          
          final users = snapshot.data ?? [];
          
          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                  Text(
                    'Daftar mengikuti kamu masih kosong',
                    style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            physics: const BouncingScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return FadeInLeft(
                delay: Duration(milliseconds: 30 * index),
                child: _buildUserCard(user),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(LoginModel user) {
    Uint8List? profileBytes;
    if (user.profilePath != null && user.profilePath!.startsWith('data:image')) {
      try {
        profileBytes = base64Decode(user.profilePath!.split(',').last);
      } catch (e) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UserProfileView(user: user)),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kPrimaryColor.withOpacity(0.05),
          ),
          child: ClipOval(
            child: profileBytes != null
                ? Image.memory(profileBytes, fit: BoxFit.cover)
                : const Icon(Icons.person_rounded, color: kPrimaryColor, size: 30),
          ),
        ),
        title: Text(
          user.nama ?? '-',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            user.asalSekolah ?? user.email ?? '-',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: kPrimaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Profil',
            style: GoogleFonts.plusJakartaSans(color: kPrimaryColor, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
