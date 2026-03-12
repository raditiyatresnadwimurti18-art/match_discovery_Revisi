import 'package:shared_preferences/shared_preferences.dart';

class PreferenceHandler {
  static final PreferenceHandler _instance = PreferenceHandler._internal();

  factory PreferenceHandler() => _instance;
  PreferenceHandler._internal();
  Future<void> init() async {}

  // Key
  static const String _isLogin = 'isLogin';
  static const String _id = 'id';

  // ==================== CREATE ====================

  static Future<void> storingIsLogin(bool isLogin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLogin, isLogin);
  }

  /// FIX: parameter tetap [int], pastikan semua pemanggil
  /// melakukan cast "as int" saat mengambil nilai dari Map SQLite.
  static Future<void> storingId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_id, id);
  }

  // ==================== GET ====================

  static Future<bool?> getIsLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLogin);
  }

  static Future<int?> getId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_id);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  // ==================== DELETE ====================

  static Future<void> deleteIsLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLogin);
  }

  static Future<void> deleteId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_id);
  }

  static Future<void> setRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
  }

  /// Hapus semua data sesi (dipakai saat logout).
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLogin);
    await prefs.remove(_id);
    await prefs.remove('role');
  }
}
