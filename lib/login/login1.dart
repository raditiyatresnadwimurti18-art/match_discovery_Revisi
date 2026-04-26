import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/auth.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/extension/navigator.dart';
import 'package:match_discovery/home_user/home_user.dart';
import 'package:match_discovery/login/login.dart';
import 'package:match_discovery/login/reggister.dart';
import 'package:match_discovery/util/app_theme.dart';
import 'package:match_discovery/util/decoration_form.dart';

class Login1 extends StatefulWidget {
  const Login1({super.key});

  @override
  State<Login1> createState() => _Login1State();
}

class _Login1State extends State<Login1> {
  bool _isPasswordVisible = false;
  bool _isLoading         = false;
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _masukSebagaiTamu() async {
    await PreferenceHandler.setRole('guest');
    await PreferenceHandler.storingIsLogin(false);
    if (!mounted) return;
    context.pushAndRemoveAll(HomeUser());
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Lupa Password', style: kTitleStyle),
          content: SingleChildScrollView(
            child: Form(
              key: dialogFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Masukkan email Anda untuk menerima link reset password.',
                    style: kSubtitleStyle,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email tidak boleh kosong';
                      if (!v.contains('@')) return 'Email tidak valid';
                      return null;
                    },
                    decoration: decorationConstant(
                      hintText: 'Email',
                      labelText: 'Email',
                      prefixIcon: Icons.email_outlined,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kBorderRadius - 4),
                ),
              ),
              onPressed: () async {
                if (!dialogFormKey.currentState!.validate()) return;

                final result = await AuthController.forgotPassword(
                  resetEmailController.text.trim(),
                );

                if (!mounted) return;
                Navigator.pop(context);

                if (result == 'success') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email reset password telah dikirim! Silakan cek inbox Anda.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  String message = 'Terjadi kesalahan. Silakan coba lagi.';
                  if (result == 'user-not-found') {
                    message = 'Email anda belum terdaftar.';
                  } else if (result == 'invalid-email') {
                    message = 'Format email tidak valid.';
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Kirim', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
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
          onPressed: () => context.pushAndRemoveAll(const Login()),
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
                child: Image.asset('assets/images/logo.png', height: 220),
              ),

              // ✅ Judul — fade in dari atas
              FadeInDown(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 500),
                child: Text('Masuk ke Akun', style: kTitleStyle),
              ),
              const SizedBox(height: 4),
              FadeInDown(
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 500),
                child: Text('Selamat datang kembali!',
                    style: kSubtitleStyle),
              ),
              const SizedBox(height: 24),

              // ✅ Form — fade in dari bawah
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 500),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Email tidak boleh kosong';
                          if (!v.contains('@')) return 'Email tidak valid';
                          return null;
                        },
                        decoration: decorationConstant(
                          hintText: 'Email',
                          labelText: 'Email',
                          prefixIcon: Icons.email_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordController,
                        obscureText: !_isPasswordVisible,
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Password tidak boleh kosong';
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // ✅ Tombol-tombol — fade in dari bawah bertahap
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                duration: const Duration(milliseconds: 400),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: kPrimaryButtonStyle(),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            setState(() => _isLoading = true);

                            final login =
                                await AuthController.login(
                              emailController.text,
                              passwordController.text,
                            );

                            if (!mounted) return;
                            setState(() => _isLoading = false);

                            if (login != null) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Login Berhasil! Selamat Datang.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              await Future.delayed(const Duration(seconds: 1));
                              if (!mounted) return;
                              context.pushAndRemoveAll(const HomeUser());
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Email atau Password salah!'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
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
                              Text('Masuk'),
                              Icon(Icons.chevron_right),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              FadeInUp(
                delay: const Duration(milliseconds: 600),
                duration: const Duration(milliseconds: 400),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _showForgotPasswordDialog,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kPrimaryColor),
                      foregroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(kBorderRadius - 2)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Lupa Password'),
                        Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              FadeInUp(
                delay: const Duration(milliseconds: 700),
                duration: const Duration(milliseconds: 400),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _masukSebagaiTamu,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400),
                      foregroundColor: Colors.grey.shade700,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(kBorderRadius - 2)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Masuk Tanpa Akun'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              FadeInUp(
                delay: const Duration(milliseconds: 800),
                duration: const Duration(milliseconds: 400),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Belum punya akun?'),
                    TextButton(
                      onPressed: () => context.push(Reggister()),
                      child: const Text('Daftar',
                          style: TextStyle(color: kPrimaryColor)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}