class AdminModel {
  String? id;
  String username;
  String? email; // Field baru untuk Firebase Auth
  String password;
  String? nama;
  String? profilePath;
  String role; // 'super' atau 'admin'

  AdminModel({
    this.id,
    required this.username,
    this.email,
    required this.password,
    this.nama,
    this.profilePath,
    this.role = 'admin',
  });

  // Mengubah Map dari database ke Objek AdminModel
  factory AdminModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return AdminModel(
      id: docId ?? map['id'],
      username: map['username'] ?? '',
      email: map['email'],
      password: map['password'] ?? '',
      nama: map['nama'],
      profilePath: map['profilePath'],
      role: map['role'] ?? 'admin',
    );
  }

  // Mengubah Objek AdminModel ke Map untuk disimpan ke database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'nama': nama,
      'profilePath': profilePath,
      'role': role,
    };
  }
}
