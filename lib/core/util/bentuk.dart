import 'package:flutter/material.dart';
import 'package:smooth_corner/smooth_corner.dart';

/// Bentuk permukaan Rukun — kurva kontinu (squircle). DESIGN.md §4.2
///
/// Apple memakai kurva kontinu, bukan busur lingkaran. Perbedaannya halus tapi
/// sangat terasa — sudut lingkaran biasa terlihat "murah" bersebelahan dengan
/// komponen iOS asli.
///
/// `smoothness: 0.6` adalah nilai yang cocok dengan lengkung iOS.
///
/// CAKUPAN: dipakai untuk **permukaan** (kartu, sheet, petak warna, modal).
/// Elemen pil dan lingkaran (tombol, chip, avatar) tetap memakai radius
/// lingkaran penuh — sebuah pil memang stadium, bukan squircle.
abstract final class Bentuk {
  /// Tingkat kelengkungan kontinu khas iOS.
  static const kehalusan = 0.6;

  /// Bentuk permukaan dengan sudut kontinu.
  static SmoothRectangleBorder permukaan(double radius, {BorderSide? sisi}) =>
      SmoothRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        smoothness: kehalusan,
        side: sisi ?? BorderSide.none,
      );

  /// Dekorasi permukaan lengkap: gradient + bayangan + sudut kontinu.
  ///
  /// Memakai [ShapeDecoration] karena [BoxDecoration] tidak bisa menerima
  /// [ShapeBorder] sembarang — ia hanya mengenal [BorderRadius].
  static ShapeDecoration dekorasi({
    required double radius,
    Gradient? gradient,
    Color? warna,
    List<BoxShadow>? bayangan,
    BorderSide? sisi,
  }) =>
      ShapeDecoration(
        gradient: gradient,
        color: warna,
        shadows: bayangan,
        shape: permukaan(radius, sisi: sisi),
      );
}
