import 'package:flutter/material.dart';

/// Grid 4pt. DESIGN.md §4.1
abstract final class Jarak {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 40.0;
  static const giant = 48.0;
  static const massive = 64.0;

  /// Padding tepi layar.
  static const tepiLayar = 20.0;

  /// Padding dalam kartu.
  static const kartuPadat = 16.0;
  static const kartuNyaman = 20.0;

  /// Jarak antar kartu.
  static const antarKartu = 12.0;

  /// Jarak antar bagian.
  static const antarBagian = 32.0;
}

/// Radius sudut. DESIGN.md §4.2
///
/// CATATAN: Apple memakai kurva kontinu (squircle), bukan busur lingkaran.
/// Untuk permukaan besar gunakan paket `smooth_corner` dengan nilai di bawah,
/// bukan [BorderRadius] bawaan Flutter.
abstract final class Sudut {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const xxl = 36.0;
  static const penuh = 999.0;
}

/// Elevasi. DESIGN.md §4.3
///
/// Apple menghindari bayangan berat — kedalaman datang dari material
/// dan lapisan. Pendar berwarna adalah satu-satunya bayangan mencolok
/// yang diizinkan, khusus CTA primer.
abstract final class Elevasi {
  static const List<BoxShadow> nol = [];

  /// Kartu diam.
  static const List<BoxShadow> satu = [
    BoxShadow(
      color: Color(0x0A0B0D12),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// Mengambang di atas peta.
  static const List<BoxShadow> dua = [
    BoxShadow(
      color: Color(0x0F0B0D12),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Modal, bottom sheet.
  static const List<BoxShadow> tiga = [
    BoxShadow(
      color: Color(0x1A0B0D12),
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];

  /// Pendar berwarna untuk tombol gradient primer.
  /// Membuat tombol terasa memancarkan cahaya — sesuai tema Kabut & Cahaya.
  static List<BoxShadow> pendar(Color warna) => [
        BoxShadow(
          color: warna.withValues(alpha: 0.30),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}

/// Material buram (frosted glass). DESIGN.md §4.4
///
/// Sinyal "Apple" paling kuat, sekaligus perwujudan literal dari kabut.
///
/// ⚠️ PERFORMA: [BackdropFilter] mahal di Android kelas menengah —
/// mayoritas pasar Indonesia. Maksimal 2 lapisan buram terlihat sekaligus.
enum Buram {
  tipis(20.0, 0.60),
  sedang(30.0, 0.72),
  tebal(40.0, 0.85);

  const Buram(this.blur, this.opasitas);

  final double blur;
  final double opasitas;
}
