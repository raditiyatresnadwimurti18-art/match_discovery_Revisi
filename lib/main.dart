import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/admin.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/firebase_options.dart';
import 'package:match_discovery/models/admin_model.dart';
import 'package:match_discovery/view/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  await _initializeSuperAdmin();
  runApp(const MainApp());
}

Future<void> _initializeSuperAdmin() async {
  bool initialized = await PreferenceHandler.getSuperAdminInitialized();
  if (!initialized) {
    // Check if super admin already exists in Firestore
    List<AdminModel> admins = await AdminController.getSemuaAdmin();
    bool superAdminExists = admins.any((admin) => admin.role == 'super');

    if (!superAdminExists) {
      // Add super admin to Firestore
      AdminModel superAdmin = AdminModel(
        nama: 'Super Admin',
        username: '111',
        password: '222',
        role: 'super',
        profilePath: '',
      );
      await AdminController.addAdmin(superAdmin);
    }

    // Mark as initialized
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
