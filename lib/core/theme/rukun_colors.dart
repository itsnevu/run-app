import 'package:flutter/material.dart';

/// Nilai warna mentah untuk Rukun.
///
/// JANGAN pakai kelas ini langsung di dalam widget. Akses warna lewat
/// `context.gradients` (lihat [RukunGradients]) atau `Theme.of(context)`.
/// Kelas ini hanya sumber kebenaran untuk berkas tema.
///
/// Referensi: DESIGN.md §2
abstract final class RukunColors {
  // ── Gradient brand ──────────────────────────────────────────────
  /// Primer. Kabut tersingkap, kejernihan.
  static const terangA = Color(0xFF2F7BFF);
  static const terangB = Color(0xFF58C6FF);

  /// Aksen & perayaan. Jejak pribadi, kehangatan.
  static const fajarA = Color(0xFFFF6B35);
  static const fajarB = Color(0xFFFFA552);

  /// Penemuan. Pin misi, quest.
  static const misiA = Color(0xFF7B61FF);
  static const misiB = Color(0xFFA78BFA);

  /// Terkunci / belum terbuka.
  static const kabutA = Color(0xFFA8B3C5);
  static const kabutB = Color(0xFFC9D2E0);

  // ── Gradient semantik ───────────────────────────────────────────
  static const tumbuhA = Color(0xFF1FB870);
  static const tumbuhB = Color(0xFF4BDD95);

  static const hangusA = Color(0xFFFF9500);
  static const hangusB = Color(0xFFFFC53D);

  static const bahayaA = Color(0xFFFF3B30);
  static const bahayaB = Color(0xFFFF7A70);

  static const netralA = Color(0xFF8B94A3);
  static const netralB = Color(0xFFA9B2BF);

  // ── Permukaan terang ────────────────────────────────────────────
  static const latarTerangA = Color(0xFFF5F7FA);
  static const latarTerangB = Color(0xFFEEF1F6);
  static const permukaanTerangA = Color(0xFFFFFFFF);
  static const permukaanTerangB = Color(0xFFFAFBFD);

  // ── Permukaan gelap ─────────────────────────────────────────────
  static const latarGelapA = Color(0xFF0A0C10);
  static const latarGelapB = Color(0xFF0E1116);
  static const permukaanGelapA = Color(0xFF16191F);
  static const permukaanGelapB = Color(0xFF1C2029);
  static const permukaanTinggiGelapA = Color(0xFF1C2029);
  static const permukaanTinggiGelapB = Color(0xFF232833);

  // ── Teks (warna datar — satu-satunya pengecualian, DESIGN.md §2.7)
  static const teksPrimerTerang = Color(0xFF0B0D12);
  static const teksSekunderTerang = Color(0xFF5B6472);
  static const teksTersierTerang = Color(0xFF8B94A3);
  static const teksKuarterTerang = Color(0xFFB4BCC8);

  static const teksPrimerGelap = Color(0xFFFFFFFF);
  static const teksSekunderGelap = Color(0xFFA3ACBA);
  static const teksTersierGelap = Color(0xFF6E7784);
  static const teksKuarterGelap = Color(0xFF4A525E);

  // ── Peta ────────────────────────────────────────────────────────
  static const jalanTerang = Color(0xFFE8EBF0);
  static const jalanGelap = Color(0xFF1C2029);

  // ── Garis pemisah ───────────────────────────────────────────────
  static const pemisahTerang = Color(0x0F0B0D12);
  static const pemisahGelap = Color(0x14FFFFFF);
}

/// Delapan gradient tim kelurahan.
///
/// Dipilih agar tetap bisa dibedakan saat berdampingan di peta, termasuk
/// pada deuteranopia & protanopia. Lihat DESIGN.md §2.5.
///
/// ATURAN: warna tim tidak pernah jadi satu-satunya pembeda —
/// selalu pasangkan dengan pola isian atau label.
enum TimWarna {
  biru('Biru', Color(0xFF2F7BFF), Color(0xFF58C6FF)),
  merah('Merah', Color(0xFFFF3B5C), Color(0xFFFF7A8A)),
  hijau('Hijau', Color(0xFF1FB870), Color(0xFF4BDD95)),
  ungu('Ungu', Color(0xFF7B61FF), Color(0xFFA78BFA)),
  oranye('Oranye', Color(0xFFFF6B35), Color(0xFFFFA552)),
  toska('Toska', Color(0xFF0FC7B7), Color(0xFF4FE0D4)),
  pink('Pink', Color(0xFFFF4FA3), Color(0xFFFF8CC4)),
  kuning('Kuning', Color(0xFFFFB800), Color(0xFFFFD75E));

  const TimWarna(this.label, this.a, this.b);

  final String label;
  final Color a;
  final Color b;

  /// Gradient 135° standar untuk tim ini.
  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [a, b],
      );

  /// Isian poligon wilayah di peta — 28% (DESIGN.md §2.5).
  LinearGradient get isianPeta => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [a.withValues(alpha: 0.28), b.withValues(alpha: 0.28)],
      );

  /// Garis tepi poligon wilayah — 90%, tebal 2px.
  Color get tepiPeta => a.withValues(alpha: 0.90);

  /// Apakah teks putih aman di atas gradient ini?
  /// Kuning gagal kontras 4.5:1 — pakai teks gelap. (DESIGN.md §2.7)
  bool get teksPutihAman => this != TimWarna.kuning;
}
