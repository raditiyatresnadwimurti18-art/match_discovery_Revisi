import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:match_discovery/home_user/asset_lomba/daftar_lomba.dart';
import 'package:match_discovery/home_user/promo_slider.dart';
import 'package:match_discovery/util/app_theme.dart';

class IsiHomeUser extends StatelessWidget {
  const IsiHomeUser({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        centerTitle: false,
        title: Image.asset(
          'assets/images/logo.png',
          height: 28,
          errorBuilder: (context, error, stackTrace) => Text(
            "Match Discovery",
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: kPrimaryColor,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded, color: kPrimaryColor, size: 26),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, Peserta! \u{1F44B}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Temukan kompetisi terbaik untuk karirmu.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const PromoSlider(),
            const SizedBox(height: 10),
            const DaftarLomba(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
