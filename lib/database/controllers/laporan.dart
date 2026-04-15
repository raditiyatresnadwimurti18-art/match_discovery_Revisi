import 'package:cloud_firestore/cloud_firestore.dart';

class LaporanController {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<Map<String, dynamic>>> getSemuaPendaftarGlobal() async {
    try {
      QuerySnapshot riwayatSnap = await _firestore.collection('riwayat')
          .where('status', isEqualTo: 'aktif')
          .get();

      List<Map<String, dynamic>> results = [];

      for (var doc in riwayatSnap.docs) {
        Map<String, dynamic> riwayatData = doc.data() as Map<String, dynamic>;
        String idUser = riwayatData['idUser'];
        String idLomba = riwayatData['idLomba'];

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
            'judul_lomba': judul,
            'nama_user': userSnap.get('nama'),
            'telepon_user': userSnap.get('tlpon'),
            'tanggalDaftar': riwayatData['tanggalDaftar'],
          });
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
