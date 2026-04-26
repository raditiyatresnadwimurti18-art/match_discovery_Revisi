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

class FindFriendsPage extends StatefulWidget {
  const FindFriendsPage({super.key});

  @override
  State<FindFriendsPage> createState() => _FindFriendsPageState();
}

class _FindFriendsPageState extends State<FindFriendsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<LoginModel> _searchResults = [];
  bool _isLoading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initUserId();
  }

  Future<void> _initUserId() async {
    _currentUserId = PreferenceHandler.getUserId();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    
    setState(() => _isLoading = true);
    final results = await SocialController.searchUsers(query, _currentUserId ?? '');
    
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: Column(
        children: [
          // Google-style Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _performSearch,
                style: GoogleFonts.plusJakartaSans(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Cari berdasarkan nama atau instansi',
                  hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: kPrimaryColor, size: 22),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  suffixIcon: _searchController.text.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                ),
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 3))
              : _searchResults.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return FadeInUp(
                        delay: Duration(milliseconds: 30 * index),
                        child: _buildUserCard(user),
                      );
                    },
                  ),
          ),
        ],
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
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchController.text.isEmpty ? Icons.explore_outlined : Icons.sentiment_dissatisfied_rounded,
            size: 64,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty 
              ? 'Temukan teman satu minat kamu!' 
              : 'Ups, nama tersebut tidak ditemukan',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
