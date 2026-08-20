import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/rukun_spacing.dart';
import '../../core/theme/rukun_theme.dart';

/// Material buram (frosted glass). DESIGN.md §4.4
///
/// Sinyal "Apple" paling kuat, sekaligus perwujudan literal dari kabut —
/// metafora inti produk.
///
/// ⚠️ PERFORMA: maksimal 2 lapisan buram terlihat sekaligus. Gunakan
/// [hematPerforma] untuk fallback opaque di perangkat kelas menengah.
class KartuBuram extends StatelessWidget {
  const KartuBuram({
    super.key,
    required this.child,
    this.buram = Buram.sedang,
    this.radius = Sudut.lg,
    this.padding = const EdgeInsets.all(Jarak.kartuNyaman),
    this.hematPerforma = false,
  });

  final Widget child;
  final Buram buram;
  final double radius;
  final EdgeInsets padding;
  final bool hematPerforma;

  @override
  Widget build(BuildContext context) {
    final gelap = context.modeGelap;
    final dasar = gelap ? const Color(0xFF16191F) : Colors.white;
    final opasitas = hematPerforma ? 1.0 : buram.opasitas;

    final isi = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: dasar.withValues(alpha: opasitas),
        borderRadius: BorderRadius.circular(radius),
        // Garis tepi rambut 0.5px — detail kecil yang membuatnya terbaca
        // sebagai kaca, bukan sekadar putih transparan.
        border: Border.all(
          color: gelap
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.50),
          width: 0.5,
        ),
      ),
      child: child,
    );

    if (hematPerforma) return isi;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: buram.blur, sigmaY: buram.blur),
        child: isi,
      ),
    );
  }
}

/// Kartu permukaan standar (tidak buram). DESIGN.md §6.2
class KartuRukun extends StatelessWidget {
  const KartuRukun({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Jarak.kartuNyaman),
    this.radius = Sudut.lg,
    this.elevasi,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final List<BoxShadow>? elevasi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: context.gradients.permukaan,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: elevasi ?? Elevasi.satu,
        border: context.modeGelap
            ? Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5)
            : null,
      ),
      child: child,
    );
  }
}

/// Teks dengan isian gradient. Dipakai untuk angka besar & aksen.
class TeksGradient extends StatelessWidget {
  const TeksGradient(
    this.teks, {
    super.key,
    required this.gradient,
    required this.style,
    this.textAlign,
  });

  final String teks;
  final Gradient gradient;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (r) => gradient.createShader(r),
      blendMode: BlendMode.srcIn,
      child: Text(
        teks,
        textAlign: textAlign,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}
