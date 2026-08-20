import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Skala tipe Rukun. DESIGN.md §3
///
/// Dua keluarga huruf dengan peran yang tegas:
/// - **Plus Jakarta Sans** (buatan Indonesia, Tokotype) — display & angka besar
/// - **Inter** — UI & body. Padanan bebas terdekat dari SF Pro.
///
/// Aturan: maksimal 2 tingkat hirarki per layar. Angka data selalu tabular.
abstract final class RukunText {
  /// Fitur OpenType untuk angka tabular — angka tidak goyang saat berubah.
  /// Wajib untuk timer dan statistik.
  static const _tabular = [FontFeature.tabularFigures()];

  // ── Display (Plus Jakarta Sans) ──────────────────────────────────
  static TextStyle get display => GoogleFonts.plusJakartaSans(
        fontSize: 40,
        height: 44 / 40,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      );

  static TextStyle get judul1 => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        height: 38 / 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.64,
      );

  static TextStyle get judul2 => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        height: 30 / 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.24,
      );

  // ── UI & body (Inter) ────────────────────────────────────────────
  static TextStyle get judul3 => GoogleFonts.inter(
        fontSize: 20,
        height: 26 / 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      );

  static TextStyle get headline => GoogleFonts.inter(
        fontSize: 17,
        height: 22 / 17,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 17,
        height: 24 / 17,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get callout => GoogleFonts.inter(
        fontSize: 16,
        height: 22 / 16,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get subhead => GoogleFonts.inter(
        fontSize: 15,
        height: 20 / 15,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get footnote => GoogleFonts.inter(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.12,
      );

  /// Angka besar untuk timer & statistik. Selalu tabular.
  static TextStyle get angkaBesar => GoogleFonts.inter(
        fontSize: 56,
        height: 1.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.68,
        fontFeatures: _tabular,
      );

  /// Angka sedang tabular — untuk persentase wilayah.
  static TextStyle get angkaSedang => GoogleFonts.inter(
        fontSize: 32,
        height: 1.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.64,
        fontFeatures: _tabular,
      );

  /// Merakit [TextTheme] Material dari skala di atas.
  static TextTheme textTheme(Color primer, Color sekunder) => TextTheme(
        displayLarge: display.copyWith(color: primer),
        displayMedium: judul1.copyWith(color: primer),
        displaySmall: judul2.copyWith(color: primer),
        headlineMedium: judul3.copyWith(color: primer),
        titleLarge: judul3.copyWith(color: primer),
        titleMedium: headline.copyWith(color: primer),
        bodyLarge: body.copyWith(color: primer),
        bodyMedium: callout.copyWith(color: primer),
        bodySmall: subhead.copyWith(color: sekunder),
        labelLarge: headline.copyWith(color: primer),
        labelMedium: footnote.copyWith(color: sekunder),
        labelSmall: caption.copyWith(color: sekunder),
      );
}
