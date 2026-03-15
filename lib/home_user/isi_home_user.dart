import 'package:flutter/material.dart';
import 'package:match_discovery/home_user/asset_lomba/daftar_lomba.dart';
import 'package:match_discovery/home_user/promo_slider.dart';
import 'package:match_discovery/util/app_theme.dart';

class IsiHomeUser extends StatelessWidget {
  const IsiHomeUser({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBgColor,
      child: const SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PromoSlider(),
            SizedBox(height: 8),
            DaftarLomba(),
          ],
        ),
      ),
    );
  }
}