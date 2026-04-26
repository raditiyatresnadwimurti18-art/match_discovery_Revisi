import 'dart:async';
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
      version: 2, // Upgrade version to trigger onUpgrade
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Drop and recreate to fix schema issues
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
        last_senderId TEXT
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
    await db.insert(
      'chat_rooms',
      {
        'id': room.id,
        'members': room.members.join(','),
        'last_message': room.lastMessage,
        'last_time': room.lastTime.millisecondsSinceEpoch,
        'last_senderId': room.lastSenderId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatRoom>> getChatRooms() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('chat_rooms', orderBy: 'last_time DESC');
    
    return List.generate(maps.length, (i) {
      return ChatRoom(
        id: maps[i]['id'],
        members: (maps[i]['members'] as String).split(','),
        lastMessage: maps[i]['last_message'],
        lastTime: DateTime.fromMillisecondsSinceEpoch(maps[i]['last_time']),
        lastSenderId: maps[i]['last_senderId'],
      );
    });
  }

  // === Message Operations ===

  Future<void> saveMessage(String roomId, ChatMessage message, {String? localPath}) async {
    final db = await database;
    
    // Ensure we are sending 10 values to match the 10 columns defined in onCreate
    await db.insert(
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

    // Update last message in room
    await db.update(
      'chat_rooms',
      {
        'last_message': message.messageType == 'text' ? message.text : (message.messageType == 'image' ? '📷 Gambar' : '📄 Dokumen'),
        'last_time': message.timestamp.millisecondsSinceEpoch,
        'last_senderId': message.senderId,
      },
      where: 'id = ?',
      whereArgs: [roomId],
    );
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

  Future<void> updateMessage(String msgId, String newText, {String? status}) async {
    final db = await database;
    Map<String, dynamic> data = {'text': newText};
    if (status != null) data['status'] = status;
    
    await db.update(
      'messages',
      data,
      where: 'id = ?',
      whereArgs: [msgId],
    );
  }

  Future<void> deleteMessage(String msgId) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [msgId],
    );
  }
}
