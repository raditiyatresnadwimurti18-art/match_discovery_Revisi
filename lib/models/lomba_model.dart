// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class LombaModel {
  String? id; // Dilepas final-nya agar bisa di-set dari doc.id Firestore
  final String judul;
  final String? gambarPath;
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
      'id': id, // Tetap disertakan agar field 'id' ada di dalam dokumen Firestore
      'judul': judul,
      'gambarPath': gambarPath,
      'kuota': kuota,
      'jenis': jenis,
      'tanggal': tanggal,
      'lokasi': lokasi,
      'deskripsi': deskripsi,
    };
  }

  factory LombaModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return LombaModel(
      id: docId ?? map['id'] as String?,
      judul: map['judul'] ?? '',
      gambarPath: map['gambarPath'],
      kuota: map['kuota'] ?? 0,
      jenis: map['jenis'] ?? '',
      tanggal: map['tanggal'] ?? '',
      lokasi: map['lokasi'] ?? '',
      deskripsi: map['deskripsi'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory LombaModel.fromJson(String source) =>
      LombaModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
