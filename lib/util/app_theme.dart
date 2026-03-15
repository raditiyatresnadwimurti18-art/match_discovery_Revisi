import 'package:flutter/material.dart';

// ── Warna ────────────────────────────────────────────────
const kPrimaryColor = Color(0xff0f2a55); // Navy — warna utama
const kAccentColor  = Color(0xFFB8860B); // Gold — warna logo
const kBgColor      = Color(0xFFF0F3F8);
const kBorderRadius = 18.0;

// ── Gradient ──────────────────────────────────────────────
const kPrimaryGradient = LinearGradient(
  colors: [Color(0xff0f2a55), Color(0xFF1e4d8c)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// ── BoxDecoration ─────────────────────────────────────────
BoxDecoration kCardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(kBorderRadius),
      boxShadow: [
        BoxShadow(
          color: kPrimaryColor.withOpacity(0.07),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );

const kHeaderDecoration = BoxDecoration(
  gradient: kPrimaryGradient,
  borderRadius: BorderRadius.only(
    bottomLeft: Radius.circular(28),
    bottomRight: Radius.circular(28),
  ),
);

BoxDecoration kBadgeDecoration({Color? color, double radius = 20}) =>
    BoxDecoration(
      color: (color ?? Colors.white).withOpacity(0.2),
      borderRadius: BorderRadius.circular(radius),
    );

BoxDecoration kAccentBadgeDecoration({double radius = 20}) => BoxDecoration(
      color: kAccentColor.withOpacity(0.12),
      borderRadius: BorderRadius.circular(radius),
    );

// ── TextStyle ─────────────────────────────────────────────
const kTitleStyle = TextStyle(
  color: kPrimaryColor,
  fontSize: 16,
  fontWeight: FontWeight.bold,
);

const kSubtitleStyle = TextStyle(
  color: Colors.grey,
  fontSize: 13,
);

const kWhiteBoldStyle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.bold,
  fontSize: 14,
);

const kWhiteSubStyle = TextStyle(
  color: Colors.white70,
  fontSize: 12,
);

const kAccentTextStyle = TextStyle(
  color: kAccentColor,
  fontWeight: FontWeight.bold,
  fontSize: 13,
);

// ── Button Style ──────────────────────────────────────────
ButtonStyle kPrimaryButtonStyle({double radius = 16}) =>
    ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
    );

ButtonStyle kDangerButtonStyle({double radius = 12}) =>
    ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
    );

// ── AppBar ────────────────────────────────────────────────
AppBar kPrimaryAppBar({
  required String title,
  bool centerTitle = true,
  bool roundedBottom = true, // ✅ true = rounded, false = runcing
  bool automaticallyImplyLeading = true,
  List<Widget>? actions,
  Widget? leading,
}) =>
    AppBar(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      elevation: 0,
      title: Text(title, style: kWhiteBoldStyle),
      actions: actions,
      leading: leading,
      // ✅ rounded hanya jika roundedBottom: true
      shape: roundedBottom
          ? const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            )
          : null,
    );