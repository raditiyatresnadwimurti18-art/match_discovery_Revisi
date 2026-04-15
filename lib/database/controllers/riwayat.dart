import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:match_discovery/models/riwayat_model.dart';
import 'package:match_discovery/models/riwayat_selesai_user.dart';

class RiwayatController {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _riwayatCollection = _firestore.collection('riwayat');
  static final CollectionReference _lombaCollection = _firestore.collection('lomba');
  static final CollectionReference _riwayatSelesaiCollection = _firestore.collection('riwayatSelesai');
  static final CollectionReference _riwayatEventCollection = _firestore.collection('riwayatEvent');

  // ==================== PENDAFTARAN ====================

  static Future<void> ikutiLomba(RiwayatModel riwayat) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Check if already following
        QuerySnapshot check = await _riwayatCollection
            .where('idUser', isEqualTo: riwayat.idUser)
            .where('idLomba', isEqualTo: riwayat.idLomba)
            .where('status', isEqualTo: 'aktif')
            .get();

        if (check.docs.isNotEmpty) return;

        // Add to riwayat
        DocumentReference riwayatDoc = _riwayatCollection.doc();
        transaction.set(riwayatDoc, {
          'idUser': riwayat.idUser,
          'idLomba': riwayat.idLomba,
          'tanggalDaftar': riwayat.tanggalDaftar ?? DateTime.now().toString(),
          'status': 'aktif',
        });

        // Update kuota in lomba
        DocumentReference lombaRef = _lombaCollection.doc(riwayat.idLomba);
        DocumentSnapshot lombaSnap = await transaction.get(lombaRef);

