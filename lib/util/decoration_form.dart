import 'package:flutter/material.dart';
import 'package:match_discovery/util/app_theme.dart';

InputDecoration decorationConstant({
  required String hintText,
  String? labelText,
  IconData? prefixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    labelText: labelText,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
    labelStyle: kSubtitleStyle,
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, color: Colors.grey.shade400, size: 20)
        : null,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kBorderRadius - 2),
      borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kBorderRadius - 2),
      borderSide: const BorderSide(color: kPrimaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kBorderRadius - 2),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kBorderRadius - 2),
      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
    ),
    filled: true,
    fillColor: Colors.grey.shade50,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}