import 'package:shared_preferences/shared_preferences.dart';

class PreferenceHandler {
  //Inisialisasi Shared Preference
  static final PreferenceHandler _instance = PreferenceHandler._internal();

  factory PreferenceHandler() => _instance;
  PreferenceHandler._internal();
  Future<void> init() async {}

  //Key user
  static const String _isLogin = 'isLogin';
  static const String _id = 'id';

  //CREATE
  static Future<void> storingIsLogin(bool isLogin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLogin, isLogin);
  }

  static Future<void> storingId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_id, id);
  }

  //GET
  static Future<bool?> getIsLogin() async {
    final prefs = await SharedPreferences.getInstance();

    var data = prefs.getBool(_isLogin);
    return data;
  }

  static Future<int?> getId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_id); // Pastikan key-nya sama dengan saat storingId
  }

  //DELETE
  static Future<void> deleteIsLogin() async {
    //
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLogin);
  }

  static Future<void> deleteId() async {
    //
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_id);
  }

  static Future<void> setRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }
}
