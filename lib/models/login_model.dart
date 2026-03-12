class LoginModel {
  int? id;
  String? nama;
  String? email;
  String? password;
  String? tlpon;
  String? profilePath;
  // Variabel baru yang menyebabkan error:
  String? asalKota;
  String? pendidikanTerakhir;
  String? asalSekolah;

  LoginModel({
    this.id,
    this.nama,
    this.email,
    this.password,
    this.tlpon,
    this.profilePath,
    this.asalKota,
    this.pendidikanTerakhir,
    this.asalSekolah,
  });

  // Fungsi untuk mengubah data dari Database (Map) ke Object Flutter
  factory LoginModel.fromMap(Map<String, dynamic> map) {
    return LoginModel(
      id: map['id'],
      nama: map['nama'],
      email: map['email'],
      password: map['password'],
      tlpon: map['tlpon'],
      profilePath: map['profilePath'],
      asalKota: map['asalKota'],
      pendidikanTerakhir: map['pendidikanTerakhir'],
      asalSekolah: map['asalSekolah'],
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
      'asalKota': asalKota,
      'pendidikanTerakhir': pendidikanTerakhir,
      'asalSekolah': asalSekolah,
    };
  }
}
