class RiwayatSelesaiModel {
  final String? id;
  final String idUser;
  final String judulLomba;
  final String tanggalSelesai;

  RiwayatSelesaiModel({
    this.id,
    required this.idUser,
    required this.judulLomba,
    required this.tanggalSelesai,
  });

  // Konversi dari Map (dari database) ke Model
  factory RiwayatSelesaiModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return RiwayatSelesaiModel(
      id: docId ?? (map['id'] as String?),
      idUser: map['idUser'] as String,
      judulLomba: map['judulLomba'] as String,
      tanggalSelesai: map['tanggalSelesai'] as String,
    );
  }

  // Konversi dari Model ke Map (untuk insert ke database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idUser': idUser,
      'judulLomba': judulLomba,
      'tanggalSelesai': tanggalSelesai,
    };
  }

  // Untuk debugging
  @override
  String toString() {
    return 'RiwayatSelesaiModel('
        'id: $id, '
        'idUser: $idUser, '
        'judulLomba: $judulLomba, '
        'tanggalSelesai: $tanggalSelesai)';
  }
}
