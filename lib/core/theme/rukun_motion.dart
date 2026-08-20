import 'package:flutter/material.dart';

/// Token gerak. DESIGN.md §5
///
/// Semua gerakan memakai spring — tidak pernah linear.
abstract final class Gerak {
  /// Standar.
  static const halus = Duration(milliseconds: 350);
  static const halusKurva = Curves.easeOutCubic;

  /// Tombol, toggle, chip.
  static const sigap = Duration(milliseconds: 220);
  static const sigapKurva = Curves.easeOutCubic;

  /// **Kabut terbuka** — animasi tanda tangan aplikasi. DESIGN.md §5.2
  static const singkap = Duration(milliseconds: 600);
  static const singkapKurva = Curves.easeOutCubic;

  /// Perayaan — satu-satunya yang boleh memantul.
  static const rayakan = Duration(milliseconds: 700);
  static const rayakanKurva = Curves.elasticOut;

  /// Denyut posisi pengguna & tombol rekam aktif.
  static const denyut = Duration(seconds: 2);

  /// Denyut petak yang akan hangus.
  static const denyutHangus = Duration(milliseconds: 1500);

  /// Spring standar untuk transisi berbasis fisika.
  static const springHalus = SpringDescription(
    mass: 1,
    stiffness: 180,
    damping: 22,
  );

  static const springSigap = SpringDescription(
    mass: 1,
    stiffness: 320,
    damping: 26,
  );

  /// Hormati preferensi aksesibilitas. DESIGN.md §9
  ///
  /// Saat `reduceMotion` menyala, [singkap] jadi fade sederhana 200ms
  /// dan semua denyut dimatikan.
  static bool kurangiGerak(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ??
      MediaQuery.maybeOf(context)?.disableAnimations ??
      false;

  static Duration singkapEfektif(BuildContext context) =>
      kurangiGerak(context) ? const Duration(milliseconds: 200) : singkap;
}
