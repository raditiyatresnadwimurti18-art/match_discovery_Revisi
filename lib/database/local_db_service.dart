import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/chat_model.dart';

class LocalDbService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'chat_database.db');
    return await openDatabase(
      path,
      version: 3, // Naikkan versi untuk skema readStatus
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('DROP TABLE IF EXISTS messages');
          await db.execute('DROP TABLE IF EXISTS chat_rooms');
          await _createTables(db);
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE chat_rooms(
        id TEXT PRIMARY KEY,
        members TEXT,
        last_message TEXT,
        last_time INTEGER,
        last_senderId TEXT,
        read_status_json TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE messages(
        id TEXT PRIMARY KEY,
        room_id TEXT,
        senderId TEXT,
        text TEXT,
        timestamp INTEGER,
        status TEXT,
        messageType TEXT,
        fileUrl TEXT,
        fileName TEXT,
        localPath TEXT
      )
    ''');
  }

  // === Chat Room Operations ===

  Future<void> saveChatRoom(ChatRoom room) async {
    final db = await database;
    List<String> sortedMembers = List.from(room.members)..sort();

    Map<String, int> jsonMap = {};
    room.readStatus.forEach((key, value) {
      jsonMap[key] = value.millisecondsSinceEpoch;
    });
    
    await db.insert(
      'chat_rooms',
      {
        'id': room.id,
        'members': sortedMembers.join(','),
        'last_message': room.lastMessage,
        'last_time': room.lastTime.millisecondsSinceEpoch,
        'last_senderId': room.lastSenderId,
        'read_status_json': jsonEncode(jsonMap),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> mergeDuplicateRooms() async {
    final db = await database;
    try {
      // Cari group members yang punya lebih dari 1 room_id
      final List<Map<String, dynamic>> duplicates = await db.rawQuery('''
        SELECT members, COUNT(*) as count 
        FROM chat_rooms 
        GROUP BY members 
        HAVING count > 1
      ''');

      if (duplicates.isEmpty) return;

      await db.transaction((txn) async {
        for (var dup in duplicates) {
          String members = dup['members'];
          // Ambil semua room untuk members ini, urutkan dari yang terbaru
          final List<Map<String, dynamic>> rooms = await txn.query(
            'chat_rooms',
            where: 'members = ?',
            whereArgs: [members],
            orderBy: 'last_time DESC',
          );

          if (rooms.length > 1) {
            String primaryId = rooms[0]['id'];
            
            for (int i = 1; i < rooms.length; i++) {
              String oldId = rooms[i]['id'];
              // Pindahkan semua pesan ke room utama
              await txn.rawUpdate(
                'UPDATE messages SET room_id = ? WHERE room_id = ?',
                [primaryId, oldId]
              );
              // Hapus room duplikat
              await txn.delete('chat_rooms', where: 'id = ?', whereArgs: [oldId]);
            }
          }
        }
      });
    } catch (e) {
      debugPrint("Error merging duplicate rooms: $e");
    }
  }

  Future<List<ChatRoom>> getChatRooms() async {
    final db = await database;
    try {
      // Query yang lebih sederhana dan efisien untuk mengambil room terbaru per grup member
      final List<Map<String, dynamic>> maps = await db.query(
        'chat_rooms',
        orderBy: 'last_time DESC',
      );
      
      return List.generate(maps.length, (i) {
        Map<String, DateTime> readStatus = {};
        if (maps[i]['read_status_json'] != null) {
          try {
            Map<String, dynamic> jsonMap = jsonDecode(maps[i]['read_status_json']);
            jsonMap.forEach((key, value) {
              readStatus[key] = DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
            });
          } catch (e) {}
        }

        return ChatRoom(
          id: maps[i]['id'],
          members: (maps[i]['members'] as String).split(','),
          lastMessage: maps[i]['last_message'] ?? '',
          lastTime: DateTime.fromMillisecondsSinceEpoch(maps[i]['last_time'] ?? 0, isUtc: true),
          lastSenderId: maps[i]['last_senderId'],
          readStatus: readStatus,
        );
      });
    } catch (e) {
      debugPrint("Error getting chat rooms: $e");
      return [];
    }
  }

  // === Message Operations ===

  Future<void> saveMessage(String roomId, ChatMessage message, {String? localPath}) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'messages',
        {
          'id': message.id,
          'room_id': roomId,
          'senderId': message.senderId,
          'text': message.text,
          'timestamp': message.timestamp.millisecondsSinceEpoch,
          'status': message.status,
          'messageType': message.messageType,
          'fileUrl': message.fileUrl,
          'fileName': message.fileName,
          'localPath': localPath ?? message.localPath,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      String lastMsgDisplay = message.text;
      if (message.messageType == 'image') lastMsgDisplay = '📷 Gambar';
      else if (message.messageType == 'file') lastMsgDisplay = '📄 Dokumen';

      await txn.update(
        'chat_rooms',
        {
          'last_message': lastMsgDisplay,
          'last_time': message.timestamp.millisecondsSinceEpoch,
          'last_senderId': message.senderId,
        },
        where: 'id = ?',
        whereArgs: [roomId],
      );
    });
  }

  Future<List<ChatMessage>> getMessages(String roomId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'room_id = ?',
      whereArgs: [roomId],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return ChatMessage(
        id: maps[i]['id'],
        senderId: maps[i]['senderId'],
        text: maps[i]['text'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp'], isUtc: true),
        status: maps[i]['status'],
        messageType: maps[i]['messageType'],
        fileUrl: maps[i]['fileUrl'],
        fileName: maps[i]['fileName'],
        localPath: maps[i]['localPath'],
      );
    });
  }

  Future<void> markMessagesAsRead(String roomId, String currentUserId) async {
    final db = await database;
    await db.update(
      'messages',
      {'status': 'read'},
      where: 'room_id = ? AND senderId != ? AND status = ?',
      whereArgs: [roomId, currentUserId, 'sent'],
    );
  }

  Future<int> getUnreadCount(String roomId, String currentUserId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM messages WHERE room_id = ? AND senderId != ? AND status = ?',
      [roomId, currentUserId, 'sent']
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalUnreadCount(String currentUserId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM messages WHERE senderId != ? AND status = ?',
      [currentUserId, 'sent']
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> updateMessage(String msgId, String newText, {String? status}) async {
    final db = await database;
    Map<String, dynamic> data = {'text': newText};
    if (status != null) data['status'] = status;
    await db.update('messages', data, where: 'id = ?', whereArgs: [msgId]);
  }

  Future<void> deleteMessage(String msgId) async {
    final db = await database;
    await db.delete('messages', where: 'id = ?', whereArgs: [msgId]);
  }
}
