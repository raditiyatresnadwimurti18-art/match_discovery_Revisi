class RiwayatSelesaiModel {
  final int? id;
  final int idUser;
  final String judulLomba;
  final String tanggalSelesai;

  RiwayatSelesaiModel({
    this.id,
    required this.idUser,
    required this.judulLomba,
    required this.tanggalSelesai,
  });

  // Konversi dari Map (dari database) ke Model
  factory RiwayatSelesaiModel.fromMap(Map<String, dynamic> map) {
    return RiwayatSelesaiModel(
      id: map['id'] as int?,
      idUser: map['idUser'] as int,
      judulLomba: map['judulLomba'] as String,
      tanggalSelesai: map['tanggalSelesai'] as String,
    );
  }

  // Konversi dari Model ke Map (untuk insert ke database)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
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
