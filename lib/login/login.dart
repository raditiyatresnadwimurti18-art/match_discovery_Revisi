import 'package:flutter/material.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/database/sql_lite.dart';
import 'package:match_discovery/extension/navigator.dart';
import 'package:match_discovery/home_admin/home.dart';
import 'package:match_discovery/login/login1.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  void _showAdminLoginDialog(BuildContext context) {
    final TextEditingController userAdmin = TextEditingController();
    final TextEditingController passAdmin = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Login Admin"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userAdmin,
              decoration: const InputDecoration(labelText: "Username Admin"),
            ),
            TextField(
              controller: passAdmin,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              // 1. Panggil fungsi login yang baru
              var adminData = await DBHelper.loginAdminModel(
                username: userAdmin.text,
                password: passAdmin.text,
              );

              if (adminData != null) {
                // 2. Simpan Role Admin (Super/Biasa) ke Preferences
                // Pastikan kamu sudah menambahkan fungsi setAdminRole di PreferenceHandler
                await PreferenceHandler.setRole('admin');

                // Tambahan: Simpan role spesifiknya (Misal pakai SharedPreferences langsung jika belum ada di PreferenceHandler)
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('admin_type', adminData.role);

                if (!mounted) return;
                Navigator.pop(context); // Tutup Dialog

                // 3. Pindah ke Home Admin
                context.push(const Home());

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Selamat Datang, ${adminData.nama ?? 'Admin'}!",
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Username atau Password Salah")),
                );
              }
            },
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              child: Column(
                children: [
                  SizedBox(height: 34),
                  Image.asset('assets/images/logof1.png', height: 160),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: Text(
                      'Platform terpercaya untuk menemukan partner dan info kompetisi terbaik.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.blueAccent.withAlpha(45),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.people),
                          SizedBox(width: 30),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Cari Partner Lomba',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  'Temukan rekan tim yang memiliki keahlian dan visi yang sama untuk menang.',
                                  style: TextStyle(),
                                  textAlign: TextAlign.justify,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color.fromARGB(
                        255,
                        255,
                        68,
                        68,
                      ).withAlpha(45),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.search),
                          SizedBox(width: 30),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Temukan Info Lomba',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  'Dapatkan update kompetisi nasional hingga internasional secara real-time.',
                                  style: TextStyle(),
                                  textAlign: TextAlign.justify,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color.fromARGB(
                        255,
                        68,
                        255,
                        162,
                      ).withAlpha(45),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.message),
                          SizedBox(width: 30),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Terhubung dengan Peserta',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  'Bangun koneksi dan diskusikan strategi dengan peserta dari berbagai daerah.',
                                  style: TextStyle(),
                                  textAlign: TextAlign.justify,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Login1()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Lanjut', style: TextStyle(color: Colors.white)),
                          Icon(Icons.chevron_right, color: Colors.white),
                        ],
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      // Arahkan ke halaman login khusus admin atau
                      // munculkan dialog login admin
                      _showAdminLoginDialog(context);
                    },
                    child: Text(
                      'Masuk sebagai Admin',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
