class RelationshipModel {
  String? id;
  String fromId;
  String toId;
  String status; // 'following', 'friend_request', 'friends'
  String timestamp;

  RelationshipModel({
    this.id,
    required this.fromId,
    required this.toId,
    required this.status,
    required this.timestamp,
  });

  factory RelationshipModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return RelationshipModel(
      id: docId ?? map['id'],
      fromId: map['fromId'],
      toId: map['toId'],
      status: map['status'],
      timestamp: map['timestamp'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromId': fromId,
      'toId': toId,
      'status': status,
      'timestamp': timestamp,
    };
  }
}
