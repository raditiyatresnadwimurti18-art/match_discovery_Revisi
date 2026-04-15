import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:match_discovery/models/lomba_model.dart';

class LombaController {
  static final CollectionReference _lombaCollection =
      FirebaseFirestore.instance.collection('lomba');

  // ==================== CREATE ====================

  static Future<void> insertLomba(LombaModel data) async {
    try {
      await _lombaCollection.add(data.toMap());
    } catch (e) {
      print("Error insertLomba: $e");
    }
  }

  // ==================== READ ====================

  static Future<List<LombaModel>> getAllLomba() async {
    try {
      QuerySnapshot querySnapshot = await _lombaCollection.get();
      return querySnapshot.docs
          .map((doc) => LombaModel.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id))
          .toList();
    } catch (e) {
      print("Error getAllLomba: $e");
      return [];
    }
  }

  // ==================== UPDATE ====================

  static Future<void> updateLomba(LombaModel data) async {
    if (data.id == null) throw Exception("Gagal Update: ID Lomba tidak ditemukan");
    try {
      await _lombaCollection.doc(data.id).update(data.toMap());
    } catch (e) {
      print("Error updateLomba: $e");
    }
  }

  // ==================== DELETE ====================

  static Future<void> deleteLomba(String id) async {
    try {
      await _lombaCollection.doc(id).delete();
    } catch (e) {
      print("Error deleteLomba: $e");
    }
  }
}
