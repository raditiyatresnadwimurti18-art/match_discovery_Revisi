import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/admin.dart';
import 'package:match_discovery/database/controllers/auth.dart';
import 'package:match_discovery/database/notification_service.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/firebase_options.dart';
import 'package:match_discovery/models/admin_model.dart';
import 'package:match_discovery/view/splash.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Inisialisasi Notifikasi
  await NotificationService.init();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await PreferenceHandler.init(); // Inisialisasi preferensi

  // Aktifkan listener jika sudah login
  if (PreferenceHandler.getIsLogin() == true) {
    NotificationService.subscribeToLombaTopic();
    NotificationService.listenToNewLomba();
  }

  await setupSuperAdmin();
  runApp(const MainApp());
}

Future<void> setupSuperAdmin() async {
  bool initialized = PreferenceHandler.getSuperAdminInitialized();
  if (!initialized) {
    print("Main: Menginisialisasi Super Admin...");
    try {
      // 1. Daftarkan di Firebase Authentication (agar bisa upload gambar)
      // Ini juga akan menyimpan datanya ke Firestore koleksi 'admins'
      await AuthController.registerAdmin(
        AdminModel(
          nama: 'Super Admin',
          username: '111',
          password: '222',
          email: '111@admin.com',
          role: 'super',
          profilePath: '',
        ),
      );
      print("Main: Berhasil mendaftarkan Super Admin di Auth & Firestore.");
    } catch (e) {
      print("Main: Super Admin Auth mungkin sudah ada: $e");
    }

    // Mark as initialized agar tidak dijalankan terus menerus
    await PreferenceHandler.setSuperAdminInitialized(true);
  }
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
