import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import '../models/chat_model.dart';
import '../database/chat_service.dart';
import '../util/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String currentUserId;
  final String peerName;
  final String? peerProfileUrl;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.currentUserId,
    required this.peerName,
    this.peerProfileUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _cleanupNotifications();
    _markRead();
  }

  void _markRead() {
    _chatService.markMessagesAsRead(widget.roomId, widget.currentUserId);
  }

  void _cleanupNotifications() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('targetId', isEqualTo: widget.currentUserId)
        .where('roomId', isEqualTo: widget.roomId)
        .get();

    for (var doc in snapshot.docs) {
      doc.reference.delete();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 50,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (pickedFile != null) {
      setState(() => _isUploading = true);

      File file = File(pickedFile.path);
      String? imageUrl = await _chatService.uploadChatFile(
        widget.roomId,
        file,
        'images',
      );

      if (imageUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengunggah gambar. Pastikan ukuran file tidak terlalu besar.')),
          );
        }
        setState(() => _isUploading = false);
        return;
      }

      final newMessage = ChatMessage(
        id: '', 
        senderId: widget.currentUserId,
        text: 'Mengirim gambar',
        timestamp: DateTime.now(),
        status: 'sent',
        messageType: 'image',
        fileUrl: imageUrl,
        localPath: pickedFile.path,
      );
      
      await _chatService.sendMessage(widget.roomId, newMessage, localPath: pickedFile.path);

      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickFile() async {
    try {
      final dynamic filePickerClass = FilePicker;
      final dynamic result = await filePickerClass.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files != null && result.files.isNotEmpty) {
        final dynamic selectedFile = result.files.first;
        if (selectedFile.path != null) {
          setState(() => _isUploading = true);

          File file = File(selectedFile.path!);
          String fileName = selectedFile.name ?? 'Berkas';
          String? fileUrl = await _chatService.uploadChatFile(
            widget.roomId,
            file,
            'docs',
          );

          if (fileUrl == null) {
             if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gagal mengirim file. Pastikan ukuran file tidak melebihi 700KB.')),
              );
            }
            setState(() => _isUploading = false);
            return;
          }

          final newMessage = ChatMessage(
            id: '', // Will be generated
            senderId: widget.currentUserId,
            text: 'Mengirim dokumen: $fileName',
            timestamp: DateTime.now(),
            status: 'sent',
            messageType: 'file',
            fileUrl: fileUrl,
            fileName: fileName,
            localPath: file.path,
          );
          await _chatService.sendMessage(widget.roomId, newMessage, localPath: file.path);
        }
      }
    } catch (e) {
      debugPrint("Gagal memilih file: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _handleSend() {
    if (_messageController.text.trim().isEmpty) return;

    final newMessage = ChatMessage(
      id: '', // Will be generated
      senderId: widget.currentUserId,
      text: _messageController.text.trim(),
      timestamp: DateTime.now().toUtc(), // SISTEM: GMT0
      status: 'sent',
      messageType: 'text',
    );

    _chatService.sendMessage(widget.roomId, newMessage);
    _messageController.clear();
  }

  String _getDateString(DateTime dateUtc) {
    final date = dateUtc.toLocal(); // TAMPILAN: LOCAL
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'HARI INI';
    } else if (messageDate == yesterday) {
      return 'KEMARIN';
    } else {
      return DateFormat('d MMMM yyyy').format(date).toUpperCase();
    }
  }

  ImageProvider? _getProfileImage(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(path.split(',').last));
      } catch (e) {
        return null;
      }
    }
    return NetworkImage(path);
  }

  @override
  Widget build(BuildContext context) {
    String peerId = widget.roomId
        .split('_')
        .firstWhere((id) => id != widget.currentUserId, orElse: () => 'Admin');

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(peerId)
              .snapshots(),
          builder: (context, snapshot) {
            final peerData = snapshot.data?.data() as Map<String, dynamic>?;
            final String name = peerData?['nama'] ?? widget.peerName;
            final String? photo =
                peerData?['profilePath'] ?? widget.peerProfileUrl;
            final image = _getProfileImage(photo);

            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white24,
                  backgroundImage: image,
                  child: image == null
                      ? Text(
                          name[0].toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      _buildStatusSubtitle(peerData),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          if (_isUploading)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              color: kSecondaryColor,
              minHeight: 2,
            ),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(widget.roomId, widget.currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimaryColor),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Belum ada pesan. Sapa temanmu!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  );
                }

                _markRead();
                
                // CACAD LOGIKA FIX: Copy list dan paksa sorting DESCENDING berdasarkan MILIDETIK
                // agar index 0 selalu pesan terbaru secara absolut (paling bawah di reverse:true)
                final List<ChatMessage> messages = List<ChatMessage>.from(snapshot.data!);
                messages.sort((a, b) {
                  int cmp = b.timestamp.millisecondsSinceEpoch.compareTo(a.timestamp.millisecondsSinceEpoch);
                  if (cmp == 0) {
                    return b.id.compareTo(a.id); // Tie-breaker menggunakan ID jika milidetik sama
                  }
                  return cmp;
                });

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == widget.currentUserId;

                    // Logika Header Tanggal untuk List Terbalik (Milidetik Precision):
                    bool showDate = false;
                    DateTime date = msg.timestamp;
                    
                    if (index == messages.length - 1) {
                      showDate = true;
                    } else {
                      DateTime olderDate = messages[index + 1].timestamp;
                      if (date.day != olderDate.day ||
                          date.month != olderDate.month ||
                          date.year != olderDate.year) {
                        showDate = true;
                      }
                    }

                    return Column(
                      children: [
                        if (showDate)
                          _buildDateHeader(_getDateString(date)),
                        _buildChatBubble(msg, isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildDateHeader(String date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: kPrimaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          date,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: kPrimaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSubtitle(Map<String, dynamic>? data) {
    if (data == null) return const SizedBox();

    final bool isOnline = data['isOnline'] ?? false;
    final String? lastActive = data['lastActive'];

    if (isOnline) {
      return Text(
        'Online',
        style: GoogleFonts.plusJakartaSans(
          color: Colors.greenAccent,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    } else if (lastActive != null) {
      try {
        DateTime lastDate = DateTime.parse(lastActive).toLocal();
        return Text(
          'Terakhir terlihat ${DateFormat('HH:mm').format(lastDate)}',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 11,
          ),
        );
      } catch (e) {
        return const SizedBox();
      }
    }
    return const SizedBox();
  }

  void _showImagePreview(String? imageUrl, String? localPath) {
    if (imageUrl == null && localPath == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: localPath != null && File(localPath).existsSync()
                    ? Image.file(File(localPath))
                    : CachedNetworkImage(
                        imageUrl: imageUrl!,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                      ),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.download_rounded, color: Colors.white, size: 30),
                onPressed: () async {
                  try {
                    String? pathToSave = localPath;
                    
                    // Jika file tidak ada secara lokal (misal: pesan masuk), unduh terlebih dahulu
                    if (pathToSave == null || !File(pathToSave).existsSync()) {
                      if (imageUrl == null) return;
                      
                      // Beri tahu user sedang memproses
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sedang mengunduh gambar...'), duration: Duration(seconds: 1)),
                      );

                      final response = await http.get(Uri.parse(imageUrl));
                      if (response.statusCode == 200) {
                        final directory = await getTemporaryDirectory();
                        final file = File('${directory.path}/temp_save_${DateTime.now().millisecondsSinceEpoch}.png');
                        await file.writeAsBytes(response.bodyBytes);
                        pathToSave = file.path;
                      } else {
                        throw Exception('Gagal mengunduh gambar dari server');
                      }
                    }

                    // Minta izin akses secara eksplisit sebelum menyimpan
                    final hasAccess = await Gal.hasAccess();
                    if (!hasAccess) {
                      await Gal.requestAccess();
                    }

                    // Simpan ke Galeri menggunakan paket gal
                    await Gal.putImage(pathToSave);
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gambar berhasil disimpan ke galeri'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal menyimpan gambar: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatOptions(ChatMessage msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (msg.messageType == 'text')
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Colors.blue),
                title: Text('Edit Pesan', style: GoogleFonts.plusJakartaSans()),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(msg);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: Text('Hapus Pesan', style: GoogleFonts.plusJakartaSans(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(msg);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(ChatMessage msg) {
    final editController = TextEditingController(text: msg.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Pesan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Ketik pesan baru..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (editController.text.trim().isNotEmpty) {
                await _chatService.updateMessage(widget.roomId, msg.id, editController.text.trim(), msg.senderId);
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ChatMessage msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Pesan?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: const Text('Pesan ini akan dihapus untuk semua orang.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await _chatService.deleteMessage(widget.roomId, msg.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg, bool isMe) {
    bool isImage = msg.messageType == 'image';
    bool isFile = msg.messageType == 'file';
    bool isDeleted = msg.status == 'deleted';
    
    return GestureDetector(
      onLongPress: (isMe && !isDeleted) ? () => _showChatOptions(msg) : null,
      onTap: (isImage && !isDeleted) ? () => _showImagePreview(msg.fileUrl, msg.localPath) : null,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            top: 4,
            bottom: 4,
            left: isMe ? 50 : 0,
            right: isMe ? 0 : 50,
          ),
          padding: (isImage || isFile) && !isDeleted
              ? const EdgeInsets.all(4)
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? kPrimaryColor : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (isDeleted)
                Text(
                  msg.text,
                  style: GoogleFonts.plusJakartaSans(
                    color: isMe ? Colors.white70 : Colors.black45,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else if (isImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Hero(
                    tag: msg.id,
                    child: msg.localPath != null && File(msg.localPath!).existsSync()
                      ? Image.file(File(msg.localPath!), fit: BoxFit.cover, width: 200, height: 200)
                      : (msg.fileUrl != null ? CachedNetworkImage(
                          imageUrl: msg.fileUrl!,
                          fit: BoxFit.cover,
                          width: 200,
                          height: 200,
                          placeholder: (context, url) => Container(width: 200, height: 200, color: Colors.grey[200]),
                          errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                        ) : const Icon(Icons.image_not_supported)),
                  ),
                )
              else if (isFile)
                _buildFileWidget(msg, isMe)
              else
                Text(
                  msg.text,
                  style: GoogleFonts.plusJakartaSans(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(msg.timestamp.toLocal()),
                    style: GoogleFonts.plusJakartaSans(
                      color: isMe ? Colors.white70 : Colors.black45,
                      fontSize: 10,
                    ),
                  ),
                  if (isMe && !isDeleted) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all_rounded,
                      size: 14,
                      color: msg.status == 'read'
                          ? Colors.lightBlueAccent
                          : Colors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileWidget(ChatMessage msg, bool isMe) {
    return GestureDetector(
      onTap: () async {
        if (msg.localPath != null && File(msg.localPath!).existsSync()) {
          final Uri url = Uri.file(msg.localPath!);
          if (await canLaunchUrl(url)) await launchUrl(url);
          return;
        }
        if (msg.fileUrl != null) {
          final Uri url = Uri.parse(msg.fileUrl!);
          if (await canLaunchUrl(url)) await launchUrl(url);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isMe ? Colors.white12 : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file_rounded, color: isMe ? Colors.white : kPrimaryColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                msg.fileName ?? 'Berkas',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMenuOption(
                  icon: Icons.image_rounded,
                  color: Colors.purple,
                  label: 'Galeri',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                _buildMenuOption(
                  icon: Icons.camera_alt_rounded,
                  color: Colors.pink,
                  label: 'Kamera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildMenuOption(
                  icon: Icons.insert_drive_file_rounded,
                  color: Colors.orange,
                  label: 'Dokumen',
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: kBgColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: kPrimaryColor,
                        ),
                        onPressed: _showAttachmentMenu,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Tulis pesan...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              color: Colors.grey[500],
                            ),
                            border: InputBorder.none,
                          ),
                          maxLines: 5,
                          minLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _handleSend,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
