class LombaModel {
  final int? id;
  final String judul;
  final String jenis;
  final String tanggal;
  final String lokasi;
  final String deskripsi;
  final String gambarPath;
  final int kuota;

  LombaModel({
    this.id,
    required this.judul,
    required this.jenis,
    required this.tanggal,
    required this.lokasi,
    required this.deskripsi,
    required this.gambarPath,
    required this.kuota,
  });

  // Konversi dari Map (Database) ke Object (Flutter)
  factory LombaModel.fromMap(Map<String, dynamic> map) {
    return LombaModel(
      id: map['id'],
      judul: map['judul'],
      jenis: map['jenis'],
      tanggal: map['tanggal'],
      lokasi: map['lokasi'],
      deskripsi: map['deskripsi'],
      gambarPath: map['gambarPath'],
      kuota: map['kuota'],
    );
  }

  // Konversi dari Object ke Map (untuk Insert ke Database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'judul': judul,
      'jenis': jenis,
      'tanggal': tanggal,
      'lokasi': lokasi,
      'deskripsi': deskripsi,
      'gambarPath': gambarPath,
      'kuota': kuota,
    };
  }

  // Khusus untuk riwayatEvent (tanpa kuota)
  Map<String, dynamic> toMapRiwayatEvent() {
    return {
      'id': id,
      'judul': judul,
      'jenis': jenis,
      'tanggal': tanggal,
      'lokasi': lokasi,
      'deskripsi': deskripsi,
      'gambarPath': gambarPath,
    };
  }
}
