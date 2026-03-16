import 'package:shared_preferences/shared_preferences.dart';

class PreferenceHandler {
  static final PreferenceHandler _instance = PreferenceHandler._internal();

  factory PreferenceHandler() => _instance;
  PreferenceHandler._internal();
  Future<void> init() async {}

  // ── Keys ────────────────────────────────────────────────────────────────
  static const String _isLogin = 'isLogin';
  static const String _role = 'role';

  // ✅ FIX: Pisahkan key ID untuk admin dan user
  // Sebelumnya hanya ada 1 key '_id' yang dipakai bersama oleh admin & user.
  // Akibatnya saat admin login (id=1 tersimpan), lalu user login tapi
  // getId() masih mengembalikan id=1 milik Super Admin.
  static const String _userId = 'user_id'; // khusus user biasa
  static const String _adminId = 'admin_id'; // khusus admin

  // ==================== LOGIN STATUS ====================

  static Future<void> storingIsLogin(bool isLogin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLogin, isLogin);
  }

  static Future<bool?> getIsLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLogin);
  }

  // ==================== ROLE ====================

  static Future<void> setRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_role, role);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_role);
  }

  // ==================== USER ID ====================

  /// Simpan ID user biasa (dipanggil saat user login)
  static Future<void> storingUserId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userId, id);
  }

  /// Ambil ID user biasa
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userId);
  }

  // ==================== ADMIN ID ====================

  /// Simpan ID admin (dipanggil saat admin login)
  static Future<void> storingAdminId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_adminId, id);
  }

  /// Ambil ID admin
  static Future<int?> getAdminId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_adminId);
  }

  // ==================== LEGACY (TETAP ADA agar tidak break kode lain) ====================

  /// @deprecated Gunakan [storingUserId] atau [storingAdminId]
  static Future<void> storingId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(_role);
    if (role == 'admin') {
      await prefs.setInt(_adminId, id);
    } else {
      await prefs.setInt(_userId, id);
    }
  }

  /// @deprecated Gunakan [getUserId] atau [getAdminId]
  static Future<int?> getId() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(_role);
    if (role == 'admin') {
      return prefs.getInt(_adminId);
    }
    return prefs.getInt(_userId);
  }

  // ==================== LOGOUT ====================

  static Future<void> deleteIsLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLogin);
  }

  static Future<void> deleteId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userId);
    await prefs.remove(_adminId);
  }

  /// Hapus semua data sesi (dipakai saat logout).
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLogin);
    await prefs.remove(_userId);
    await prefs.remove(_adminId);
    await prefs.remove(_role);
  }
}
