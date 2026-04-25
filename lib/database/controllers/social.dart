import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:match_discovery/models/login_model.dart';

class SocialController {
  static final CollectionReference _relationshipsCollection =
      FirebaseFirestore.instance.collection('relationships');
  static final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  // Follow user
  static Future<void> followUser(String fromId, String toId) async {
    String docId = "${fromId}_$toId";
    
    // Get follower info
    DocumentSnapshot followerSnap = await _usersCollection.doc(fromId).get();
    String followerName = followerSnap.exists ? (followerSnap.data() as Map<String, dynamic>)['nama'] ?? 'Seseorang' : 'Seseorang';

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // 1. Create relationship
      transaction.set(_relationshipsCollection.doc(docId), {
        'fromId': fromId,
        'toId': toId,
        'status': 'following',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // 2. Create notification
      transaction.set(FirebaseFirestore.instance.collection('notifications').doc(), {
        'targetId': toId,
        'fromId': fromId,
        'title': '👤 Pengikut Baru!',
        'body': '$followerName mulai mengikuti kamu',
        'type': 'follow',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  // Unfollow user
  static Future<void> unfollowUser(String fromId, String toId) async {
    String docId = "${fromId}_$toId";
    await _relationshipsCollection.doc(docId).delete();
  }

  // Get following list
  static Stream<List<LoginModel>> getFollowingStream(String userId) {
    return _relationshipsCollection
        .where('fromId', isEqualTo: userId)
        .where('status', isEqualTo: 'following')
        .snapshots()
        .asyncMap((snapshot) async {
      List<String> followingIds = snapshot.docs.map((doc) => doc['toId'] as String).toList();
      if (followingIds.isEmpty) return [];
      
      // Firestore Limit: 'whereIn' maksimal 30 item.
      // Jika lebih dari 30, perlu dipecah menjadi beberapa query.
      List<String> limitedIds = followingIds.take(30).toList();
      
      QuerySnapshot userSnap = await _usersCollection
          .where(FieldPath.documentId, whereIn: limitedIds)
          .get();
          
      return userSnap.docs.map((doc) => LoginModel.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id)).toList();
    });
  }

  // Get followers list
  static Stream<List<LoginModel>> getFollowersStream(String userId) {
    return _relationshipsCollection
        .where('toId', isEqualTo: userId)
        .where('status', isEqualTo: 'following')
        .snapshots()
        .asyncMap((snapshot) async {
      List<String> followerIds = snapshot.docs.map((doc) => doc['fromId'] as String).toList();
      if (followerIds.isEmpty) return [];
      
      // Firestore Limit: 'whereIn' maksimal 30 item.
      List<String> limitedIds = followerIds.take(30).toList();
      
      QuerySnapshot userSnap = await _usersCollection
          .where(FieldPath.documentId, whereIn: limitedIds)
          .get();
          
      return userSnap.docs.map((doc) => LoginModel.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id)).toList();
    });
  }

  // Search users - Google-like "Contains" logic
  static Future<List<LoginModel>> searchUsers(String query, String currentUserId) async {
    if (query.isEmpty) return [];
    
    String lowercaseQuery = query.toLowerCase();
    
    // Step 1: Ambil semua user (atau limit yang besar) dengan role 'user'
    // Menggunakan query tunggal 'role' agar tidak butuh composite index manual
    QuerySnapshot snap = await _usersCollection
        .where('role', isEqualTo: 'user')
        .limit(200) // Ambil cukup banyak data untuk difilter
        .get();
        
    // Step 2: Filter logic "Google-style" (Substring match)
    return snap.docs
        .map((doc) => LoginModel.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id))
        .where((user) {
          if (user.id == currentUserId) return false;
          
          final name = (user.nama ?? "").toLowerCase();
          final email = (user.email ?? "").toLowerCase();
          final school = (user.asalSekolah ?? "").toLowerCase();
          final city = (user.asalKota ?? "").toLowerCase();
          
          // Bisa mencari di nama, email, sekolah, atau kota sekaligus
          return name.contains(lowercaseQuery) || 
                 email.contains(lowercaseQuery) || 
                 school.contains(lowercaseQuery) ||
                 city.contains(lowercaseQuery);
        })
        .toList();
  }

  // Get relationship status
  static Future<bool> isFollowing(String fromId, String toId) async {
    DocumentSnapshot followSnap = await _relationshipsCollection.doc("${fromId}_$toId").get();
    return followSnap.exists;
  }

  static Future<int> getFollowersCount(String userId) async {
    AggregateQuerySnapshot snap = await _relationshipsCollection
        .where('toId', isEqualTo: userId)
        .where('status', isEqualTo: 'following')
        .count()
        .get();
    return snap.count ?? 0;
  }

  static Future<int> getFollowingCount(String userId) async {
    AggregateQuerySnapshot snap = await _relationshipsCollection
        .where('fromId', isEqualTo: userId)
        .where('status', isEqualTo: 'following')
        .count()
        .get();
    return snap.count ?? 0;
  }

  static Stream<int> getFollowersCountStream(String userId) {
    return _relationshipsCollection
        .where('toId', isEqualTo: userId)
        .where('status', isEqualTo: 'following')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  static Stream<int> getFollowingCountStream(String userId) {
    return _relationshipsCollection
        .where('fromId', isEqualTo: userId)
        .where('status', isEqualTo: 'following')
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
