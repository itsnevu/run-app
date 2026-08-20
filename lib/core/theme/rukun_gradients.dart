import 'package:flutter/material.dart';
import 'rukun_colors.dart';

/// Membuat gradient 135° standar Rukun (kiri-atas → kanan-bawah).
///
/// Satu sumber cahaya untuk seluruh aplikasi. Lihat DESIGN.md §1.2 prinsip 4.
LinearGradient g135(Color a, Color b) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [a, b],
    );

/// Token gradient Rukun, disuntikkan lewat [ThemeExtension].
///
/// [ColorScheme] Flutter hanya menyimpan `Color` datar. Karena SETIAP warna
/// bermakna di Rukun adalah gradient (DESIGN.md §2.1), kita butuh perluasan
/// tema sendiri.
///
/// Pemakaian: `context.gradients.terang`
@immutable
class RukunGradients extends ThemeExtension<RukunGradients> {
  const RukunGradients({
    required this.terang,
    required this.fajar,
    required this.misi,
    required this.kabut,
    required this.tumbuh,
    required this.hangus,
    required this.bahaya,
    required this.netral,
    required this.latar,
    required this.permukaan,
    required this.permukaanTinggi,
  });

  /// Primer — kejernihan, CTA utama, elemen aktif.
  final LinearGradient terang;

  /// Aksen — jejak pribadi, perayaan, kehangatan.
  final LinearGradient fajar;

  /// Penemuan — misi, quest.
  final LinearGradient misi;

  /// Terkunci — petak berkabut, state nonaktif.
  final LinearGradient kabut;

  /// Petak diklaim, target tercapai, tren naik.
  final LinearGradient tumbuh;

  /// Petak akan kedaluwarsa, peringatan lembut.
  final LinearGradient hangus;

  /// Error, aksi destruktif. Jangan pernah untuk performa buruk.
  final LinearGradient bahaya;

  /// Informasi, state kosong.
  final LinearGradient netral;

  /// Latar layar.
  final LinearGradient latar;

  /// Permukaan kartu.
  final LinearGradient permukaan;

  /// Permukaan terangkat (modal, sheet).
  final LinearGradient permukaanTinggi;

  // ── Mode terang ─────────────────────────────────────────────────
  static final terangTheme = RukunGradients(
    terang: g135(RukunColors.terangA, RukunColors.terangB),
    fajar: g135(RukunColors.fajarA, RukunColors.fajarB),
    misi: g135(RukunColors.misiA, RukunColors.misiB),
    kabut: g135(RukunColors.kabutA, RukunColors.kabutB),
    tumbuh: g135(RukunColors.tumbuhA, RukunColors.tumbuhB),
    hangus: g135(RukunColors.hangusA, RukunColors.hangusB),
    bahaya: g135(RukunColors.bahayaA, RukunColors.bahayaB),
    netral: g135(RukunColors.netralA, RukunColors.netralB),
    latar: g135(RukunColors.latarTerangA, RukunColors.latarTerangB),
    permukaan: g135(RukunColors.permukaanTerangA, RukunColors.permukaanTerangB),
    permukaanTinggi: g135(
      RukunColors.permukaanTerangA,
      RukunColors.permukaanTerangA,
    ),
  );

  // ── Mode gelap ──────────────────────────────────────────────────
  // Gradient dinaikkan lightness +6% agar tidak lumpur. DESIGN.md §2.8
  static final gelapTheme = RukunGradients(
    terang: g135(_naik(RukunColors.terangA), _naik(RukunColors.terangB)),
    fajar: g135(_naik(RukunColors.fajarA), _naik(RukunColors.fajarB)),
    misi: g135(_naik(RukunColors.misiA), _naik(RukunColors.misiB)),
    kabut: g135(const Color(0xFF3A4250), const Color(0xFF4A5260)),
    tumbuh: g135(_naik(RukunColors.tumbuhA), _naik(RukunColors.tumbuhB)),
    hangus: g135(_naik(RukunColors.hangusA), _naik(RukunColors.hangusB)),
    bahaya: g135(_naik(RukunColors.bahayaA), _naik(RukunColors.bahayaB)),
    netral: g135(RukunColors.netralA, RukunColors.netralB),
    latar: g135(RukunColors.latarGelapA, RukunColors.latarGelapB),
    permukaan: g135(RukunColors.permukaanGelapA, RukunColors.permukaanGelapB),
    permukaanTinggi: g135(
      RukunColors.permukaanTinggiGelapA,
      RukunColors.permukaanTinggiGelapB,
    ),
  );

  /// Menaikkan lightness sebesar [jumlah] untuk mode gelap.
  static Color _naik(Color c, [double jumlah = 0.06]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + jumlah).clamp(0.0, 1.0)).toColor();
  }

  @override
  RukunGradients copyWith({
    LinearGradient? terang,
    LinearGradient? fajar,
    LinearGradient? misi,
    LinearGradient? kabut,
    LinearGradient? tumbuh,
    LinearGradient? hangus,
    LinearGradient? bahaya,
    LinearGradient? netral,
    LinearGradient? latar,
    LinearGradient? permukaan,
    LinearGradient? permukaanTinggi,
  }) {
    return RukunGradients(
      terang: terang ?? this.terang,
      fajar: fajar ?? this.fajar,
      misi: misi ?? this.misi,
      kabut: kabut ?? this.kabut,
      tumbuh: tumbuh ?? this.tumbuh,
      hangus: hangus ?? this.hangus,
      bahaya: bahaya ?? this.bahaya,
      netral: netral ?? this.netral,
      latar: latar ?? this.latar,
      permukaan: permukaan ?? this.permukaan,
      permukaanTinggi: permukaanTinggi ?? this.permukaanTinggi,
    );
  }

  @override
  RukunGradients lerp(ThemeExtension<RukunGradients>? other, double t) {
    if (other is! RukunGradients) return this;
    return RukunGradients(
      terang: LinearGradient.lerp(terang, other.terang, t)!,
      fajar: LinearGradient.lerp(fajar, other.fajar, t)!,
      misi: LinearGradient.lerp(misi, other.misi, t)!,
      kabut: LinearGradient.lerp(kabut, other.kabut, t)!,
      tumbuh: LinearGradient.lerp(tumbuh, other.tumbuh, t)!,
      hangus: LinearGradient.lerp(hangus, other.hangus, t)!,
      bahaya: LinearGradient.lerp(bahaya, other.bahaya, t)!,
      netral: LinearGradient.lerp(netral, other.netral, t)!,
      latar: LinearGradient.lerp(latar, other.latar, t)!,
      permukaan: LinearGradient.lerp(permukaan, other.permukaan, t)!,
      permukaanTinggi:
          LinearGradient.lerp(permukaanTinggi, other.permukaanTinggi, t)!,
    );
  }
}
