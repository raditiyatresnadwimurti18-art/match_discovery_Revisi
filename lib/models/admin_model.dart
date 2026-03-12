class AdminModel {
  int? id;
  String username;
  String password;
  String? nama;
  String? profilePath;
  String role; // 'super' atau 'biasa'

  AdminModel({
    this.id,
    required this.username,
    required this.password,
    this.nama,
    this.profilePath,
    this.role = 'biasa', // Defaultnya admin biasa
  });

  // Mengubah Map dari database ke Objek AdminModel
  factory AdminModel.fromMap(Map<String, dynamic> map) {
    return AdminModel(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      nama: map['nama'],
      profilePath: map['profilePath'],
      role: map['role'] ?? 'biasa',
    );
  }

  // Mengubah Objek AdminModel ke Map untuk disimpan ke database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'nama': nama,
      'profilePath': profilePath,
      'role': role,
    };
  }
}
