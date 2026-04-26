import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final List<String> members;
  final String lastMessage;
  final DateTime lastTime;
  final String? lastSenderId;

  ChatRoom({
    required this.id,
    required this.members,
    required this.lastMessage,
    required this.lastTime,
    this.lastSenderId,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      members: List<String>.from(data['members'] ?? []),
      lastMessage: data['last_message'] ?? '',
      lastTime: data['last_time'] != null 
          ? (data['last_time'] as Timestamp).toDate().toUtc() 
          : DateTime.now().toUtc(),
      lastSenderId: data['last_senderId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'members': members,
      'last_message': lastMessage,
      'last_time': Timestamp.fromDate(lastTime),
      'last_senderId': lastSenderId,
    };
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String status; // 'sent', 'read'
  final String messageType; // 'text', 'image', 'file'
  final String? fileUrl;
  final String? fileName;
  final String? localPath;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.status = 'sent',
    this.messageType = 'text',
    this.fileUrl,
    this.fileName,
    this.localPath,
  });

  factory ChatMessage.fromFirestore(Map<String, dynamic> data, [String? docId]) {
    dynamic ts = data['timestamp'];
    DateTime parsedTime;
    
    if (ts is Timestamp) {
      parsedTime = ts.toDate().toUtc();
    } else if (ts is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true).toUtc();
    } else {
      parsedTime = DateTime.now().toUtc();
    }

    return ChatMessage(
      id: docId ?? data['id'] ?? '',
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: parsedTime,
      status: data['status'] ?? 'sent',
      messageType: data['messageType'] ?? 'text',
      fileUrl: data['fileUrl'] ?? data['imageUrl'],
      fileName: data['fileName'],
      localPath: data['localPath'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'messageType': messageType,
      'fileUrl': fileUrl,
      'fileName': fileName,
      // localPath tidak dikirim ke firestore karena path tiap HP berbeda
    };
  }
}
