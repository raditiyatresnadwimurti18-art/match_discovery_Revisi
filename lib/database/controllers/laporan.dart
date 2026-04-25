import 'package:cloud_firestore/cloud_firestore.dart';

class LaporanController {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<Map<String, dynamic>>> getSemuaPendaftarGlobal() async {
    try {
      // 1. Ambil dari riwayat (Individual & Kelompok yang sudah penuh)
      QuerySnapshot riwayatSnap = await _firestore.collection('riwayat')
          .where('status', isEqualTo: 'aktif')
          .get();

      // 2. Ambil dari kelompok (Kelompok yang masih mencari anggota)
      QuerySnapshot kelompokSnap = await _firestore.collection('kelompok')
          .where('status', isEqualTo: 'mencari')
          .get();

      List<Map<String, dynamic>> results = [];
      Set<String> processedUserLombaKeys = {}; // Untuk mencegah duplikasi

      // PROSES RIWAYAT
      for (var doc in riwayatSnap.docs) {
        Map<String, dynamic> riwayatData = doc.data() as Map<String, dynamic>;
        String idUser = riwayatData['idUser'];
        String idLomba = riwayatData['idLomba'];
        processedUserLombaKeys.add("${idUser}_${idLomba}");

        DocumentSnapshot userSnap = await _firestore.collection('users').doc(idUser).get();
        DocumentSnapshot lombaSnap = await _firestore.collection('lomba').doc(idLomba).get();
        
        String? judul;
        if (lombaSnap.exists) {
          judul = lombaSnap.get('judul');
        } else {
          DocumentSnapshot eventSnap = await _firestore.collection('riwayatEvent').doc(idLomba).get();
          if (eventSnap.exists) {
            judul = eventSnap.get('judul');
          }
        }

        if (userSnap.exists && judul != null) {
          results.add({
            'idUser': idUser,
            'judul_lomba': judul,
            'nama_user': userSnap.get('nama'),
            'telepon_user': userSnap.get('tlpon'),
            'tanggalDaftar': riwayatData['tanggalDaftar'],
            'jenis': riwayatData['idKelompok'] != null ? 'Kelompok' : 'Individual',
            'status_tim': 'Terdaftar',
          });
        }
      }

      // PROSES KELOMPOK (PENDING)
      for (var doc in kelompokSnap.docs) {
        Map<String, dynamic> kData = doc.data() as Map<String, dynamic>;
        String idLomba = kData['idLomba'];
        List<String> anggotaIds = List<String>.from(kData['anggotaIds'] ?? []);

        DocumentSnapshot lombaSnap = await _firestore.collection('lomba').doc(idLomba).get();
        if (!lombaSnap.exists) continue;
        String judul = lombaSnap.get('judul');

        for (String uid in anggotaIds) {
          if (processedUserLombaKeys.contains("${uid}_${idLomba}")) continue;
          processedUserLombaKeys.add("${uid}_${idLomba}");

          DocumentSnapshot userSnap = await _firestore.collection('users').doc(uid).get();
          if (userSnap.exists) {
            results.add({
              'idUser': uid,
              'judul_lomba': judul,
              'nama_user': userSnap.get('nama'),
              'telepon_user': userSnap.get('tlpon'),
              'tanggalDaftar': DateTime.now().toIso8601String(), // Kelompok pending tidak punya tanggalDaftar di doc kelompok
              'jenis': 'Kelompok',
              'status_tim': 'Mencari Anggota',
            });
          }
        }
      }

      return results;
    } catch (e) {
      print("Error getSemuaPendaftarGlobal: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPendaftarByLomba(String idLomba) async {
    try {
      QuerySnapshot riwayatSnap = await _firestore.collection('riwayat')
          .where('idLomba', isEqualTo: idLomba)
          .where('status', isEqualTo: 'aktif')
          .get();

      List<Map<String, dynamic>> results = [];

      for (var doc in riwayatSnap.docs) {
        Map<String, dynamic> riwayatData = doc.data() as Map<String, dynamic>;
        String idUser = riwayatData['idUser'];

        DocumentSnapshot userSnap = await _firestore.collection('users').doc(idUser).get();
        
        if (userSnap.exists) {
          results.add({
            'nama': userSnap.get('nama'),
            'tlpon': userSnap.get('tlpon'),
            'tanggalDaftar': riwayatData['tanggalDaftar'],
          });
        }
      }
      return results;
    } catch (e) {
      print("Error getPendaftarByLomba: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllLombaDenganJumlahPendaftar() async {
    try {
      QuerySnapshot lombaSnap = await _firestore.collection('lomba').get();
      List<Map<String, dynamic>> results = [];

      for (var doc in lombaSnap.docs) {
        Map<String, dynamic> lombaData = doc.data() as Map<String, dynamic>;
        lombaData['id'] = doc.id;

        AggregateQuerySnapshot count = await _firestore.collection('riwayat')
            .where('idLomba', isEqualTo: doc.id)
            .where('status', isEqualTo: 'aktif')
            .count()
            .get();
        
        lombaData['totalPendaftar'] = count.count ?? 0;
        results.add(lombaData);
      }
      return results;
    } catch (e) {
      print("Error getAllLombaDenganJumlahPendaftar: $e");
      return [];
    }
  }
}
