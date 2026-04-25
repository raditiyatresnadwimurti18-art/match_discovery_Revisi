import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:match_discovery/database/controllers/riwayat.dart';
import 'package:match_discovery/models/kelompok_model.dart';
import 'package:match_discovery/models/riwayat_model.dart';

class KelompokController {
  static final CollectionReference _kelompokCollection =
      FirebaseFirestore.instance.collection('kelompok');

  // Mencari kelompok yang sedang butuh anggota untuk lomba tertentu
  static Stream<List<KelompokModel>> getKelompokTersedia(String idLomba) {
    return _kelompokCollection
        .where('idLomba', isEqualTo: idLomba)
        .where('status', isEqualTo: 'mencari')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return KelompokModel.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);
      }).toList();
    });
  }

  // Membuat permintaan pencarian kelompok baru
  static Future<Map<String, dynamic>> buatKelompok(KelompokModel kelompok) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentReference docRef = _kelompokCollection.doc();
      kelompok.id = docRef.id;

      final result = await firestore.runTransaction<Map<String, dynamic>>((transaction) async {
        bool isPenuh = kelompok.anggotaIds.length >= kelompok.maxAnggota;
        String status = isPenuh ? 'penuh' : 'mencari';

        // JIKA PENUH: Cek dan Kurangi kuota Lomba
        if (isPenuh) {
          DocumentReference lombaRef = firestore.collection('lomba').doc(kelompok.idLomba);
          DocumentSnapshot lombaSnap = await transaction.get(lombaRef);
          
          if (!lombaSnap.exists) {
            return {'success': false, 'message': 'Lomba tidak ditemukan atau sudah penuh.'};
          }

          Map<String, dynamic> lombaData = lombaSnap.data() as Map<String, dynamic>;
          int currentKuota = 0;
          if (lombaData['kuota'] != null) {
            currentKuota = (lombaData['kuota'] is int) ? lombaData['kuota'] : int.tryParse(lombaData['kuota'].toString()) ?? 0;
          }

          if (currentKuota <= 0) {
            return {'success': false, 'message': 'Maaf, kuota lomba ini sudah penuh.'};
          }

          // Kurangi kuota
          int newKuota = currentKuota - 1;
          transaction.update(lombaRef, {'kuota': newKuota});

          // Jika kuota habis, pindahkan ke riwayatEvent
          if (newKuota <= 0) {
            lombaData['idLombaAsli'] = lombaSnap.id;
            lombaData['statusLomba'] = 'Penuh/Selesai';
            lombaData['kuota'] = 0;
            transaction.set(firestore.collection('riwayatEvent').doc(lombaSnap.id), lombaData);
            transaction.delete(lombaRef);
          }
        }

        // Simpan kelompok
        Map<String, dynamic> kelompokMap = kelompok.toMap();
        kelompokMap['status'] = status;
        transaction.set(docRef, kelompokMap);

        return {
          'success': true, 
          'id': docRef.id,
          'isFull': isPenuh,
          'idLomba': kelompok.idLomba,
          'anggotaIds': kelompok.anggotaIds
        };
      });

      // Jika langsung penuh, daftarkan ke riwayat
      if (result['success'] == true && result['isFull'] == true) {
        List<String> anggotaIds = List<String>.from(result['anggotaIds']);
        String idLomba = result['idLomba'];
        
        // Optimasi: Daftarkan semua anggota secara paralel
        await Future.wait(anggotaIds.map((uid) => RiwayatController.ikutiLomba(
          RiwayatModel(
            idUser: uid,
            idLomba: idLomba,
            idKelompok: docRef.id,
            tanggalDaftar: DateTime.now().toIso8601String(),
          ), 
          reduceKuota: false
        )));
      }

      return result;
    } catch (e) {
      print("Error buatKelompok: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  // Bergabung ke kelompok yang sudah ada
  static Future<Map<String, dynamic>> gabungKelompok(String idKelompok, String idUser) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentReference docRef = _kelompokCollection.doc(idKelompok);
      
      final result = await firestore.runTransaction<Map<String, dynamic>>((transaction) async {
        DocumentSnapshot doc = await transaction.get(docRef);
        
        if (!doc.exists) return {'success': false, 'message': 'Kelompok tidak ditemukan'};
        
        KelompokModel kelompok = KelompokModel.fromMap(doc.data() as Map<String, dynamic>);
        
        if (kelompok.anggotaIds.contains(idUser)) {
          return {'success': false, 'message': 'Anda sudah bergabung'};
        }

        if (kelompok.anggotaIds.length >= kelompok.maxAnggota) {
          return {'success': false, 'message': 'Kelompok sudah penuh'};
        }

        List<String> newAnggota = List.from(kelompok.anggotaIds);
        newAnggota.add(idUser);
        
        bool isPenuh = newAnggota.length >= kelompok.maxAnggota;
        String newStatus = isPenuh ? 'penuh' : 'mencari';

        // JIKA PENUH: Cek dan Kurangi kuota Lomba (1 tim = 1 kuota)
        if (isPenuh) {
          DocumentReference lombaRef = firestore.collection('lomba').doc(kelompok.idLomba);
          DocumentSnapshot lombaSnap = await transaction.get(lombaRef);
          
          if (!lombaSnap.exists) {
            return {'success': false, 'message': 'Lomba tidak ditemukan, tidak bisa melengkapi kelompok.'};
          }

          Map<String, dynamic> lombaData = lombaSnap.data() as Map<String, dynamic>;
          int currentKuota = 0;
          if (lombaData['kuota'] != null) {
            currentKuota = (lombaData['kuota'] is int) ? lombaData['kuota'] : int.tryParse(lombaData['kuota'].toString()) ?? 0;
          }

          if (currentKuota <= 0) {
            return {'success': false, 'message': 'Maaf, kuota lomba ini sudah penuh.'};
          }

          // Kurangi kuota
          int newKuota = currentKuota - 1;
          transaction.update(lombaRef, {'kuota': newKuota});

          // Jika kuota habis, pindahkan ke riwayatEvent
          if (newKuota <= 0) {
            lombaData['idLombaAsli'] = lombaSnap.id;
            lombaData['statusLomba'] = 'Penuh/Selesai';
            lombaData['kuota'] = 0;
            transaction.set(firestore.collection('riwayatEvent').doc(lombaSnap.id), lombaData);
            transaction.delete(lombaRef);
          }
        }

        // Update data kelompok
        transaction.update(docRef, {
          'anggotaIds': newAnggota,
          'status': newStatus
        });

        return {
          'success': true, 
          'isFull': isPenuh, 
          'anggotaIds': newAnggota, 
          'idLomba': kelompok.idLomba
        };
      });

      // Jika transaksi sukses dan penuh, daftarkan riwayat anggota (di luar transaksi agar tidak bentrok dengan logic internal ikutiLomba)
      if (result['success'] == true && result['isFull'] == true) {
        List<String> anggotaIds = List<String>.from(result['anggotaIds']);
        String idLomba = result['idLomba'];
        
        // Optimasi: Daftarkan semua anggota secara paralel
        await Future.wait(anggotaIds.map((uid) => RiwayatController.ikutiLomba(
          RiwayatModel(
            idUser: uid,
            idLomba: idLomba,
            idKelompok: idKelompok,
            tanggalDaftar: DateTime.now().toIso8601String(),
          ), 
          reduceKuota: false
        )));
      }
      
      return result;
    } catch (e) {
      print("Error gabungKelompok: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  // Ambil data kelompok berdasarkan ID
  static Stream<KelompokModel?> streamKelompokById(String idKelompok) {
    return _kelompokCollection.doc(idKelompok).snapshots().map((doc) {
      if (!doc.exists) return null;
      return KelompokModel.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);
    });
  }


  // Cek apakah user sudah punya kelompok untuk lomba ini
  static Future<KelompokModel?> getMyKelompok(String idLomba, String idUser) async {
    final query = await _kelompokCollection
        .where('idLomba', isEqualTo: idLomba)
        .where('anggotaIds', arrayContains: idUser)
        .get();
    
    if (query.docs.isEmpty) return null;
    return KelompokModel.fromMap(query.docs.first.data() as Map<String, dynamic>, docId: query.docs.first.id);
  }
}
