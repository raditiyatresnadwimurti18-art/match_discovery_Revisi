import 'package:flutter/material.dart';
import 'package:match_discovery/database/sql_lite.dart';
import 'package:match_discovery/extension/navigator.dart';
import 'package:match_discovery/login/login1.dart';
import 'package:match_discovery/models/login_model.dart';

class Reggister extends StatefulWidget {
  const Reggister({super.key});

  @override
  State<Reggister> createState() => _ReggisterState();
}

class _ReggisterState extends State<Reggister> {
  final TextEditingController emailControler = TextEditingController();
  final TextEditingController passwordControler = TextEditingController();
  final TextEditingController namaControler = TextEditingController();
  final TextEditingController tlponControler = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool x = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              Image.asset('assets/images/logo.png', height: 300),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: emailControler,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tidak boleh kosong';
                        } else if (!value.contains('@')) {
                          return 'Harus mengandung @';
                        } else if (!value.contains('gmail.com')) {
                          return 'Email tidak valid';
                        } else {
                          return null;
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(34),
                        ),
                        icon: Icon(Icons.email),
                        hintText: 'Email',
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      obscureText: x,
                      controller: passwordControler,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Isi dulu bos!';
                        } else if (value.length < 8) {
                          return 'Kurang panjang (min 8)';
                        } else if (!value.contains(RegExp(r'[A-Z]'))) {
                          return 'Butuh huruf kapital';
                        } else if (!value.contains(RegExp(r'[0-9]'))) {
                          return 'Butuh angka';
                        } else {
                          return null;
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(34),
                        ),
                        icon: Icon(Icons.password),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              x = !x;
                            });
                          },
                          icon: Icon(
                            x ? Icons.visibility_off : Icons.visibility,
                          ),
                        ),
                        hintText: 'Pasword',
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: namaControler,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama tidak boleh kosong';
                        } else {
                          return null;
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(34),
                        ),
                        icon: Icon(Icons.person),
                        hintText: 'Nama',
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: tlponControler,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tlpon tidak boleh kosong';
                        } else {
                          return null;
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(34),
                        ),
                        icon: Icon(Icons.phone),
                        hintText: 'No Tlpon',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          if (passwordControler.text.isEmpty ||
                              emailControler.text.isEmpty ||
                              namaControler.text.isEmpty ||
                              tlponControler.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Harus dilengkapi')),
                            );
                            return;
                          } else {
                            context.push(Login1());
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Data Ditambahkan')),
                            );
                          }
                          DBHelper.registerUser(
                            LoginModel(
                              nama: namaControler.text,
                              password: passwordControler.text,
                              tlpon: tlponControler.text,
                              email: emailControler.text,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Daftar',
                              style: TextStyle(
                                color: const Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),

                            Icon(
                              Icons.chevron_right,
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                          ],
                        ),
                      ),
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
