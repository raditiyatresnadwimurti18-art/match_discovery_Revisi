import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import 'local_db_service.dart';

class ChatService {
  // Singleton pattern
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalDbService _localDb = LocalDbService();
  final Set<String> _activeSyncRooms = {};

  // StreamController global untuk notifikasi perubahan data lokal ke UI
  static final _messageUpdateController = StreamController<String>.broadcast();

  // Melacak room mana yang sedang dibuka oleh user (agar tidak muncul notifikasi double)
  static String? activeRoomId;

  static void notifyUpdate([String roomId = 'global']) {
    if (!_messageUpdateController.isClosed) {
      _messageUpdateController.add(roomId);
    }
  }

  // Mendapatkan daftar pesan secara real-time (Local-First + Auto Delete Cloud)
  Stream<List<ChatMessage>> getMessages(String roomId, String currentUserId) {
    StreamController<List<ChatMessage>>? controller;
    StreamSubscription? localSub;
    StreamSubscription? firestoreSub;

    controller = StreamController<List<ChatMessage>>(
      onListen: () {
        // 1. Ambil pesan lokal segera
        _refreshLocalMessages(roomId, controller!);

        // 2. Dengar sinyal perubahan lokal (Internal)
        localSub = _messageUpdateController.stream
            .where((id) => id == roomId || id == 'global')
            .listen((_) => _refreshLocalMessages(roomId, controller!));

        // 3. Dengar Firestore untuk pesan baru
        firestoreSub = _db.collection('rooms')
            .doc(roomId)
            .collection('messages')
            .snapshots()
            .listen((snapshot) async {
          if (snapshot.docs.isEmpty) return;

          bool hasChanges = false;
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.removed) continue;
            
            final doc = change.doc;
            if (!doc.exists) continue;
            
            try {
              final data = doc.data() as Map<String, dynamic>;
              ChatMessage msg = ChatMessage.fromFirestore(data, doc.id);
              
              // Jika ini PESAN MASUK
              if (msg.senderId != currentUserId) {
                if (msg.status == 'deleted') {
                  await _localDb.updateMessage(msg.id, 'Pesan ini telah dihapus', status: 'deleted');
                } else {
                  String? finalLocalPath;
                  if (msg.fileUrl != null && msg.fileUrl!.startsWith('data:')) {
                    finalLocalPath = await _saveBase64ToFile(msg.fileUrl!, msg.fileName ?? "file_${msg.id}");
                  }
                  await _localDb.saveMessage(roomId, msg, localPath: finalLocalPath);
                }
                
                // Hapus dari cloud setelah berhasil disimpan di lokal
                doc.reference.delete().catchError((_) => null);
                hasChanges = true;
              } 
              // Jika ini PESAN KITA SENDIRI (sinkronisasi antar perangkat)
              else {
                if (msg.status == 'updated' || msg.status == 'deleted') {
                  // Jika status update/delete, sinkronkan ke lokal lalu hapus dari cloud
                  if (msg.status == 'deleted') {
                    await _localDb.updateMessage(msg.id, 'Pesan ini telah dihapus', status: 'deleted');
                  } else {
                    await _localDb.updateMessage(msg.id, msg.text);
                  }
                  doc.reference.delete().catchError((_) => null);
                  hasChanges = true;
                } else {
                  // Pesan baru dari kita (mungkin dari perangkat lain)
                  await _localDb.saveMessage(roomId, msg);
                  // Biarkan tetap di cloud agar penerima bisa ambil, 
                  // atau hapus jika kita yakin penerima sudah ambil (tapi sulit dipastikan di sini)
                }
              }
            } catch (e) {
              debugPrint("Error processing message doc: $e");
            }
          }

          if (hasChanges) {
            notifyUpdate(roomId);
          }
        }, onError: (e) => debugPrint("Firestore stream error: $e"));
      },
      onCancel: () {
        localSub?.cancel();
        firestoreSub?.cancel();
        controller?.close();
      },
    );

    return controller.stream;
  }

  void _refreshLocalMessages(String roomId, StreamController<List<ChatMessage>> controller) async {
    if (controller.isClosed) return;
    try {
      final msgs = await _localDb.getMessages(roomId);
      if (!controller.isClosed) controller.add(msgs);
    } catch (e) {
      debugPrint("Error refresh local messages: $e");
    }
  }

  Future<String?> _saveBase64ToFile(String base64Data, String fileName) async {
    try {
      final parts = base64Data.split(',');
      if (parts.length < 2) return null;
      
      final bytes = base64Decode(parts.last);
      final directory = await getApplicationDocumentsDirectory();
      
      final mediaDir = Directory(p.join(directory.path, 'chat_media'));
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      final file = File(p.join(mediaDir.path, fileName));
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint("Error saving base64 to file: $e");
      return null;
    }
  }

  Future<String?> uploadChatFile(String roomId, File file, String type) async {
    try {
      if (!await file.exists()) return null;
      // Tingkatkan sedikit batas jika memang dibutuhkan, tapi tetap waspada limit Firestore
      if (file.lengthSync() > 900000) return null; 

      List<int> fileBytes = await file.readAsBytes();
      String base64String = base64Encode(fileBytes);
      
      String ext = p.extension(file.path).replaceAll('.', '');
      if (ext.isEmpty) ext = (type == 'images') ? 'png' : 'bin';
      
      return "data:${type == 'images' ? 'image' : 'application/octet-stream'}/$ext;base64,$base64String";
    } catch (e) {
      debugPrint("Error encoding file to base64: $e");
      return null;
    }
  }

  Future<void> sendMessage(String roomId, ChatMessage message, {String? localPath}) async {
    try {
      String msgId = message.id.isEmpty 
          ? _db.collection('rooms').doc(roomId).collection('messages').doc().id 
          : message.id;

      final finalMessage = ChatMessage(
        id: msgId,
        senderId: message.senderId,
        text: message.text,
        timestamp: message.timestamp.toUtc(),
        status: message.status,
        messageType: message.messageType,
        fileUrl: message.fileUrl,
        fileName: message.fileName,
        localPath: localPath ?? message.localPath,
      );

      // 1. Simpan lokal dulu agar responsif
      await _localDb.saveMessage(roomId, finalMessage);
      notifyUpdate(roomId);

      // 2. Kirim ke Firestore
      final batch = _db.batch();
      final messageRef = _db.collection('rooms').doc(roomId).collection('messages').doc(msgId);
      batch.set(messageRef, finalMessage.toFirestore());

      final roomRef = _db.collection('rooms').doc(roomId);
      String lastMsgDisplay = finalMessage.text;
      if (finalMessage.messageType == 'image') {
        lastMsgDisplay = '📷 Gambar';
      } else if (finalMessage.messageType == 'file') {
        lastMsgDisplay = '📄 Dokumen';
      }
      
      batch.set(roomRef, {
        'last_message': lastMsgDisplay,
        'last_time': Timestamp.fromDate(finalMessage.timestamp),
        'last_senderId': finalMessage.senderId,
      }, SetOptions(merge: true));

      // 3. Notifikasi (Opsional: Bisa dipindah ke Cloud Functions agar lebih efisien)
      final roomDoc = await roomRef.get();
      final data = roomDoc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('members')) {
        List<String> members = List<String>.from(data['members']);
        String recipientId = members.firstWhere((id) => id != message.senderId, orElse: () => '');

        if (recipientId.isNotEmpty) {
          final senderDoc = await _db.collection('users').doc(message.senderId).get();
          final senderName = senderDoc.exists ? (senderDoc.data() as Map<String, dynamic>)['nama'] ?? 'Seseorang' : 'Seseorang';

          final notifRef = _db.collection('notifications').doc();
          batch.set(notifRef, {
            'targetId': recipientId,
            'fromId': message.senderId,
            'title': '💬 Pesan Baru dari $senderName',
            'body': lastMsgDisplay,
            'type': 'chat',
            'roomId': roomId,
            'isRead': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint("Error sending message: $e");
      rethrow;
    }
  }

  Future<void> markMessagesAsRead(String roomId, String currentUserId) async {
    try {
      await _localDb.markMessagesAsRead(roomId, currentUserId);
      
      // Sync ke Firestore: Update kapan terakhir kali SAYA membaca room ini
      await _db.collection('rooms').doc(roomId).set({
        'readStatus': {
          currentUserId: FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
      
      notifyUpdate(roomId);
    } catch (e) {
      debugPrint("Gagal sync read status: $e");
    }
  }

  Future<void> updateMessage(String roomId, String msgId, String newText, String senderId) async {
    try {
      // Update lokal
      await _localDb.updateMessage(msgId, newText);
      notifyUpdate(roomId);

      // Update di cloud
      await _db.collection('rooms').doc(roomId).collection('messages').doc(msgId).set({
        'senderId': senderId,
        'text': newText,
        'status': 'updated',
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Gagal update cloud: $e");
    }
  }

  Future<void> deleteMessage(String roomId, String msgId) async {
    const deletedText = 'Pesan ini telah dihapus';
    try {
      // Update lokal
      await _localDb.updateMessage(msgId, deletedText, status: 'deleted');
      notifyUpdate(roomId);

      // Kirim sinyal 'deleted' ke cloud
      await _db.collection('rooms').doc(roomId).collection('messages').doc(msgId).set({
        'status': 'deleted',
        'text': deletedText,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Gagal kirim sinyal hapus ke cloud: $e");
    }
  }

  Stream<int> getUnreadCount(String roomId, String currentUserId) {
    StreamController<int>? controller;
    StreamSubscription? sub;

    controller = StreamController<int>(
      onListen: () {
        _localDb.getUnreadCount(roomId, currentUserId).then((count) {
          if (!(controller?.isClosed ?? true)) controller?.add(count);
        });

        sub = _messageUpdateController.stream
            .where((id) => id == roomId || id == 'global')
            .listen((_) async {
          final count = await _localDb.getUnreadCount(roomId, currentUserId);
          if (!(controller?.isClosed ?? true)) controller?.add(count);
        });
      },
      onCancel: () {
        sub?.cancel();
        controller?.close();
      }
    );

    return controller.stream;
  }

  Stream<int> getTotalUnreadCountStream(String currentUserId) {
    StreamController<int>? controller;
    StreamSubscription? sub;

    controller = StreamController<int>(
      onListen: () {
        _localDb.getTotalUnreadCount(currentUserId).then((count) {
          if (!(controller?.isClosed ?? true)) controller?.add(count);
        });

        sub = _messageUpdateController.stream.listen((_) async {
          final count = await _localDb.getTotalUnreadCount(currentUserId);
          if (!(controller?.isClosed ?? true)) controller?.add(count);
        });
      },
      onCancel: () {
        sub?.cancel();
        controller?.close();
      }
    );

    return controller.stream;
  }
  
  Stream<DocumentSnapshot> getPeerStatusStream(String peerId) {
    return _db.collection('users').doc(peerId).snapshots();
  }
  
  Future<String> getOrCreateChatRoom(String myId, String peerId) async {
    try {
      List<String> members = [myId, peerId]..sort();
      String deterministicId = members.join('_');
      
      final docRef = _db.collection('rooms').doc(deterministicId);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        await docRef.set({
          'members': members,
          'last_message': 'Memulai percakapan...',
          'last_time': FieldValue.serverTimestamp(),
        });
      }

      ChatRoom room = ChatRoom(
        id: deterministicId, 
        members: members, 
        lastMessage: docSnap.exists ? (docSnap.data() as Map<String, dynamic>)['last_message'] ?? '' : 'Memulai percakapan...', 
        lastTime: docSnap.exists && docSnap.data()?['last_time'] != null 
            ? (docSnap.data()!['last_time'] as Timestamp).toDate() 
            : DateTime.now()
      );
      
      await _localDb.saveChatRoom(room);
      return deterministicId;
    } catch (e) {
      debugPrint("Error getOrCreateChatRoom: $e");
      rethrow;
    }
  }

  Stream<List<ChatRoom>> getChatRooms(String userId) {
    // 1. Dengar Firestore untuk daftar room
    return _db.collection('rooms')
        .where('members', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          bool anyChanges = false;
          for (var doc in snapshot.docs) {
            try {
              ChatRoom room = ChatRoom.fromFirestore(doc);
              await _localDb.saveChatRoom(room);
              
              // Sync pesan hanya jika ada update waktu terakhir
              // Kita bisa bandingkan dengan data lokal untuk efisiensi
              _syncRoomMessages(room.id, userId);
              anyChanges = true;
            } catch (e) {
              debugPrint("Error parsing room: $e");
            }
          }
          
          if (anyChanges) {
            // Jalankan merge duplicate secara background/berkala saja, tidak tiap kali
            _localDb.mergeDuplicateRooms().catchError((_) => null);
          }
          
          return _localDb.getChatRooms();
        });
  }

  Future<void> syncAllRooms(String userId) async {
    try {
      final snapshot = await _db.collection('rooms')
          .where('members', arrayContains: userId)
          .get();
          
      for (var doc in snapshot.docs) {
        ChatRoom room = ChatRoom.fromFirestore(doc);
        await _localDb.saveChatRoom(room);
        await _syncRoomMessages(room.id, userId);
      }
      notifyUpdate('global');
    } catch (e) {
      debugPrint("Error syncAllRooms: $e");
    }
  }

  Future<void> _syncRoomMessages(String roomId, String currentUserId) async {
    if (_activeSyncRooms.contains(roomId)) return;
    _activeSyncRooms.add(roomId);

    try {
      final snapshot = await _db.collection('rooms').doc(roomId).collection('messages').get();
      if (snapshot.docs.isEmpty) return;

      bool hasChanges = false;
      for (var doc in snapshot.docs) {
        if (!doc.exists) continue;
        
        try {
          ChatMessage msg = ChatMessage.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
          
          if (msg.senderId != currentUserId) {
            String? finalLocalPath;
            if (msg.fileUrl != null && msg.fileUrl!.startsWith('data:')) {
              finalLocalPath = await _saveBase64ToFile(msg.fileUrl!, msg.fileName ?? "file_${msg.id}");
            }
            await _localDb.saveMessage(roomId, msg, localPath: finalLocalPath);
            await doc.reference.delete().catchError((_) => null);
            hasChanges = true;
          } else if (msg.status == 'updated' || msg.status == 'deleted') {
            if (msg.status == 'deleted') {
              await _localDb.updateMessage(msg.id, 'Pesan ini telah dihapus', status: 'deleted');
            } else {
              await _localDb.updateMessage(msg.id, msg.text);
            }
            await doc.reference.delete().catchError((_) => null);
            hasChanges = true;
          }
        } catch (e) {
          debugPrint("Error syncing individual message: $e");
        }
      }
      if (hasChanges) {
        notifyUpdate(roomId);
      }
    } catch (e) {
      debugPrint("Error in _syncRoomMessages: $e");
    } finally {
      _activeSyncRooms.remove(roomId);
    }
  }
}
