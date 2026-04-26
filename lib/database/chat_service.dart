import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../models/chat_model.dart';
import 'local_db_service.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalDbService _localDb = LocalDbService();
  final Set<String> _activeSyncRooms = {};

  // StreamController global untuk notifikasi perubahan data lokal ke UI
  final _messageUpdateController = StreamController<String>.broadcast();

  // Mendapatkan daftar pesan secara real-time (Local-First + Auto Delete Cloud)
  Stream<List<ChatMessage>> getMessages(String roomId, String currentUserId) {
    final controller = StreamController<List<ChatMessage>>();
    
    // 1. Ambil pesan lokal segera
    _refreshLocalMessages(roomId, controller);

    // 2. Dengar sinyal perubahan lokal (Internal)
    final localSub = _messageUpdateController.stream.where((id) => id == roomId).listen((_) {
      _refreshLocalMessages(roomId, controller);
    });

    // 3. Dengar Firestore untuk pesan baru dan pembaruan (edit/hapus)
    final firestoreSub = _db.collection('rooms')
        .doc(roomId)
        .collection('messages')
        .snapshots()
        .listen((snapshot) async {
          if (snapshot.docs.isEmpty) return;

          bool hasChanges = false;
          for (var change in snapshot.docChanges) {
            final doc = change.doc;
            if (!doc.exists) continue;
            
            ChatMessage msg = ChatMessage.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
            
            // LOGIKA DIPERKETAT:
            // 1. Jika ini pesan orang lain (pesan masuk baru atau update dari lawan bicara)
            if (msg.senderId != currentUserId) {
              if (msg.status == 'deleted') {
                // Jangan hapus lokal secara fisik, tapi update teks dan statusnya
                await _localDb.updateMessage(msg.id, 'Pesan ini telah dihapus', status: 'deleted');
                doc.reference.delete().catchError((e) => null);
                hasChanges = true;
              } else {
                String? finalLocalPath;
                if (msg.fileUrl != null && msg.fileUrl!.startsWith('data:')) {
                  finalLocalPath = await _saveBase64ToFile(msg.fileUrl!, msg.fileName ?? "file_${msg.id}");
                }

                await _localDb.saveMessage(roomId, msg, localPath: finalLocalPath);
                
                // Jika pesan sudah masuk lokal dan bukan sedang di-update, hapus dari cloud
                if (msg.status != 'updated') {
                  doc.reference.delete().catchError((e) => null);
                }
                hasChanges = true;
              }
            } 
            // 2. Jika ini pesan KITA SENDIRI yang baru saja di-update (sinyal balik dari cloud)
            else if (msg.status == 'updated' || msg.status == 'deleted') {
               doc.reference.delete().catchError((e) => null);
            }
          }

          if (hasChanges) {
            _messageUpdateController.add(roomId);
          }
        });

    controller.onCancel = () {
      localSub.cancel();
      firestoreSub.cancel();
    };
    
    return controller.stream;
  }

  void _refreshLocalMessages(String roomId, StreamController<List<ChatMessage>> controller) async {
    try {
      final msgs = await _localDb.getMessages(roomId);
      if (!controller.isClosed) controller.add(msgs);
    } catch (e) {
      print("Error refresh local: $e");
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
      return null;
    }
  }

  Future<String?> uploadChatFile(String roomId, File file, String type) async {
    try {
      if (!await file.exists()) return null;
      if (file.lengthSync() > 800000) return null; 

      List<int> fileBytes = await file.readAsBytes();
      String base64String = base64Encode(fileBytes);
      
      String ext = p.extension(file.path).replaceAll('.', '');
      if (ext.isEmpty) ext = (type == 'images') ? 'png' : 'bin';
      
      return "data:${type == 'images' ? 'image' : 'application/octet-stream'}/$ext;base64,$base64String";
    } catch (e) {
      return null;
    }
  }

  Future<void> sendMessage(String roomId, ChatMessage message, {String? localPath}) async {
    String msgId = message.id.isEmpty 
        ? _db.collection('rooms').doc(roomId).collection('messages').doc().id 
        : message.id;

    final finalMessage = ChatMessage(
      id: msgId,
      senderId: message.senderId,
      text: message.text,
      timestamp: message.timestamp,
      status: message.status,
      messageType: message.messageType,
      fileUrl: message.fileUrl,
      fileName: message.fileName,
      localPath: localPath ?? message.localPath,
    );

    // Simpan lokal dan beritahu UI
    await _localDb.saveMessage(roomId, finalMessage);
    _messageUpdateController.add(roomId);

    final batch = _db.batch();
    final messageRef = _db.collection('rooms').doc(roomId).collection('messages').doc(msgId);
    batch.set(messageRef, finalMessage.toFirestore());

    final roomRef = _db.collection('rooms').doc(roomId);
    String lastMsgDisplay = finalMessage.text;
    if (finalMessage.messageType == 'image') lastMsgDisplay = '📷 Gambar';
    else if (finalMessage.messageType == 'file') lastMsgDisplay = '📄 Dokumen';
    
    batch.set(roomRef, {
      'last_message': lastMsgDisplay,
      'last_time': Timestamp.fromDate(finalMessage.timestamp),
      'last_senderId': finalMessage.senderId,
    }, SetOptions(merge: true));

    try {
      final roomDoc = await roomRef.get();
      final data = roomDoc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('members')) {
        List<String> members = List<String>.from(data['members']);
        String recipientId = members.firstWhere((id) => id != message.senderId, orElse: () => '');

        if (recipientId.isNotEmpty) {
          DocumentSnapshot senderDoc = await _db.collection('users').doc(message.senderId).get();
          String senderName = senderDoc.exists ? (senderDoc.data() as Map<String, dynamic>)['nama'] ?? 'Seseorang' : 'Seseorang';

          final notifRef = _db.collection('notifications').doc();
          batch.set(notifRef, {
            'targetId': recipientId,
            'fromId': message.senderId,
            'title': '💬 Pesan Baru dari $senderName',
            'body': message.text,
            'type': 'chat',
            'roomId': roomId,
            'isRead': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {}

    await batch.commit();
  }

  Future<void> markMessagesAsRead(String roomId, String currentUserId) async {
    await _localDb.markMessagesAsRead(roomId, currentUserId);
    _messageUpdateController.add(roomId);
  }

  Future<void> updateMessage(String roomId, String msgId, String newText, String senderId) async {
    // Update lokal
    await _localDb.updateMessage(msgId, newText);
    _messageUpdateController.add(roomId);

    // Update di cloud dengan menyertakan senderId agar identitas tidak hilang jika dokumen dibuat ulang
    try {
      await _db.collection('rooms').doc(roomId).collection('messages').doc(msgId).set({
        'senderId': senderId,
        'text': newText,
        'status': 'updated',
        'updateNonce': DateTime.now().millisecondsSinceEpoch.toString(),
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Gagal update cloud: $e");
    }
  }

  Future<void> deleteMessage(String roomId, String msgId) async {
    const deletedText = 'Pesan ini telah dihapus';
    
    // Update lokal: Ubah teks pesan alih-alih menghapusnya
    await _localDb.updateMessage(msgId, deletedText);
    // Kita juga perlu cara untuk menandai status hapus di lokal agar UI tahu
    // Karena kita sudah punya metode updateMessage, kita gunakan itu untuk teksnya dulu
    _messageUpdateController.add(roomId);

    // Kirim sinyal 'deleted' ke cloud agar lawan bicara juga mengubah teks mereka
    try {
      await _db.collection('rooms').doc(roomId).collection('messages').doc(msgId).set({
        'status': 'deleted',
        'text': deletedText,
        'updateNonce': DateTime.now().millisecondsSinceEpoch.toString(),
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Gagal kirim sinyal hapus ke cloud: $e");
    }
  }

  Stream<int> getUnreadCount(String roomId, String currentUserId) {
    // Memberikan update setiap kali ada perubahan pesan
    final controller = StreamController<int>();
    
    _localDb.getUnreadCount(roomId, currentUserId).then((count) {
      if (!controller.isClosed) controller.add(count);
    });

    final sub = _messageUpdateController.stream.where((id) => id == roomId).listen((_) async {
      final count = await _localDb.getUnreadCount(roomId, currentUserId);
      if (!controller.isClosed) controller.add(count);
    });

    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }
  
  Stream<DocumentSnapshot> getPeerStatusStream(String peerId) {
    return _db.collection('users').doc(peerId).snapshots();
  }
  
  Future<String> getOrCreateChatRoom(String myId, String peerId) async {
    List<String> members = [myId, peerId]..sort();
    final query = await _db.collection('rooms').where('members', isEqualTo: members).limit(1).get();

    String roomId;
    ChatRoom room;
    if (query.docs.isNotEmpty) {
      roomId = query.docs.first.id;
      room = ChatRoom.fromFirestore(query.docs.first);
    } else {
      final docRef = _db.collection('rooms').doc();
      roomId = docRef.id;
      await docRef.set({
        'members': members,
        'last_message': 'Memulai percakapan...',
        'last_time': FieldValue.serverTimestamp(),
      });
      room = ChatRoom(id: roomId, members: members, lastMessage: 'Memulai percakapan...', lastTime: DateTime.now());
    }
    await _localDb.saveChatRoom(room);
    return roomId;
  }

  Stream<List<ChatRoom>> getChatRooms(String userId) {
    return _db.collection('rooms')
        .where('members', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          for (var doc in snapshot.docs) {
            ChatRoom room = ChatRoom.fromFirestore(doc);
            await _localDb.saveChatRoom(room);
            _syncRoomMessages(room.id, userId);
          }
          return _localDb.getChatRooms();
        });
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
        
        ChatMessage msg = ChatMessage.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        if (msg.senderId != currentUserId) {
          String? finalLocalPath;
          if (msg.fileUrl != null && msg.fileUrl!.startsWith('data:')) {
            finalLocalPath = await _saveBase64ToFile(msg.fileUrl!, msg.fileName ?? "file_${msg.id}");
          }
          await _localDb.saveMessage(roomId, msg, localPath: finalLocalPath);
          await doc.reference.delete().catchError((e) {});
          hasChanges = true;
        }
      }
      if (hasChanges) {
        _messageUpdateController.add(roomId);
      }
    } catch (e) {} finally {
      _activeSyncRooms.remove(roomId);
    }
  }
}
