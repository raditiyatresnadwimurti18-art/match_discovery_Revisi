import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/chat_model.dart';
import '../models/login_model.dart';
import '../database/chat_service.dart';
import '../database/controllers/social.dart';
import '../database/controllers/user.dart';
import '../database/preferences.dart';
import '../util/app_theme.dart';
import 'chat_screen.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatService _chatService = ChatService();
  String? _currentUserId;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  void _loadUserId() {
    final id = PreferenceHandler.getId();
    setState(() => _currentUserId = id);
  }

  Uint8List? _getProfileBytes(String? profilePath) {
    if (profilePath != null && profilePath.startsWith('data:image')) {
      try {
        return base64Decode(profilePath.split(',').last);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateToCheck == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (dateToCheck == yesterday) {
      return 'Kemarin';
    } else {
      return DateFormat('dd/MM/yy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Pesan')),
        body: const Center(child: Text('Silakan login terlebih dahulu')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Chat',
          style: GoogleFonts.plusJakartaSans(
            color: kPrimaryColor,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: kBgColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  icon: const Icon(Icons.search, color: Colors.grey),
                  hintText: 'Cari chat...',
                  hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Teman Baru (Mutual)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Text(
                      'Teman Baru',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    child: StreamBuilder<List<LoginModel>>(
                      stream: SocialController.getMutualFriendsStream(_currentUserId!),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Belum ada teman baru.',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),
                            ),
                          );
                        }
                        
                        final friends = snapshot.data!;
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: friends.length,
                          itemBuilder: (context, index) {
                            final friend = friends[index];
                            final bytes = _getProfileBytes(friend.profilePath);
                            
                            return GestureDetector(
                              onTap: () async {
                                String roomId = await _chatService.getOrCreateChatRoom(_currentUserId!, friend.id!);
                                if (mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        roomId: roomId,
                                        currentUserId: _currentUserId!,
                                        peerName: friend.nama ?? 'User',
                                        peerProfileUrl: friend.profilePath,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                width: 70,
                                margin: const EdgeInsets.only(right: 15),
                                child: Column(
                                  children: [
                                    Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor: kPrimaryColor.withOpacity(0.1),
                                          backgroundImage: bytes != null ? MemoryImage(bytes) : null,
                                          child: bytes == null 
                                            ? Text(friend.nama?[0].toUpperCase() ?? 'U', style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold))
                                            : null,
                                        ),
                                        if (friend.isOnline ?? false)
                                          Positioned(
                                            right: 2,
                                            bottom: 2,
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: kSuccessColor,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      friend.nama?.split(' ')[0] ?? 'User',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  StreamBuilder<List<ChatRoom>>(
                    stream: _chatService.getChatRooms(_currentUserId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(color: kPrimaryColor),
                        ));
                      }

                      final rooms = snapshot.data ?? [];
                      if (rooms.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              Icon(Icons.chat_bubble_outline_rounded, size: 60, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('Belum ada obrolan', style: GoogleFonts.plusJakartaSans(color: Colors.grey[500])),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: rooms.length,
                        itemBuilder: (context, index) {
                          final room = rooms[index];
                          final peerId = room.members.firstWhere((id) => id != _currentUserId, orElse: () => 'Admin');
                          
                          return FutureBuilder<LoginModel?>(
                            future: UserController.getUserById(peerId),
                            builder: (context, userSnap) {
                              final peer = userSnap.data;
                              final displayName = peer?.nama ?? 'User $peerId';
                              
                              if (_searchQuery.isNotEmpty && !displayName.toLowerCase().contains(_searchQuery)) {
                                return const SizedBox.shrink();
                              }

                              final bytes = _getProfileBytes(peer?.profilePath);
                              final bool isMe = room.lastSenderId == _currentUserId;

                              return ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        roomId: room.id,
                                        currentUserId: _currentUserId!,
                                        peerName: displayName,
                                        peerProfileUrl: peer?.profilePath,
                                      ),
                                    ),
                                  );
                                },
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor: Colors.grey[200],
                                      backgroundImage: bytes != null ? MemoryImage(bytes) : null,
                                      child: bytes == null 
                                        ? Text(displayName[0].toUpperCase(), style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold))
                                        : null,
                                    ),
                                    if (peer?.isOnline ?? false)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: kSuccessColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                                      ),
                                    ),
                                    Text(
                                      _formatDateTime(room.lastTime),
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Row(
                                  children: [
                                    if (isMe) const Icon(Icons.done_all, size: 16, color: Colors.blue),
                                    if (isMe) const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        room.lastMessage,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    StreamBuilder<int>(
                                      stream: _chatService.getUnreadCount(room.id, _currentUserId!),
                                      builder: (context, countSnap) {
                                        final count = countSnap.data ?? 0;
                                        if (count == 0) return const SizedBox.shrink();
                                        return Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: kSuccessColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '$count',
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }
                          );
                        },
                      );
                    },
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

