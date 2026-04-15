import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Pusat layanan Firebase untuk seluruh aplikasi.
/// Memisahkan logika infrastruktur Firebase dari logika bisnis (Controller).
class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Collections ────────────────────────────────────────────────────────
  static CollectionReference get users => _db.collection('users');
  static CollectionReference get lomba => _db.collection('lomba');
  static CollectionReference get riwayat => _db.collection('riwayat');

  // ── Auth ───────────────────────────────────────────────────────────────
  static FirebaseAuth get auth => _auth;
  static User? get currentUser => _auth.currentUser;

  // ── Helper Methods ─────────────────────────────────────────────────────
  
  /// Mengambil satu dokumen berdasarkan ID
  static Future<DocumentSnapshot> getDoc(CollectionReference collection, String id) {
    return collection.doc(id).get();
  }

  /// Menambah dokumen baru dan menyisipkan ID-nya ke dalam field 'id'
  static Future<String> addDoc(CollectionReference collection, Map<String, dynamic> data) async {
    DocumentReference doc = await collection.add(data);
    await doc.update({'id': doc.id});
    return doc.id;
  }

  /// Update dokumen
  static Future<void> updateDoc(CollectionReference collection, String id, Map<String, dynamic> data) {
    return collection.doc(id).update(data);
  }

  /// Hapus dokumen
  static Future<void> deleteDoc(CollectionReference collection, String id) {
    return collection.doc(id).delete();
  }
}
