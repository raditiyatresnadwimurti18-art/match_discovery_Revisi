import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/extension/navigator.dart';
import 'package:match_discovery/home_admin/home.dart';
import 'package:match_discovery/home_user/home_user.dart';
import 'package:match_discovery/login/login.dart';
import 'package:match_discovery/util/app_theme.dart';

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

    final bool? isLogin = PreferenceHandler.getIsLogin();
    final String? role = PreferenceHandler.getRole();

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
      backgroundColor: kBgColor,
      body: Stack(
        children: [
          // Latar belakang dekoratif
          Positioned(
            top: -100,
            right: -100,
            child: FadeInDown(
              duration: const Duration(milliseconds: 1000),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.03),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ZoomIn(
                  duration: const Duration(milliseconds: 800),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryColor.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset('assets/images/logo.png', height: 120),
                  ),
                ),
                const SizedBox(height: 40),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Discovery',
                        style: kDisplayStyle.copyWith(
                          fontSize: 32,
                          color: kPrimaryColor,
                        ),
                      ),
                      Text(
                        'Match',
                        style: kDisplayStyle.copyWith(
                          fontSize: 32,
                          color: kSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: Text(
                    'Temukan lomba, raih prestasi',
                    style: kSubtitleStyle.copyWith(
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                FadeIn(
                  delay: const Duration(milliseconds: 1000),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: kPrimaryColor,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeInUp(
              delay: const Duration(milliseconds: 1200),
              child: Center(
                child: Text(
                  'v1.2.0 • 2026',
                  style: kSubtitleStyle.copyWith(fontSize: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
