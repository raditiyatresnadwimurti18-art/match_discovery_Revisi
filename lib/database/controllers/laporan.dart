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
      Set<String> processedUserLombaKeys = {};

      // Cache untuk User dan Lomba untuk menghindari fetch berulang
      Map<String, DocumentSnapshot> userCache = {};
      Map<String, String> lombaJudulCache = {};

      // PROSES RIWAYAT
      List<Future<void>> riwayatTasks = riwayatSnap.docs.map((doc) async {
        Map<String, dynamic> riwayatData = doc.data() as Map<String, dynamic>;
        String idUser = riwayatData['idUser'];
        String idLomba = riwayatData['idLomba'];
        processedUserLombaKeys.add("${idUser}_$idLomba");

        // Fetch User (dengan cache)
        if (!userCache.containsKey(idUser)) {
          userCache[idUser] = await _firestore.collection('users').doc(idUser).get();
        }
        DocumentSnapshot userSnap = userCache[idUser]!;

        // Fetch Lomba Judul (dengan cache)
        if (!lombaJudulCache.containsKey(idLomba)) {
          DocumentSnapshot lSnap = await _firestore.collection('lomba').doc(idLomba).get();
          if (lSnap.exists) {
            lombaJudulCache[idLomba] = lSnap.get('judul');
          } else {
            DocumentSnapshot eventSnap = await _firestore.collection('riwayatEvent').doc(idLomba).get();
            if (eventSnap.exists) {
              lombaJudulCache[idLomba] = eventSnap.get('judul');
            }
          }
        }
        String? judul = lombaJudulCache[idLomba];

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
      }).toList();

      await Future.wait(riwayatTasks);

      // PROSES KELOMPOK (PENDING)
      for (var doc in kelompokSnap.docs) {
        Map<String, dynamic> kData = doc.data() as Map<String, dynamic>;
        String idLomba = kData['idLomba'];
        List<String> anggotaIds = List<String>.from(kData['anggotaIds'] ?? []);

        // Fetch Lomba Judul
        if (!lombaJudulCache.containsKey(idLomba)) {
          DocumentSnapshot lSnap = await _firestore.collection('lomba').doc(idLomba).get();
          if (lSnap.exists) {
            lombaJudulCache[idLomba] = lSnap.get('judul');
          }
        }
        String? judul = lombaJudulCache[idLomba];
        if (judul == null) continue;

        List<Future<void>> memberTasks = anggotaIds.map((uid) async {
          if (processedUserLombaKeys.contains("${uid}_$idLomba")) return;
          processedUserLombaKeys.add("${uid}_$idLomba");

          if (!userCache.containsKey(uid)) {
            userCache[uid] = await _firestore.collection('users').doc(uid).get();
          }
          DocumentSnapshot userSnap = userCache[uid]!;

          if (userSnap.exists) {
            results.add({
              'idUser': uid,
              'judul_lomba': judul,
              'nama_user': userSnap.get('nama'),
              'telepon_user': userSnap.get('tlpon'),
              'tanggalDaftar': DateTime.now().toIso8601String(),
              'jenis': 'Kelompok',
              'status_tim': 'Mencari Anggota',
            });
          }
        }).toList();
        
        await Future.wait(memberTasks);
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
      
      // Parallel fetch users
      List<Future<void>> tasks = riwayatSnap.docs.map((doc) async {
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
      }).toList();

      await Future.wait(tasks);
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

      List<Future<void>> tasks = lombaSnap.docs.map((doc) async {
        Map<String, dynamic> lombaData = doc.data() as Map<String, dynamic>;
        lombaData['id'] = doc.id;

        AggregateQuerySnapshot count = await _firestore.collection('riwayat')
            .where('idLomba', isEqualTo: doc.id)
            .where('status', isEqualTo: 'aktif')
            .count()
            .get();
        
        lombaData['totalPendaftar'] = count.count ?? 0;
        results.add(lombaData);
      }).toList();

      await Future.wait(tasks);
      return results;
    } catch (e) {
      print("Error getAllLombaDenganJumlahPendaftar: $e");
      return [];
    }
  }
}
