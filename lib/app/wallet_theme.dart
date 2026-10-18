import 'package:flutter/material.dart';

abstract final class WalletColors {
  static const background = Color(0xFF0D1117);
  static const surface = Color(0xFF151C25);
  static const border = Color(0xFF273240);
  static const muted = Color(0xFF9EAFC1);
  static const accent = Color(0xFF89E2BC);
  static const loss = Color(0xFFFFA4A4);
}

ThemeData buildWalletTheme() => ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  scaffoldBackgroundColor: WalletColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: WalletColors.accent,
    brightness: Brightness.dark,
    surface: WalletColors.surface,
    primary: WalletColors.accent,
  ),
  fontFamily: 'Segoe UI',
  dividerColor: WalletColors.border,
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  dataTableTheme: const DataTableThemeData(
    headingTextStyle: TextStyle(
      color: WalletColors.muted,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    dataTextStyle: TextStyle(color: Color(0xFFE8EFF7), fontSize: 14),
    dividerThickness: 0.5,
    headingRowHeight: 52,
    dataRowMinHeight: 80,
    dataRowMaxHeight: 80,
  ),
);
