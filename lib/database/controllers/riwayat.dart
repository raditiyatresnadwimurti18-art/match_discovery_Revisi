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

  static Future<Map<String, dynamic>> ikutiLomba(RiwayatModel riwayat, {bool reduceKuota = true}) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        // 1. Gunakan ID Dokumen deterministik untuk cek duplikasi pendaftaran
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

        // 2. Ambil detail lomba
        DocumentReference lombaRef = _lombaCollection.doc(riwayat.idLomba);
        DocumentSnapshot lombaSnap = await transaction.get(lombaRef);

        if (!lombaSnap.exists) {
          return {
            'success': false,
            'message': 'Lomba tidak ditemukan atau sudah ditutup.',
          };
        }

        Map<String, dynamic> lombaData = lombaSnap.data() as Map<String, dynamic>;
        
        // Penanganan tipe data kuota
        int currentKuota = 0;
        if (lombaData['kuota'] != null) {
          if (lombaData['kuota'] is int) {
            currentKuota = lombaData['kuota'];
          } else {
            currentKuota = int.tryParse(lombaData['kuota'].toString()) ?? 0;
          }
        }

        // 3. Generate Token Unik
        String token = "TKN-${riwayatDoc.id.substring(0, 8).toUpperCase()}";
        String judulLomba = lombaData['judul'] ?? 'Lomba';

        // 4. Kurangi Kuota (Hanya jika reduceKuota true)
        int newKuota = currentKuota;
        if (reduceKuota) {
          if (currentKuota <= 0) {
            return {
              'success': false,
              'message': 'Maaf, kuota sudah penuh.',
            };
          }
          newKuota = currentKuota - 1;
          transaction.update(lombaRef, {'kuota': newKuota});
        }

        // 5. Simpan ke Riwayat
        transaction.set(riwayatDoc, {
          'id': registrationId,
          'idUser': riwayat.idUser,
          'idLomba': riwayat.idLomba,
          'tanggalDaftar': riwayat.tanggalDaftar ?? DateTime.now().toIso8601String(),
          'status': 'aktif',
          'token': token,
          'judulLomba': judulLomba,
          'idKelompok': riwayat.idKelompok,
        });

        // 6. Jika kuota habis (setelah dikurangi), pindahkan ke riwayatEvent
        if (reduceKuota && newKuota <= 0) {
          lombaData['idLombaAsli'] = lombaSnap.id;
          lombaData['statusLomba'] = 'Penuh/Selesai';
          lombaData['kuota'] = 0;
          
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

  static Future<void> konfirmasiSelesaiKelompok(String idKelompok, String idLomba) async {
    try {
      final WriteBatch batch = _firestore.batch();
      
      // 1. Cari semua riwayat yang terkait dengan kelompok ini (tanpa filter lomba agar lebih pasti)
      QuerySnapshot riwayatSnap = await _riwayatCollection
          .where('idKelompok', isEqualTo: idKelompok)
          .where('status', isEqualTo: 'aktif')
          .get();

      if (riwayatSnap.docs.isEmpty) {
        print("Peringatan: Tidak ada riwayat aktif ditemukan untuk kelompok $idKelompok");
      }

      // 2. Ambil detail lomba (judul)
      String judulLomba = 'Lomba Tidak Diketahui';
      DocumentSnapshot lombaSnap = await _lombaCollection.doc(idLomba).get();
      if (lombaSnap.exists) {
        judulLomba = lombaSnap.get('judul') as String;
      } else {
        DocumentSnapshot eventSnap = await _riwayatEventCollection.doc(idLomba).get();
        if (eventSnap.exists) {
          judulLomba = eventSnap.get('judul') as String;
        }
      }

      final tanggalSelesai = DateTime.now().toIso8601String().split('T').first;

      // 3. Proses setiap anggota dalam riwayat
      for (var doc in riwayatSnap.docs) {
        // Update status di riwayat jadi 'selesai'
        batch.update(doc.reference, {'status': 'selesai'});

        // Tambahkan ke riwayatSelesai untuk setiap anggota
        String userId = doc.get('idUser');
        DocumentReference newSelesaiRef = _riwayatSelesaiCollection.doc();
        batch.set(newSelesaiRef, {
          'idUser': userId,
          'judulLomba': judulLomba,
          'tanggalSelesai': tanggalSelesai,
          'jenisLomba': 'Kelompok',
          'idKelompok': idKelompok,
        });
      }

      // 4. Hapus dokumen kelompok agar hilang dari halaman "Kelompok Saya"
      batch.delete(_firestore.collection('kelompok').doc(idKelompok));

      // Eksekusi Batch
      await batch.commit();
      print("Berhasil menyelesaikan kelompok $idKelompok");
    } catch (e) {
      print("Error konfirmasiSelesaiKelompok: $e");
      throw Exception("Gagal menyelesaikan kelompok: $e");
    }
  }

  static Future<bool> konfirmasiSelesaiManual(String userId, String lombaId) async {
    try {
      final WriteBatch batch = _firestore.batch();
      
      // Update status in riwayat
      QuerySnapshot riwayatSnap = await _riwayatCollection
          .where('idUser', isEqualTo: userId)
          .where('idLomba', isEqualTo: lombaId)
          .where('status', isEqualTo: 'aktif')
          .get();

      if (riwayatSnap.docs.isEmpty) return false;

      for (var doc in riwayatSnap.docs) {
        batch.update(doc.reference, {'status': 'selesai'});
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
      DocumentReference newSelesaiRef = _riwayatSelesaiCollection.doc();
      batch.set(newSelesaiRef, RiwayatSelesaiModel(
        idUser: userId,
        judulLomba: judulLomba ?? 'Tidak Diketahui',
        tanggalSelesai: DateTime.now().toIso8601String().split('T').first,
        jenisLomba: 'Individual',
      ).toMap());

      await batch.commit();
      return true;
    } catch (e) {
      print("Error konfirmasiSelesaiManual: $e");
      return false;
    }
  }

  static Future<List<RiwayatModel>> getRiwayatByUserId(String userId) async {
    try {
      QuerySnapshot snap = await _riwayatCollection
          .where('idUser', isEqualTo: userId)
          .get();
      return snap.docs.map((doc) => RiwayatModel.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id)).toList();
    } catch (e) {
      print("Error getRiwayatByUserId: $e");
      return [];
    }
  }

  // ==================== RIWAYAT USER (REAL-TIME) ====================

  static Stream<List<Map<String, dynamic>>> getRiwayatUserStream(String userId) {
    // Memantau riwayat aktif secara real-time
    return _riwayatCollection
        .where('idUser', isEqualTo: userId)
        .where('status', isEqualTo: 'aktif')
        .snapshots()
        .asyncMap((riwayatSnap) async {
      
      List<Map<String, dynamic>> results = [];
      
      List<Future<void>> futures = riwayatSnap.docs.map((doc) async {
        Map<String, dynamic> riwayatData = doc.data() as Map<String, dynamic>;
        String lombaId = riwayatData['idLomba'];
        String? idKelompok = riwayatData['idKelompok'];
        
        final details = await Future.wait([
          idKelompok != null 
            ? _firestore.collection('kelompok').doc(idKelompok).get() 
            : Future.value(null),
          _lombaCollection.doc(lombaId).get().then((snap) => snap.exists ? snap : _riwayatEventCollection.doc(lombaId).get()),
        ]);

        DocumentSnapshot? kSnap = details[0] as DocumentSnapshot?;
        DocumentSnapshot? lombaSnap = details[1] as DocumentSnapshot?;

        if (idKelompok != null) {
          if (kSnap == null || !kSnap.exists) return;
          Map<String, dynamic> kData = kSnap.data() as Map<String, dynamic>;
          if (kData['status'] != 'penuh') return;
          
          String? idLeader = kData['idLeader'];
          if (lombaSnap != null && lombaSnap.exists) {
            Map<String, dynamic> detail = lombaSnap.data() as Map<String, dynamic>;
            results.add({
              'idRiwayat': doc.id,
              'idLomba': lombaId,
              'status': 'aktif',
              'idKelompok': idKelompok,
              'idLeader': idLeader,
              'isLeader': idLeader == userId,
              'judul': detail['judul'] ?? riwayatData['judulLomba'] ?? 'Lomba',
              'lokasi': detail['lokasi'] ?? '-',
              'tanggal': detail['tanggal'] ?? '-',
              'gambarPath': detail['gambarPath'],
            });
          }
        } else {
          if (lombaSnap != null && lombaSnap.exists) {
            Map<String, dynamic> detail = lombaSnap.data() as Map<String, dynamic>;
            results.add({
              'idRiwayat': doc.id,
              'idLomba': lombaId,
              'status': 'aktif',
              'idKelompok': null,
              'idLeader': null,
              'isLeader': false,
              'judul': detail['judul'] ?? riwayatData['judulLomba'] ?? 'Lomba',
              'lokasi': detail['lokasi'] ?? '-',
              'tanggal': detail['tanggal'] ?? '-',
              'gambarPath': detail['gambarPath'],
            });
          }
        }
      }).toList();

      await Future.wait(futures);
      results.sort((a, b) => (a['judul'] as String).compareTo(b['judul'] as String));
      return results;
    });
  }

  // ==================== TRACK RECORD (REAL-TIME) ====================

  static Stream<List<Map<String, dynamic>>> getTrackRecordUserStream(String userId) {
    return _riwayatSelesaiCollection
        .where('idUser', isEqualTo: userId)
        .snapshots()
        .map((snap) {
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
    });
  }

  static Stream<int> getTotalSelesaiUserStream(String userId) {
    return _riwayatSelesaiCollection
        .where('idUser', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  static Stream<List<Map<String, dynamic>>> getTrackRecordPerLombaStream(String userId) {
    return _riwayatSelesaiCollection
        .where('idUser', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      List<Map<String, dynamic>> results = snap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      results.sort((a, b) {
        String tglA = a['tanggalSelesai'] ?? '';
        String tglB = b['tanggalSelesai'] ?? '';
        return tglB.compareTo(tglA);
      });
      return results;
    });
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

  static Stream<List<Map<String, dynamic>>> getRiwayatStream() {
    return _riwayatCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
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
