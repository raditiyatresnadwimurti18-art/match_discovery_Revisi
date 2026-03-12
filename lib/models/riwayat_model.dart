// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class RiwayatModel {
  int? id;
  int idUser;
  int idLomba;
  String? tanggalDaftar;

  RiwayatModel({
    this.id,
    required this.idUser,
    required this.idLomba,
    this.tanggalDaftar,
  });

  // Untuk menyimpan ke Database
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'idUser': idUser,
      'idLomba': idLomba,
      'tanggalDaftar': tanggalDaftar ?? DateTime.now().toString(),
    };
  }

  // Untuk mengambil dari Database
  factory RiwayatModel.fromMap(Map<String, dynamic> map) {
    return RiwayatModel(
      id: map['id'] != null ? map['id'] as int : null,
      idUser: map['idUser'] as int,
      idLomba: map['idLomba'] as int,
      tanggalDaftar: map['tanggalDaftar'] != null
          ? map['tanggalDaftar'] as String
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory RiwayatModel.fromJson(String source) =>
      RiwayatModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
