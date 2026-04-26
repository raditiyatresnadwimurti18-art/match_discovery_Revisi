import 'dart:convert';
import 'dart:typed_data';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/riwayat.dart';
import 'package:match_discovery/database/controllers/social.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/database/chat_service.dart';
import 'package:match_discovery/home_user/chat_screen.dart';
import 'package:match_discovery/home_user/social/followers_list_widget.dart';
import 'package:match_discovery/models/login_model.dart';
import 'package:match_discovery/util/app_theme.dart';

class UserProfileView extends StatefulWidget {
  final LoginModel user;
  const UserProfileView({super.key, required this.user});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  int _totalLomba = 0;
  List<Map<String, dynamic>> _trackRecord = [];
  bool _isFollowing = false;
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _currentUserId = PreferenceHandler.getUserId();
    if (_currentUserId != null) {
      _isFollowing = await SocialController.isFollowing(_currentUserId!, widget.user.id!);
    }
    _totalLomba = await RiwayatController.getTotalSelesaiUser(widget.user.id!);
    _trackRecord = await RiwayatController.getTrackRecordUser(widget.user.id!);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Uint8List? _getProfileBytes() {
    if (widget.user.profilePath != null && widget.user.profilePath!.startsWith('data:image')) {
      try {
        return base64Decode(widget.user.profilePath!.split(',').last);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> _handleAction() async {
    if (_currentUserId == null) return;
    
    if (_isFollowing) {
      // Show confirmation dialog for unfollowing
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Batal Mengikuti?'),
          content: Text('Apakah kamu yakin ingin berhenti mengikuti ${widget.user.nama}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tidak', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: kDangerButtonStyle(radius: 12),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya, Berhenti'),
            ),
          ],
        ),
      ) ?? false;

      if (!confirm) return;
    }

    setState(() => _isLoading = true);
    
    if (!_isFollowing) {
      await SocialController.followUser(_currentUserId!, widget.user.id!);
    } else {
      await SocialController.unfollowUser(_currentUserId!, widget.user.id!);
    }
    
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? profileBytes = _getProfileBytes();
    
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: kModernAppBar(
        title: 'Profil Pengguna',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Hero(
                tag: 'user_${widget.user.id}',
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kPrimaryColor, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: profileBytes != null
                        ? Image.memory(profileBytes, fit: BoxFit.cover)
                        : const Icon(Icons.person, size: 80, color: kPrimaryColor),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.user.nama ?? '-',
              style: kTitleStyle.copyWith(fontSize: 22),
            ),
            Text(
              widget.user.asalSekolah ?? widget.user.email ?? '-',
              style: kSubtitleStyle,
            ),
            const SizedBox(height: 20),
            
            // Action Buttons
            if (_currentUserId != null && _currentUserId != widget.user.id)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing ? Colors.red.shade400 : kPrimaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _handleAction,
                        icon: Icon(_isFollowing ? Icons.person_remove_rounded : Icons.person_add_rounded),
                        label: Text(_isFollowing ? 'Batal Mengikuti' : 'Ikuti'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: kPrimaryColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          setState(() => _isLoading = true);
                          String roomId = await ChatService().getOrCreateChatRoom(_currentUserId!, widget.user.id!);
                          setState(() => _isLoading = false);
                          
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  roomId: roomId,
                                  currentUserId: _currentUserId!,
                                  peerName: widget.user.nama ?? 'User',
                                  peerProfileUrl: widget.user.profilePath,
                                ),
                              ),
                            );
                          }
                        },
                        child: const Icon(Icons.mail_outline_rounded, color: kPrimaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              
            const SizedBox(height: 30),
            
            // Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildStatCard('Total Lomba', _totalLomba.toString(), Icons.emoji_events_rounded, Colors.orange),
                  const SizedBox(width: 15),
                  _buildStatCard('Kota', widget.user.asalKota ?? '-', Icons.location_on_rounded, Colors.red),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Followers section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daftar Pengikut', style: kTitleStyle),
                  const SizedBox(height: 15),
                  FollowersListWidget(
                    userId: widget.user.id!,
                    onUserTap: (user) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UserProfileView(user: user)),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Track Record
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Statistik Lomba', style: kTitleStyle),
                  const SizedBox(height: 15),
                  if (_trackRecord.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey, size: 40),
                          SizedBox(height: 10),
                          Text('Belum mengikuti lomba apapun', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  else
                    ..._trackRecord.map((item) => FadeInUp(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
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
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.star_rounded, color: kPrimaryColor),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['judulLomba'], style: kTitleStyle.copyWith(fontSize: 16)),
                                  Text('Diikuti ${item['jumlahIkut']} kali', style: kSubtitleStyle),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Terakhir', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                Text(item['terakhirIkut'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )).toList(),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(value, style: kTitleStyle.copyWith(fontSize: 18, color: color)),
            Text(label, style: kSubtitleStyle.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
