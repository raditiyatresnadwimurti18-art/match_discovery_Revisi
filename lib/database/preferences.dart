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
  static const String _userId = 'user_id'; // khusus user biasa
  static const String _adminId = 'admin_id'; // khusus admin

  // ==================== LOGIN STATUS ====================

  static Future<void> storingIsLogin(bool isLogin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLogin, isLogin);
    // Debugging (bisa dihapus nanti)
    print("PreferenceHandler: Status Login disimpan -> $isLogin");
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
  static Future<void> storingUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userId, id);
  }

  /// Ambil ID user biasa
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userId);
  }

  // ==================== ADMIN ID ====================

  /// Simpan ID admin (dipanggil saat admin login)
  static Future<void> storingAdminId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminId, id);
  }

  /// Ambil ID admin
  static Future<String?> getAdminId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_adminId);
  }

  // ==================== LEGACY (TETAP ADA agar tidak break kode lain) ====================

  /// @deprecated Gunakan [storingUserId] or [storingAdminId]
  static Future<void> storingId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(_role);
    if (role == 'admin' || role == 'super') {
      await prefs.setString(_adminId, id);
    } else {
      await prefs.setString(_userId, id);
    }
  }

  /// @deprecated Gunakan [getUserId] or [getAdminId]
  static Future<String?> getId() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(_role);
    if (role == 'admin' || role == 'super') {
      return prefs.getString(_adminId);
    }
    return prefs.getString(_userId);
  }

  // ==================== SUPER ADMIN ====================

  static const String _superAdminInitialized = 'super_admin_initialized';

  static Future<void> setSuperAdminInitialized(bool initialized) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_superAdminInitialized, initialized);
  }

  static Future<bool> getSuperAdminInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_superAdminInitialized) ?? false;
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
