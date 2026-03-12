// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class LombaModel {
  final int? id;
  final String judul;
  final String gambarPath;
  final int kuota;
  final String jenis; // Kategori
  final String tanggal;
  final String lokasi;
  final String deskripsi;

  LombaModel({
    this.id,
    required this.judul,
    required this.gambarPath,
    required this.kuota,
    required this.jenis,
    required this.tanggal,
    required this.lokasi,
    required this.deskripsi,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'judul': judul,
      'gambarPath': gambarPath,
      'kuota': kuota,
      'jenis': jenis,
      'tanggal': tanggal,
      'lokasi': lokasi,
      'deskripsi': deskripsi,
    };
  }

  factory LombaModel.fromMap(Map<String, dynamic> map) {
    return LombaModel(
      id: map['id'] != null ? map['id'] as int : null,
      judul: map['judul'] as String,
      gambarPath: map['gambarPath'] as String,
      kuota: map['kuota'] as int,
      jenis: map['jenis'] as String,
      tanggal: map['tanggal'] as String,
      lokasi: map['lokasi'] as String,
      deskripsi: map['deskripsi'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory LombaModel.fromJson(String source) =>
      LombaModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
