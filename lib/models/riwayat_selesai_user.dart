class RiwayatSelesaiModel {
  final String? id;
  final String idUser;
  final String judulLomba;
  final String tanggalSelesai;
  final String jenisLomba; // 'Individual' atau 'Kelompok'
  final String? idKelompok;

  RiwayatSelesaiModel({
    this.id,
    required this.idUser,
    required this.judulLomba,
    required this.tanggalSelesai,
    this.jenisLomba = 'Individual',
    this.idKelompok,
  });

  // Konversi dari Map (dari database) ke Model
  factory RiwayatSelesaiModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return RiwayatSelesaiModel(
      id: docId ?? (map['id'] as String?),
      idUser: map['idUser'] ?? '',
      judulLomba: map['judulLomba'] ?? '',
      tanggalSelesai: map['tanggalSelesai'] ?? '',
      jenisLomba: map['jenisLomba'] ?? 'Individual',
      idKelompok: map['idKelompok'],
    );
  }

  // Konversi dari Model ke Map (untuk insert ke database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idUser': idUser,
      'judulLomba': judulLomba,
      'tanggalSelesai': tanggalSelesai,
      'jenisLomba': jenisLomba,
      'idKelompok': idKelompok,
    };
  }
}
