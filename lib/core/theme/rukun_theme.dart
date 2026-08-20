import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'rukun_colors.dart';
import 'rukun_gradients.dart';
import 'rukun_spacing.dart';
import 'rukun_typography.dart';

/// Tema Rukun untuk mode terang & gelap.
///
/// Mode gelap bukan renungan belakangan — metafora kabut justru lebih bagus
/// dalam gelap, dan sesi subuh/malam adalah kasus pakai nyata di Indonesia.
/// DESIGN.md §2.8
abstract final class RukunTheme {
  static ThemeData get terang => _bangun(
        brightness: Brightness.light,
        gradients: RukunGradients.terangTheme,
        latar: RukunColors.latarTerangA,
        permukaan: RukunColors.permukaanTerangA,
        teksPrimer: RukunColors.teksPrimerTerang,
        teksSekunder: RukunColors.teksSekunderTerang,
        pemisah: RukunColors.pemisahTerang,
      );

  static ThemeData get gelap => _bangun(
        brightness: Brightness.dark,
        gradients: RukunGradients.gelapTheme,
        latar: RukunColors.latarGelapA,
        permukaan: RukunColors.permukaanGelapA,
        teksPrimer: RukunColors.teksPrimerGelap,
        teksSekunder: RukunColors.teksSekunderGelap,
        pemisah: RukunColors.pemisahGelap,
      );

  static ThemeData _bangun({
    required Brightness brightness,
    required RukunGradients gradients,
    required Color latar,
    required Color permukaan,
    required Color teksPrimer,
    required Color teksSekunder,
    required Color pemisah,
  }) {
    final gelap = brightness == Brightness.dark;

    final skema = ColorScheme(
      brightness: brightness,
      // Warna datar ini hanya untuk komponen Material bawaan.
      // Elemen bermakna Rukun memakai gradient — lihat RukunGradients.
      primary: RukunColors.terangA,
      onPrimary: Colors.white,
      secondary: RukunColors.fajarA,
      onSecondary: Colors.white,
      tertiary: RukunColors.misiA,
      onTertiary: Colors.white,
      error: RukunColors.bahayaA,
      onError: Colors.white,
      surface: permukaan,
      onSurface: teksPrimer,
      onSurfaceVariant: teksSekunder,
      outline: pemisah,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: skema,
      scaffoldBackgroundColor: latar,
      textTheme: RukunText.textTheme(teksPrimer, teksSekunder),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,

      // Ikon garis 1.5 — halus, sesuai bahasa Apple.
      iconTheme: IconThemeData(color: teksPrimer, size: 24, weight: 500),

      dividerTheme: DividerThemeData(
        color: pemisah,
        thickness: 0.5,
        space: 0.5,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: RukunText.judul3.copyWith(color: teksPrimer),
        systemOverlayStyle:
            gelap ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Sudut.xl)),
        ),
      ),

      // Transisi halaman bergaya iOS di kedua platform —
      // konsisten dengan bahasa gerak berbasis spring.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),

      extensions: <ThemeExtension<dynamic>>[gradients],
    );
  }
}

/// Akses pintas ke token Rukun dari [BuildContext].
///
/// Pemakaian:
/// ```dart
/// Container(decoration: BoxDecoration(gradient: context.gradients.terang))
/// Text('Halo', style: context.teks.headline)
/// ```
extension RukunContext on BuildContext {
  /// Token gradient. JANGAN pernah tulis nilai hex langsung di widget.
  RukunGradients get gradients => Theme.of(this).extension<RukunGradients>()!;

  ColorScheme get warna => Theme.of(this).colorScheme;

  TextTheme get teks => Theme.of(this).textTheme;

  bool get modeGelap => Theme.of(this).brightness == Brightness.dark;

  /// Warna teks sekunder sesuai mode.
  Color get teksSekunder => modeGelap
      ? RukunColors.teksSekunderGelap
      : RukunColors.teksSekunderTerang;

  /// Warna teks tersier sesuai mode.
  Color get teksTersier =>
      modeGelap ? RukunColors.teksTersierGelap : RukunColors.teksTersierTerang;
}
