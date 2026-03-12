import 'package:flutter/material.dart';
import 'package:match_discovery/login/login.dart';
import 'package:match_discovery/view/splash.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashscreenT16(),
    );
  }
}
