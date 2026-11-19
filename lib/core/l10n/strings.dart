import 'package:flutter/material.dart';

/// Bilingual string helper. Every user-facing label is declared once with its
/// English and Arabic form. IDs, codes, flight numbers and times are never
/// translated — they are wrapped in an LTR island widget in the UI.
class AppStrings {
  final bool arabic;
  const AppStrings({required this.arabic});

  Locale get locale => arabic ? const Locale('ar') : const Locale('en');
  TextDirection get direction => arabic ? TextDirection.rtl : TextDirection.ltr;
  String get fontFamily => arabic ? 'Cairo' : 'Inter';

  String tr(String en, String ar) => arabic ? ar : en;

  String tf(String en, String ar, Map<String, String> params) {
    var value = tr(en, ar);
    params.forEach((key, replacement) {
      value = value.replaceAll('{$key}', replacement);
    });
    return value;
  }
}
