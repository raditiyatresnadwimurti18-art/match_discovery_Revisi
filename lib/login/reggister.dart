import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/auth.dart';
import 'package:match_discovery/extension/navigator.dart';
import 'package:match_discovery/login/login1.dart';
import 'package:match_discovery/models/login_model.dart';
import 'package:match_discovery/util/app_theme.dart';
import 'package:match_discovery/util/decoration_form.dart';

class Reggister extends StatefulWidget {
  const Reggister({super.key});

  @override
  State<Reggister> createState() => _ReggisterState();
}

class _ReggisterState extends State<Reggister> {
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();
  final namaController     = TextEditingController();
  final tlponController    = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading         = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    namaController.dispose();
    tlponController.dispose();
    super.dispose();
  }

  void _showEmailTerdaftarDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                "Email Sudah Terdaftar",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '"${emailController.text}" sudah digunakan oleh akun lain.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gunakan email lain atau masuk dengan akun yang sudah ada.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Coba Email Lain",
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: kPrimaryButtonStyle(radius: 12),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.pushAndRemoveAll(const Login1());
            },
            child: const Text("Masuk"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kPrimaryColor),
          onPressed: () => context.pushAndRemoveAll(const Login1()),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              // ✅ Logo — zoom in
              ZoomIn(
                duration: const Duration(milliseconds: 600),
                child: Image.asset('assets/images/logo.png', height: 180),
              ),

              // ✅ Judul — fade in dari atas
              FadeInDown(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 500),
                child: const Text('Buat Akun Baru', style: kTitleStyle),
              ),
              const SizedBox(height: 4),
              FadeInDown(
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 500),
                child: const Text('Daftarkan diri kamu sekarang!',
                    style: kSubtitleStyle),
              ),
              const SizedBox(height: 24),

              // ✅ Form fields — masing-masing slide dari kiri bertahap
              FadeInLeft(
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Email tidak boleh kosong';
                          if (!v.contains('@')) return 'Harus mengandung @';
                          if (!v.contains('gmail.com'))
                            return 'Email tidak valid';
                          return null;
                        },
                        decoration: decorationConstant(
                          hintText: 'Email',
                          labelText: 'Email',
                          prefixIcon: Icons.email_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Password
                      TextFormField(
                        obscureText: !_isPasswordVisible,
                        controller: passwordController,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Isi dulu bos!';
                          if (v.length < 8) return 'Kurang panjang (min 8)';
                          if (!v.contains(RegExp(r'[A-Z]')))
                            return 'Butuh huruf kapital';
                          if (!v.contains(RegExp(r'[0-9]')))
                            return 'Butuh angka';
                          return null;
                        },
                        decoration: decorationConstant(
                          hintText: 'Password',
                          labelText: 'Password',
                          prefixIcon: Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(() =>
                                _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Nama
                      TextFormField(
                        controller: namaController,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Nama tidak boleh kosong'
                            : null,
                        decoration: decorationConstant(
                          hintText: 'Nama Lengkap',
                          labelText: 'Nama',
                          prefixIcon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // No Telepon
                      TextFormField(
                        controller: tlponController,
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'No. telepon tidak boleh kosong'
                            : null,
                        decoration: decorationConstant(
                          hintText: 'No. Telepon',
                          labelText: 'Telepon',
                          prefixIcon: Icons.phone_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // ✅ Tombol Daftar — bounce in dari bawah
              BounceInUp(
                delay: const Duration(milliseconds: 600),
                duration: const Duration(milliseconds: 600),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            setState(() => _isLoading = true);

                            final berhasil =
                                await AuthController.registerUser(
                              LoginModel(
                                nama: namaController.text,
                                password: passwordController.text,
                                tlpon: tlponController.text,
                                email: emailController.text,
                              ),
                            );

                            if (!mounted) return;
                            setState(() => _isLoading = false);

                            if (!berhasil) {
                              _showEmailTerdaftarDialog();
                              return;
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Akun berhasil dibuat!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            await Future.delayed(const Duration(seconds: 1));
                            if (!mounted) return;
                            context.push(Login1());
                          },
                    style: kPrimaryButtonStyle(),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Daftar'),
                              Icon(Icons.chevron_right),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              FadeIn(
                delay: const Duration(milliseconds: 800),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah punya akun?'),
                    TextButton(
                      onPressed: () => context.push(Login1()),
                      child: const Text('Masuk',
                          style: TextStyle(color: kPrimaryColor)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}