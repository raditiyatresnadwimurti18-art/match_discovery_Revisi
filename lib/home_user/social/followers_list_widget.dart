import 'dart:convert';
import 'dart:typed_data';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/social.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/models/login_model.dart';
import 'package:match_discovery/util/app_theme.dart';

class FollowersListWidget extends StatefulWidget {
  final String userId;
  final Function(LoginModel)? onUserTap;
  const FollowersListWidget({super.key, required this.userId, this.onUserTap});

  @override
  State<FollowersListWidget> createState() => _FollowersListWidgetState();
}

class _FollowersListWidgetState extends State<FollowersListWidget> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initUserId();
  }

  Future<void> _initUserId() async {
    _currentUserId = await PreferenceHandler.getUserId();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) return const SizedBox.shrink();

    return StreamBuilder<List<LoginModel>>(
      stream: SocialController.getFollowersStream(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
        }

        final followers = snapshot.data ?? [];

        if (followers.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Column(
              children: [
                Icon(Icons.person_outline_rounded, color: Colors.grey, size: 40),
                SizedBox(height: 10),
                Text('Belum ada pengikut', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return Column(
          children: followers.map((follower) => _buildFollowerItem(follower)).toList(),
        );
      },
    );
  }

  Widget _buildFollowerItem(LoginModel follower) {
    return FutureBuilder<bool>(
      future: SocialController.isFollowing(_currentUserId!, follower.id!),
      builder: (context, followSnapshot) {
        bool isFollowingBack = followSnapshot.data ?? false;

        Uint8List? profileBytes;
        if (follower.profilePath != null && follower.profilePath!.startsWith('data:image')) {
          try {
            profileBytes = base64Decode(follower.profilePath!.split(',').last);
          } catch (e) {}
        }

        return FadeInUp(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (widget.onUserTap != null) {
                      widget.onUserTap!(follower);
                    }
                  },
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: kPrimaryLight),
                    child: ClipOval(
                      child: profileBytes != null
                          ? Image.memory(profileBytes, fit: BoxFit.cover)
                          : const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(follower.nama ?? '-', style: kTitleStyle.copyWith(fontSize: 14)),
                      Text(follower.asalSekolah ?? '-', style: kSubtitleStyle.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
                if (follower.id != _currentUserId)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowingBack ? Colors.grey : kPrimaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      minimumSize: const Size(80, 30),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      if (isFollowingBack) {
                        await SocialController.unfollowUser(_currentUserId!, follower.id!);
                      } else {
                        await SocialController.followUser(_currentUserId!, follower.id!);
                      }
                      setState(() {}); // Refresh follow status
                    },
                    child: Text(
                      isFollowingBack ? 'Diikuti' : 'Ikuti Balik',
                      style: const TextStyle(fontSize: 11, color: Colors.white),
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
