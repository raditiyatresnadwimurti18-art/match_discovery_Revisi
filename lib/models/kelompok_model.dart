class KelompokModel {
  String? id;
  final String idLomba;
  final String idLeader; // User yang memulai pencarian
  final List<String> anggotaIds; // Daftar user ID anggota
  final int maxAnggota;
  final String status; // 'mencari' atau 'penuh'

  KelompokModel({
    this.id,
    required this.idLomba,
    required this.idLeader,
    required this.anggotaIds,
    required this.maxAnggota,
    this.status = 'mencari',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idLomba': idLomba,
      'idLeader': idLeader,
      'anggotaIds': anggotaIds,
      'maxAnggota': maxAnggota,
      'status': status,
    };
  }

  factory KelompokModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return KelompokModel(
      id: docId ?? map['id'],
      idLomba: map['idLomba'] ?? '',
      idLeader: map['idLeader'] ?? '',
      anggotaIds: List<String>.from(map['anggotaIds'] ?? []),
      maxAnggota: map['maxAnggota'] ?? 0,
      status: map['status'] ?? 'mencari',
    );
  }
}
