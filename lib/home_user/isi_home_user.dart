import 'dart:io';
import 'package:flutter/material.dart';
import 'package:match_discovery/home_user/asset_lomba/daftar_lomba.dart';
import 'package:match_discovery/home_user/promo_slider.dart';

class IsiHomeUser extends StatefulWidget {
  const IsiHomeUser({super.key});

  @override
  State<IsiHomeUser> createState() => _IsiHomeUserState();
}

class _IsiHomeUserState extends State<IsiHomeUser> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [PromoSlider(), DaftarLomba()],
        ),
      ),
    );
  }
}
