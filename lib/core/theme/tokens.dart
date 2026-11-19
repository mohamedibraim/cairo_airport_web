import 'package:flutter/material.dart';

/// Centralized design tokens from the Master System Blueprint §18.
/// Do not introduce arbitrary brand colors or spacing values in features.
abstract final class AppColors {
  static const page = Color(0xFFF8FBFC);
  static const icy = Color(0xFFEAF8FB);
  static const surface = Color(0xFFFFFFFF);
  static const soft = Color(0xFFF1FAFC);
  static const border = Color(0xFFDEEDF1);
  static const divider = Color(0xFFE8F1F4);

  static const primary = Color(0xFF66C2C3);
  static const action = Color(0xFF0E7379);
  static const navy = Color(0xFF0C2132);
  static const sidebarTop = Color(0xFF0B3441);
  static const sidebarBottom = Color(0xFF082B37);

  static const text = Color(0xFF0C2132);
  static const muted = Color(0xFF64818D);
  static const onSidebar = Color(0xFFDCEDEF);
  static const onSidebarMuted = Color(0xFF8FB0B8);

  static const success = Color(0xFF22A06B);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  static const unknown = Color(0xFF94A3B8);

  static const successSoft = Color(0xFFE9F7F0);
  static const warningSoft = Color(0xFFFEF5E4);
  static const dangerSoft = Color(0xFFFDECEC);
  static const infoSoft = Color(0xFFECF2FE);
  static const tealSoft = Color(0xFFE7F6F7);
  static const neutralSoft = Color(0xFFF2F6F8);
}

abstract final class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class AppRadius {
  static const double major = 20;
  static const double nested = 16;
  static const double control = 12;
  static const double chip = 8;
  static const double pill = 999;
}

abstract final class AppShadow {
  static const card = BoxShadow(
    color: Color(0x0A0C2132),
    blurRadius: 14,
    offset: Offset(0, 4),
  );
  static const raised = BoxShadow(
    color: Color(0x140C2132),
    blurRadius: 22,
    offset: Offset(0, 8),
  );
}
