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
  final String jenisLomba; // Individual atau Kelompok
  final int? jumlahAnggota;

  LombaModel({
    this.id,
    required this.judul,
    required this.gambarPath,
    required this.kuota,
    required this.jenis,
    required this.tanggal,
    required this.lokasi,
    required this.deskripsi,
    required this.jenisLomba,
    this.jumlahAnggota,
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
      'jenisLomba': jenisLomba,
      'jumlahAnggota': jumlahAnggota,
    };
  }

  factory LombaModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return LombaModel(
      id: docId ?? map['id'] as String?,
      judul: map['judul'] ?? '',
      gambarPath: map['gambarPath'],
      kuota: map['kuota'] ?? 0,
      jenis: map['jenis'] ?? 'Akademik',
      tanggal: map['tanggal'] ?? '',
      lokasi: map['lokasi'] ?? '',
      deskripsi: map['deskripsi'] ?? '',
      jenisLomba: map['jenisLomba'] ?? 'Individual',
      jumlahAnggota: map['jumlahAnggota'] != null ? (map['jumlahAnggota'] as num).toInt() : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory LombaModel.fromJson(String source) =>
      LombaModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
