import 'package:animate_do/animate_do.dart';
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
    // ✅ Durasi splash diperpanjang sedikit agar animasi selesai
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;

    final bool? isLogin = await PreferenceHandler.getIsLogin();
    final String? role = await PreferenceHandler.getRole();

    if (!mounted) return;

    if (isLogin == true && (role == 'admin' || role == 'super')) {
      context.pushAndRemoveAll(const Home());
    } else if (isLogin == true && role == 'user') {
      context.pushAndRemoveAll(const HomeUser());
    } else {
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
            // ✅ Logo — zoom in dari kecil
            ZoomIn(
              duration: const Duration(milliseconds: 700),
              child: Image.asset('assets/images/logo.png', height: 200),
            ),

            const SizedBox(height: 16),

            // ✅ Teks "Discovery" — slide dari kiri
            FadeInLeft(
              delay: const Duration(milliseconds: 500),
              duration: const Duration(milliseconds: 600),
              child: const Text(
                'Discovery',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: Color(0xffcdb060),
                ),
              ),
            ),

            // ✅ Teks "Match" — slide dari kanan
            FadeInRight(
              delay: const Duration(milliseconds: 600),
              duration: const Duration(milliseconds: 600),
              child: const Text(
                'Match',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: Color(0xff112955),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ✅ Tagline — fade in dari bawah
            FadeInUp(
              delay: const Duration(milliseconds: 800),
              duration: const Duration(milliseconds: 500),
              child: const Text(
                'Temukan lomba, raih prestasi',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 48),

            // ✅ Loading indicator — fade in terakhir
            FadeIn(
              delay: const Duration(milliseconds: 1000),
              duration: const Duration(milliseconds: 400),
              child: const CircularProgressIndicator(
                color: Color(0xff112955),
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
