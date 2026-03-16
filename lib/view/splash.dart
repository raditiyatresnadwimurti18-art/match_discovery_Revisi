import 'package:flutter/material.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/extension/navigator.dart';
import 'package:match_discovery/home_admin/home.dart';
import 'package:match_discovery/home_user/home_user.dart';
import 'package:match_discovery/login/login.dart';

class SplashscreenT16 extends StatefulWidget {
  const SplashscreenT16({super.key});

  @override
  State<SplashscreenT16> createState() => _SplashscreenT16State();
}

class _SplashscreenT16State extends State<SplashscreenT16> {
  @override
  void initState() {
    super.initState();
    _autoLogin();
  }

  Future<void> _autoLogin() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final bool? isLogin = await PreferenceHandler.getIsLogin();
    final String? role = await PreferenceHandler.getRole();

    if (!mounted) return;

    if (role == 'admin' && isLogin == true) {
      // ✅ Admin yang sudah login → Dashboard Admin
      context.pushAndRemoveAll(const Home());
    } else if (role == 'user' && isLogin == true) {
      // ✅ User biasa yang sudah login → Home User
      context.pushAndRemoveAll(const HomeUser());
    } else if (role == 'guest') {
      // ✅ Tamu (masuk tanpa akun) → Home User tapi tanpa sesi login
      context.pushAndRemoveAll(const HomeUser());
    } else {
      // ✅ Belum pernah login sama sekali → Halaman Welcome
      context.pushAndRemoveAll(const Login());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: 200),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Discovery',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: Color(0xffcdb060),
                  ),
                ),
                Text(
                  'Match',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: Color(0xff112955),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Color(0xff112955),
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
