import 'package:shared_preferences/shared_preferences.dart';

class PreferenceHandler {
  static SharedPreferences? _prefs;

  // Inisialisasi SharedPreferences satu kali saat aplikasi dimulai
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _getPrefs {
    if (_prefs == null) {
      throw Exception("PreferenceHandler belum diinisialisasi. Panggil PreferenceHandler.init() di main.dart");
    }
    return _prefs!;
  }

  // ── Keys ────────────────────────────────────────────────────────────────
  static const String _isLogin = 'isLogin';
  static const String _role = 'role';
  static const String _userId = 'user_id';
  static const String _adminId = 'admin_id';

  // ==================== LOGIN STATUS ====================

  static Future<void> storingIsLogin(bool isLogin) async {
    await _getPrefs.setBool(_isLogin, isLogin);
    print("PreferenceHandler: Status Login disimpan -> $isLogin");
  }

  static bool? getIsLogin() {
    return _getPrefs.getBool(_isLogin);
  }

  // ==================== ROLE ====================

  static Future<void> setRole(String role) async {
    await _getPrefs.setString(_role, role);
  }

  static String? getRole() {
    return _getPrefs.getString(_role);
  }

  // ==================== USER ID ====================

  static Future<void> storingUserId(String id) async {
    await _getPrefs.setString(_userId, id);
  }

  static String? getUserId() {
    return _getPrefs.getString(_userId);
  }

  // ==================== ADMIN ID ====================

  static Future<void> storingAdminId(String id) async {
    await _getPrefs.setString(_adminId, id);
  }

  static String? getAdminId() {
    return _getPrefs.getString(_adminId);
  }

  // ==================== LEGACY ====================

  static Future<void> storingId(String id) async {
    final role = _getPrefs.getString(_role);
    if (role == 'admin' || role == 'super') {
      await _getPrefs.setString(_adminId, id);
    } else {
      await _getPrefs.setString(_userId, id);
    }
  }

  static String? getId() {
    final role = _getPrefs.getString(_role);
    if (role == 'admin' || role == 'super') {
      return _getPrefs.getString(_adminId);
    }
    return _getPrefs.getString(_userId);
  }

  // ==================== SUPER ADMIN ====================

  static const String _superAdminInitialized = 'super_admin_initialized';

  static Future<void> setSuperAdminInitialized(bool initialized) async {
    await _getPrefs.setBool(_superAdminInitialized, initialized);
  }

  static bool getSuperAdminInitialized() {
    return _getPrefs.getBool(_superAdminInitialized) ?? false;
  }

  // ==================== LOGOUT ====================

  static Future<void> clearAll() async {
    await _getPrefs.remove(_isLogin);
    await _getPrefs.remove(_userId);
    await _getPrefs.remove(_adminId);
    await _getPrefs.remove(_role);
  }
}

