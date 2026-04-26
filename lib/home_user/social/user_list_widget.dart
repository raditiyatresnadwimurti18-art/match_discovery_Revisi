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

class UserListWidget extends StatefulWidget {
  final String userId;
  final String mode; // 'followers' or 'following'
  const UserListWidget({super.key, required this.userId, required this.mode});

  @override
  State<UserListWidget> createState() => _UserListWidgetState();
}

class _UserListWidgetState extends State<UserListWidget> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initUserId();
  }

  Future<void> _initUserId() async {
    _currentUserId = PreferenceHandler.getUserId();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) return const SizedBox.shrink();

    return StreamBuilder<List<LoginModel>>(
      stream: widget.mode == 'followers' 
          ? SocialController.getFollowersStream(widget.userId)
          : SocialController.getFollowingStream(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 2),
          ));
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Icon(Icons.person_search_rounded, color: Colors.grey.shade200, size: 60),
                const SizedBox(height: 10),
                Text(
                  widget.mode == 'followers' ? 'Belum ada pengikut' : 'Belum mengikuti siapapun', 
                  style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontWeight: FontWeight.w500)
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) => _buildUserItem(users[index]),
        );
      },
    );
  }

  Widget _buildUserItem(LoginModel user) {
    return FutureBuilder<bool>(
      future: SocialController.isFollowing(_currentUserId!, user.id!),
      builder: (context, followSnapshot) {
        bool isFollowing = followSnapshot.data ?? false;

        Uint8List? profileBytes;
        if (user.profilePath != null && user.profilePath!.startsWith('data:image')) {
          try {
            profileBytes = base64Decode(user.profilePath!.split(',').last);
          } catch (e) {}
        }

        return FadeInUp(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UserProfileView(user: user)),
                    );
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: kPrimaryColor.withOpacity(0.05)),
                    child: ClipOval(
                      child: profileBytes != null
                          ? Image.memory(profileBytes, fit: BoxFit.cover)
                          : const Icon(Icons.person, color: kPrimaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.nama ?? '-', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(user.asalSekolah ?? user.email ?? '-', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                if (user.id != _currentUserId)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing ? Colors.grey.shade200 : kPrimaryColor,
                      foregroundColor: isFollowing ? Colors.grey.shade700 : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (isFollowing) {
                        bool confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Batal Mengikuti?'),
                            content: Text('Hapus ${user.nama} dari daftar mengikuti?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, Hapus')),
                            ],
                          ),
                        ) ?? false;
                        if (confirm) {
                          await SocialController.unfollowUser(_currentUserId!, user.id!);
                          setState(() {});
                        }
                      } else {
                        await SocialController.followUser(_currentUserId!, user.id!);
                        setState(() {});
                      }
                    },
                    child: Text(
                      isFollowing ? 'Diikuti' : (widget.mode == 'followers' ? 'Ikuti Balik' : 'Ikuti'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
