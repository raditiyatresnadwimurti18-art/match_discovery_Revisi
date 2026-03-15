import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/auth.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/extension/navigator.dart';
import 'package:match_discovery/home_user/home_user.dart';
import 'package:match_discovery/login/login.dart';
import 'package:match_discovery/login/reggister.dart';
import 'package:match_discovery/models/login_model.dart';
import 'package:match_discovery/util/app_theme.dart';
import 'package:match_discovery/util/decoration_form.dart';

class Login1 extends StatefulWidget {
  const Login1({super.key});

  @override
  State<Login1> createState() => _Login1State();
}

class _Login1State extends State<Login1> {
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
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
              Image.asset('assets/images/logo.png', height: 220),
              const Text('Masuk ke Akun', style: kTitleStyle),
              const SizedBox(height: 4),
              const Text('Selamat datang kembali!', style: kSubtitleStyle),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email
                    TextFormField(
                      controller: emailController,
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
                    const SizedBox(height: 12),

                    // Password
                    TextFormField(
                      controller: passwordController,
                      obscureText: !_isPasswordVisible,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password tidak boleh kosong';
                        return null;
                      },
                      decoration: decorationConstant(
                        hintText: 'Password',
                        labelText: 'Password',
                        prefixIcon: Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () =>
                              setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Tombol Masuk
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _isLoading = true);

                          final LoginModel? login = await AuthController.loginUser(
                            email: emailController.text,
                            password: passwordController.text,
                          );

                          if (!mounted) return;
                          setState(() => _isLoading = false);

                          if (login != null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Login Berhasil! Selamat Datang.'),
                              backgroundColor: Colors.green,
                            ));
                            await Future.delayed(const Duration(seconds: 1));
                            if (!mounted) return;
                            await PreferenceHandler.storingIsLogin(true);
                            context.pushAndRemoveAll(HomeUser());
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Email atau Password salah!'),
                              backgroundColor: Colors.red,
                            ));
                          }
                        },
                  style: kPrimaryButtonStyle(),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Text('Masuk'), Icon(Icons.chevron_right)],
                        ),
                ),
              ),
              const SizedBox(height: 10),

              // Tombol Lupa Password
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kPrimaryColor),
                    foregroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius - 2)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Text('Lupa Password'), Icon(Icons.chevron_right)],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Row(
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
            ],
          ),
        ),
      ),
    );
  }
}