        if (lombaSnap.exists) {
          int newKuota = (lombaSnap.get('kuota') as int) - 1;
          transaction.update(lombaRef, {'kuota': newKuota});

          if (newKuota <= 0) {
            Map<String, dynamic> lombaData = lombaSnap.data() as Map<String, dynamic>;
            lombaData['idLombaAsli'] = lombaSnap.id;
            lombaData.remove('kuota');

            // Move to riwayatEvent
            transaction.set(_riwayatEventCollection.doc(lombaSnap.id), lombaData);
            // Delete from lomba
            transaction.delete(lombaRef);
          }
        }
      });
    } catch (e) {
      print("Error ikutiLomba: $e");
    }
  }

  static Future<bool> isUserSedangIkutLomba(String userId, String lombaId) async {
    try {
      QuerySnapshot result = await _riwayatCollection
          .where('idUser', isEqualTo: userId)
          .where('idLomba', isEqualTo: lombaId)
          .where('status', isEqualTo: 'aktif')
          .get();
      return result.docs.isNotEmpty;
    } catch (e) {
      print("Error isUserSedangIkutLomba: $e");
      return false;
    }
  }

  static Future<void> konfirmasiSelesaiManual(String userId, String lombaId) async {
    try {
      // Update status in riwayat
      QuerySnapshot riwayatSnap = await _riwayatCollection
          .where('idUser', isEqualTo: userId)
          .where('idLomba', isEqualTo: lombaId)
          .get();

      for (var doc in riwayatSnap.docs) {
        await doc.reference.update({'status': 'selesai'});
      }

      // Get Lomba title
      String? judulLomba;
      DocumentSnapshot lombaSnap = await _lombaCollection.doc(lombaId).get();
      if (lombaSnap.exists) {
        judulLomba = lombaSnap.get('judul') as String?;
      } else {
        DocumentSnapshot eventSnap = await _riwayatEventCollection.doc(lombaId).get();
        if (eventSnap.exists) {
          judulLomba = eventSnap.get('judul') as String?;
        }
      }

      // Insert to riwayatSelesai
      await _riwayatSelesaiCollection.add(RiwayatSelesaiModel(
        idUser: userId,
        judulLomba: judulLomba ?? 'Tidak Diketahui',
        tanggalSelesai: DateTime.now().toIso8601String().split('T').first,
      ).toMap());
    } catch (e) {
      print("Error konfirmasiSelesaiManual: $e");
    }
  }

  // ==================== RIWAYAT USER ====================

  static Future<List<Map<String, dynamic>>> getRiwayatUser(String userId) async {
    try {
      QuerySnapshot riwayatSnap = await _riwayatCollection
          .where('idUser', isEqualTo: userId)
          .where('status', isEqualTo: 'aktif')
          .get();

      List<Map<String, dynamic>> results = [];

      for (var doc in riwayatSnap.docs) {
        Map<String, dynamic> riwayatData = doc.data() as Map<String, dynamic>;
        String lombaId = riwayatData['idLomba'];

        DocumentSnapshot lombaSnap = await _lombaCollection.doc(lombaId).get();
        Map<String, dynamic>? detail;
        
        if (lombaSnap.exists) {
          detail = lombaSnap.data() as Map<String, dynamic>?;
        } else {
          DocumentSnapshot eventSnap = await _riwayatEventCollection.doc(lombaId).get();
          if (eventSnap.exists) {
            detail = eventSnap.data() as Map<String, dynamic>?;
          }
        }

        if (detail != null) {
          results.add({
            'idRiwayat': doc.id,
            'idLomba': lombaId,
            'status': riwayatData['status'],
            'judul': detail['judul'],
            'lokasi': detail['lokasi'],
            'tanggal': detail['tanggal'],
            'gambarPath': detail['gambarPath'],
          });
        }
      }
      return results;
    } catch (e) {
      print("Error getRiwayatUser: $e");
      return [];
    }
  }

  // ==================== TRACK RECORD ====================

  static Future<List<Map<String, dynamic>>> getTrackRecordUser(String userId) async {
    try {
      QuerySnapshot snap = await _riwayatSelesaiCollection
          .where('idUser', isEqualTo: userId)
          .get();

      Map<String, List<String>> grouped = {};
      for (var doc in snap.docs) {
        String judul = doc.get('judulLomba');
        String tanggal = doc.get('tanggalSelesai');
        if (!grouped.containsKey(judul)) {
          grouped[judul] = [];
        }
        grouped[judul]!.add(tanggal);
      }

      List<Map<String, dynamic>> results = [];
      grouped.forEach((judul, tanggals) {
        tanggals.sort((a, b) => b.compareTo(a));
        results.add({
          'judulLomba': judul,
          'jumlahIkut': tanggals.length,
          'terakhirIkut': tanggals.first,
        });
      });

      results.sort((a, b) => (b['jumlahIkut'] as int).compareTo(a['jumlahIkut'] as int));
      return results;
    } catch (e) {
      print("Error getTrackRecordUser: $e");
      return [];
    }
  }

  static Future<int> getTotalSelesaiUser(String userId) async {
    try {
      AggregateQuerySnapshot count = await _riwayatSelesaiCollection
          .where('idUser', isEqualTo: userId)
          .count()
          .get();
      return count.count ?? 0;
    } catch (e) {
      print("Error getTotalSelesaiUser: $e");
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> getTrackRecordPerLomba(String userId) async {
    try {
      QuerySnapshot snap = await _riwayatSelesaiCollection
          .where('idUser', isEqualTo: userId)
          .orderBy('tanggalSelesai', descending: true)
          .get();

      return snap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error getTrackRecordPerLomba: $e");
      return [];
    }
  }

  // ==================== RIWAYAT EVENT ====================

  static Future<List<Map<String, dynamic>>> getRiwayatEvent() async {
    try {
      QuerySnapshot snap = await _riwayatEventCollection.get();
      return snap.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print("Error getRiwayatEvent: $e");
      return [];
    }
  }

  static Future<void> deleteRiwayatEvent(String id) async {
    try {
      await _riwayatEventCollection.doc(id).delete();
    } catch (e) {
      print("Error deleteRiwayatEvent: $e");
    }
  }

  static Future<void> deleteAllRiwayatEvent() async {
    try {
      QuerySnapshot snap = await _riwayatEventCollection.get();
      for (var doc in snap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print("Error deleteAllRiwayatEvent: $e");
    }
  }
}
