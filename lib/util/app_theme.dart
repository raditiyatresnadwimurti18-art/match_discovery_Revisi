import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Warna (Modern Palette) ────────────────────────────────
const kPrimaryColor = Color(0xff0f2a55); // Navy Utama
const kPrimaryLight = Color(0xFF1e4d8c);
const kSecondaryColor = Color(0xFFB8860B); // Gold Logo
const kAccentColor = Color(0xFF2196F3); // Blue Accent
const kBgColor = Color(0xFFF8FAFF); // Soft Blue-Grey Background
const kSurfaceColor = Colors.white;
const kErrorColor = Color(0xFFD32F2F);
const kSuccessColor = Color(0xFF388E3C);
const kDangerColor = Color(0xFFD32F2F);
const kWarningColor = Color(0xFFFFA000);

const kBorderRadius = 20.0;
const kCardRadius = 24.0;

// ── Gradient ──────────────────────────────────────────────
const kPrimaryGradient = LinearGradient(
  colors: [kPrimaryColor, kPrimaryLight],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const kAccentGradient = LinearGradient(
  colors: [kSecondaryColor, Color(0xFFDAA520)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// ── BoxDecoration ─────────────────────────────────────────
BoxDecoration kCardDecoration({double? radius}) => BoxDecoration(
  color: kSurfaceColor,
  borderRadius: BorderRadius.circular(radius ?? kCardRadius),
  boxShadow: [
    BoxShadow(
      color: kPrimaryColor.withOpacity(0.06),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ],
);

BoxDecoration kGlassDecoration({double radius = 20}) => BoxDecoration(
  color: Colors.white.withOpacity(0.8),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: Colors.white.withOpacity(0.2)),
);

const kHeaderDecoration = BoxDecoration(
  gradient: kPrimaryGradient,
  borderRadius: BorderRadius.only(
    bottomLeft: Radius.circular(32),
    bottomRight: Radius.circular(32),
  ),
);

BoxDecoration kBadgeDecoration([Color color = kPrimaryColor]) => BoxDecoration(
  color: color.withOpacity(0.1),
  borderRadius: BorderRadius.circular(8),
);

// ── TextStyle (Using Google Fonts) ────────────────────────
TextStyle get kDisplayStyle => GoogleFonts.plusJakartaSans(
  color: kPrimaryColor,
  fontSize: 24,
  fontWeight: FontWeight.bold,
);

TextStyle get kTitleStyle => GoogleFonts.plusJakartaSans(
  color: kPrimaryColor,
  fontSize: 18,
  fontWeight: FontWeight.w700,
);

TextStyle get kBodyStyle =>
    GoogleFonts.plusJakartaSans(color: Colors.black87, fontSize: 14);

TextStyle get kSubtitleStyle =>
    GoogleFonts.plusJakartaSans(color: Colors.black54, fontSize: 13);

TextStyle get kWhiteBoldStyle => GoogleFonts.plusJakartaSans(
  color: Colors.white,
  fontWeight: FontWeight.bold,
  fontSize: 16,
);

TextStyle get kWhiteSubStyle =>
    GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12);

TextStyle get kAccentTextStyle => GoogleFonts.plusJakartaSans(
  color: kSecondaryColor,
  fontWeight: FontWeight.bold,
  fontSize: 14,
);

// ── Button Styles ─────────────────────────────────────────
ButtonStyle kPrimaryButtonStyle({double radius = 16}) =>
    ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      elevation: 2,
      shadowColor: kPrimaryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
    );

ButtonStyle kSecondaryButtonStyle({double radius = 16}) =>
    OutlinedButton.styleFrom(
      foregroundColor: kPrimaryColor,
      side: const BorderSide(color: kPrimaryColor, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
    );

ButtonStyle kDangerButtonStyle({double radius = 16}) =>
    ElevatedButton.styleFrom(
      backgroundColor: kErrorColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
    );

// ── Custom Components ─────────────────────────────────────
AppBar kModernAppBar({
  required String title,
  Widget? leading,
  List<Widget>? actions,
  bool centerTitle = true,
  bool automaticallyImplyLeading = true,
}) => AppBar(
  title: Text(title, style: kWhiteBoldStyle),
  leading: leading,
  actions: actions,
  centerTitle: centerTitle,
  automaticallyImplyLeading: automaticallyImplyLeading,
  backgroundColor: kPrimaryColor,
  elevation: 0,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
  ),
);

AppBar kPrimaryAppBar({
  required String title,
  List<Widget>? actions,
  Widget? leading,
  bool centerTitle = true,
  bool automaticallyImplyLeading = true,
}) => kModernAppBar(
  title: title,
  actions: actions,
  leading: leading,
  centerTitle: centerTitle,
  automaticallyImplyLeading: automaticallyImplyLeading,
);

// ── Animation Helpers ─────────────────────────────────────
class PageTransition extends PageRouteBuilder {
  final Widget child;
  PageTransition({required this.child})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutQuart;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      );
}
