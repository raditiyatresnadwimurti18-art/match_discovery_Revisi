import 'package:flutter/material.dart';
// import 'package:flutter_ppkd_r_1/extension/navigator.dart';
import 'package:match_discovery/database/preferences.dart';
// import 'package:flutter_ppkd_r_1/tugas_flutter11/home_t_6.dart';
// import 'package:flutter_ppkd_r_1/tugas_flutter11/login.dart';
// import 'package:flutter_ppkd_r_1/tugas_flutter11/login1.dart';
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
    autoLogin();
  }

  void autoLogin() async {
    await Future.delayed(const Duration(seconds: 2));

    // 1. Cek apakah sudah login
    bool? isLogin = await PreferenceHandler.getIsLogin();

    if (isLogin == true) {
      // 2. Cek Role-nya siapa (Admin atau User)
      String? role = await PreferenceHandler.getRole(); // Ambil role dari prefs

      if (role == 'admin') {
        // Jika admin, lempar ke halaman Dashboard Admin
        context.pushAndRemoveAll(Home());
        print("Arahkan ke Admin Dashboard");
      } else {
        // Jika user biasa, lempar ke Home
        context.pushAndRemoveAll(const HomeUser());
      }
    } else {
      // 3. Jika belum login, ke halaman Welcome/Login
      context.pushAndRemoveAll(const Login());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),

      body: Center(
        child: Column(
          children: [
            SizedBox(height: 200),
            Image.asset('assets/images/logof1.png', height: 200),
            Row(
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
          ],
        ),
      ),
    );
  }
}
