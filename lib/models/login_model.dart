class LoginModel {
  String? id;
  String? nama;
  String? email;
  String? password;
  String? tlpon;
  String? profilePath;
  String? role; // 'user', 'admin', 'super'
  // Variabel baru yang menyebabkan error:
  String? asalKota;
  String? pendidikanTerakhir;
  String? asalSekolah;
  String? tanggal_daftar;
  String? fcmToken;
  bool? isOnline;
  String? lastActive;

  LoginModel({
    this.id,
    this.nama,
    this.email,
    this.password,
    this.tlpon,
    this.profilePath,
    this.role = 'user',
    this.asalKota,
    this.pendidikanTerakhir,
    this.asalSekolah,
    this.tanggal_daftar,
    this.fcmToken,
    this.isOnline = false,
    this.lastActive,
  });

  // Fungsi untuk mengubah data dari Database (Map) ke Object Flutter
  factory LoginModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return LoginModel(
      id: docId ?? map['id'],
      nama: map['nama'],
      email: map['email'],
      password: map['password'],
      tlpon: map['tlpon'],
      profilePath: map['profilePath'],
      role: map['role'] ?? 'user',
      asalKota: map['asalKota'],
      pendidikanTerakhir: map['pendidikanTerakhir'],
      asalSekolah: map['asalSekolah'],
      tanggal_daftar: map['tanggal_daftar'],
      fcmToken: map['fcmToken'],
      isOnline: map['isOnline'] ?? false,
      lastActive: map['lastActive'],
    );
  }

  // Fungsi untuk mengubah Object Flutter ke Map (untuk simpan ke Database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'password': password,
      'tlpon': tlpon,
      'profilePath': profilePath,
      'role': role,
      'asalKota': asalKota,
      'pendidikanTerakhir': pendidikanTerakhir,
      'asalSekolah': asalSekolah,
      'tanggal_daftar': tanggal_daftar,
      'fcmToken': fcmToken,
      'isOnline': isOnline,
      'lastActive': lastActive,
    };
  }
}
