import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/auth.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/extension/navigator.dart';
import 'package:match_discovery/home_admin/home.dart';
import 'package:match_discovery/login/login1.dart';
import 'package:match_discovery/util/app_theme.dart';
import 'package:match_discovery/util/decoration_form.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  void _showAdminLoginDialog(BuildContext context) {
    final userAdmin = TextEditingController();
    final passAdmin = TextEditingController();
    bool isPasswordVisible = false;
    final outerContext = context;

    showDialog(
      context: outerContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: kPrimaryColor),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "Login Admin",
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: userAdmin,
                  decoration: decorationConstant(
                    hintText: 'Username Admin',
                    labelText: 'Username',
                    prefixIcon: Icons.alternate_email,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passAdmin,
                  obscureText: !isPasswordVisible,
                  decoration:
                      decorationConstant(
                        hintText: 'Password',
                        labelText: 'Password',
                        prefixIcon: Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () => setStateDialog(
                            () => isPasswordVisible = !isPasswordVisible,
                          ),
                        ),
                      ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  "Batal",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: kPrimaryButtonStyle(radius: 12),
                onPressed: () async {
                  var adminData = await AuthController.loginAdminModel(
                    username: userAdmin.text,
                    password: passAdmin.text,
                  );

                  if (adminData != null) {
                    await PreferenceHandler.setRole('admin');

                    await PreferenceHandler.storingAdminId(adminData.id!);
                    await PreferenceHandler.storingIsLogin(true);

                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);

                    if (!outerContext.mounted) return;
                    outerContext.pushAndRemoveAll(const Home());
                    ScaffoldMessenger.of(outerContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Selamat Datang, ${adminData.nama ?? 'Admin'}!",
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    if (!dialogContext.mounted) return;
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text("Username atau Password Salah"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text("Login"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withAlpha(45),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: kSubtitleStyle.copyWith(color: Colors.black87),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 24),
              decoration: kHeaderDecoration,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(1, 4),
                        ),
                      ],
                    ),
                    child: Image.asset('assets/images/logo.png', height: 150),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Platform terpercaya untuk menemukan partner dan info kompetisi terbaik.',
                      style: kWhiteSubStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Kartu Fitur ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _featureCard(
                    icon: Icons.people,
                    color: kPrimaryColor,
                    title: 'Cari Partner Lomba',
                    desc:
                        'Temukan rekan tim yang memiliki keahlian dan visi yang sama untuk menang.',
                  ),
                  const SizedBox(height: 14),
                  _featureCard(
                    icon: Icons.search,
                    color: Colors.red,
                    title: 'Temukan Info Lomba',
                    desc:
                        'Dapatkan update kompetisi nasional hingga internasional secara real-time.',
                  ),
                  const SizedBox(height: 14),
                  _featureCard(
                    icon: Icons.message,
                    color: Colors.green,
                    title: 'Terhubung dengan Peserta',
                    desc:
                        'Bangun koneksi dan diskusikan strategi dengan peserta dari berbagai daerah.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Tombol ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => context.push(Login1()),
                      style: kPrimaryButtonStyle(),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Text('Lanjut'), Icon(Icons.chevron_right)],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showAdminLoginDialog(context),
                    child: Text(
                      'Masuk sebagai Admin',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
