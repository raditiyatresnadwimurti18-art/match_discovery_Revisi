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

  static Future<Map<String, dynamic>> ikutiLomba(RiwayatModel riwayat) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        // 1. Gunakan ID Dokumen deterministik untuk cek duplikasi pendaftaran
        // Ini memastikan pengecekan duplikasi aman di dalam transaksi tanpa perlu Query.
        String registrationId = "${riwayat.idUser}_${riwayat.idLomba}";
        DocumentReference riwayatDoc = _riwayatCollection.doc(registrationId);
        DocumentSnapshot riwayatSnap = await transaction.get(riwayatDoc);

        if (riwayatSnap.exists) {
          Map<String, dynamic> existingData = riwayatSnap.data() as Map<String, dynamic>;
          if (existingData['status'] == 'aktif') {
            return {
              'success': false,
              'message': 'Anda sudah terdaftar di lomba ini.',
            };
          }
        }

        // 2. Cek kuota lomba
        DocumentReference lombaRef = _lombaCollection.doc(riwayat.idLomba);
        DocumentSnapshot lombaSnap = await transaction.get(lombaRef);

        if (!lombaSnap.exists) {
          return {
            'success': false,
            'message': 'Lomba tidak ditemukan atau sudah ditutup.',
          };
        }

        Map<String, dynamic> lombaData = lombaSnap.data() as Map<String, dynamic>;
        
        // Penanganan tipe data kuota yang lebih aman (casting/parsing)
        int currentKuota = 0;
        if (lombaData['kuota'] != null) {
          if (lombaData['kuota'] is int) {
            currentKuota = lombaData['kuota'];
          } else {
            currentKuota = int.tryParse(lombaData['kuota'].toString()) ?? 0;
          }
        }

        if (currentKuota <= 0) {
          return {
            'success': false,
            'message': 'Maaf, kuota lomba sudah penuh.',
          };
        }

        // 3. Generate Token Unik
        String token = "TKN-${riwayatDoc.id.substring(0, 8).toUpperCase()}";
        String judulLomba = lombaData['judul'] ?? 'Lomba';

        // 4. Kurangi Kuota
        int newKuota = currentKuota - 1;
        transaction.update(lombaRef, {'kuota': newKuota});

        // 5. Simpan ke Riwayat (menggunakan ID deterministik agar tidak duplikat)
        transaction.set(riwayatDoc, {
          'id': registrationId,
          'idUser': riwayat.idUser,
          'idLomba': riwayat.idLomba,
          'tanggalDaftar': riwayat.tanggalDaftar ?? DateTime.now().toIso8601String(),
          'status': 'aktif',
          'token': token,
          'judulLomba': judulLomba,
        });

        // 6. Jika kuota habis, pindahkan ke riwayatEvent (Selesai) sesuai permintaan
        if (newKuota <= 0) {
          lombaData['idLombaAsli'] = lombaSnap.id;
          lombaData['statusLomba'] = 'Penuh/Selesai';
          lombaData['kuota'] = 0; // Pastikan kuota tercatat 0
          
          transaction.set(_riwayatEventCollection.doc(lombaSnap.id), lombaData);
          transaction.delete(lombaRef);
        }

        return {
          'success': true,
          'message': 'Pendaftaran berhasil!',
          'token': token,
          'data': {
            'judul': judulLomba,
            'lokasi': lombaData['lokasi'] ?? '-',
            'tanggal': lombaData['tanggal'] ?? '-',
          }
        };
      });
    } catch (e) {
      print("Error ikutiLomba: $e");
      return {
        'success': false,
        'message': 'Terjadi kesalahan sistem: $e',
      };
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

  static Stream<List<RiwayatSelesaiModel>> getRiwayatSelesaiStream() {
    return _riwayatSelesaiCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return RiwayatSelesaiModel.fromMap(doc.data() as Map<String, dynamic>,
            docId: doc.id);
      }).toList();
    });
  }

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
          .get();

      List<Map<String, dynamic>> results = snap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      
      // Urutkan di memori berdasarkan tanggalSelesai descending
      results.sort((a, b) {
        String tglA = a['tanggalSelesai'] ?? '';
        String tglB = b['tanggalSelesai'] ?? '';
        return tglB.compareTo(tglA);
      });

      return results;
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
