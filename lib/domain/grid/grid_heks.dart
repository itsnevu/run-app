import 'dart:math' as math;

import '../model/koordinat.dart';
import 'grid_petak.dart';

/// Grid heksagon pure-Dart. DESIGN.md §10.3
///
/// **Kenapa heksagon, bukan kotak:** semua tetangga berjarak sama, tidak ada
/// kebingungan diagonal, dan bentuknya lebih organik di peta.
///
/// **Ukuran.** [ukuranMeter] adalah jari-jari lingkar luar (pusat ke sudut).
/// Nilai baku 76 m menghasilkan petak selebar ~132 m dengan luas ~15.000 m²,
/// setara H3 resolusi 10. Jalan kaki 5 menit (~400 m) melintasi ~3 petak —
/// memberi pemula rasa pencapaian yang cepat dan berulang tanpa membuat
/// klaim jadi murah.
///
/// **Proyeksi.** Memakai Web Mercator. Mercator meregang seiring lintang,
/// jadi satu meter Mercator = cos(lintang) meter di tanah. Untuk Indonesia
/// (lintang -11° s.d. 6°) simpangannya di bawah 2%, sehingga petak tetap
/// terasa seukuran di seluruh negeri. Jarak nyata tetap dihitung dengan
/// haversine, bukan pada bidang proyeksi.
class GridHeks implements GridPetak {
  const GridHeks({this.ukuranMeter = 76.0});

  final double ukuranMeter;

  static const _r = Koordinat.jariBumiMeter;
  static final _akar3 = math.sqrt(3);

  @override
  double get lebarMeter => _akar3 * ukuranMeter;

  // ── Proyeksi ────────────────────────────────────────────────────
  static (double, double) _keMercator(Koordinat k) {
    final lat = k.lat.clamp(-85.05112878, 85.05112878);
    final x = _r * k.lng * math.pi / 180;
    final y = _r * math.log(math.tan(math.pi / 4 + lat * math.pi / 360));
    return (x, y);
  }

  static Koordinat _dariMercator(double x, double y) {
    final lng = x / _r * 180 / math.pi;
    final lat = (2 * math.atan(math.exp(y / _r)) - math.pi / 2) * 180 / math.pi;
    return Koordinat(lat, lng);
  }

  // ── Heksagon pointy-top, koordinat aksial ───────────────────────
  @override
  IdPetak petakDi(Koordinat k) {
    final (x, y) = _keMercator(k);
    final q = (_akar3 / 3 * x - 1 / 3 * y) / ukuranMeter;
    final r = (2 / 3 * y) / ukuranMeter;
    return _bulatkan(q, r);
  }

  @override
  Koordinat pusat(IdPetak id) {
    final x = ukuranMeter * _akar3 * (id.q + id.r / 2);
    final y = ukuranMeter * 3 / 2 * id.r;
    return _dariMercator(x, y);
  }

  @override
  List<Koordinat> batas(IdPetak id) {
    final x = ukuranMeter * _akar3 * (id.q + id.r / 2);
    final y = ukuranMeter * 3 / 2 * id.r;
    return [
      for (var i = 0; i < 6; i++)
        () {
          // Pointy-top: sudut pada 60°·i − 30°.
          final sudut = math.pi / 180 * (60 * i - 30);
          return _dariMercator(
            x + ukuranMeter * math.cos(sudut),
            y + ukuranMeter * math.sin(sudut),
          );
        }(),
    ];
  }

  /// Enam arah tetangga dalam koordinat aksial.
  static const _arah = [
    (1, 0), (1, -1), (0, -1),
    (-1, 0), (-1, 1), (0, 1),
  ];

  @override
  List<IdPetak> cincin(IdPetak id, int langkah) {
    if (langkah <= 0) return [id];
    final hasil = <IdPetak>[];
    for (var dq = -langkah; dq <= langkah; dq++) {
      final bawah = math.max(-langkah, -dq - langkah);
      final atas = math.min(langkah, -dq + langkah);
      for (var dr = bawah; dr <= atas; dr++) {
        hasil.add(IdPetak(id.q + dq, id.r + dr));
      }
    }
    return hasil;
  }

  /// Tetangga langsung sebuah petak.
  List<IdPetak> tetangga(IdPetak id) =>
      [for (final (dq, dr) in _arah) IdPetak(id.q + dq, id.r + dr)];

  @override
  Set<IdPetak> petakSepanjang(List<Koordinat> jalur) {
    final hasil = <IdPetak>{};
    if (jalur.isEmpty) return hasil;
    if (jalur.length == 1) return {petakDi(jalur.first)};

    // Interpolasi dengan langkah setengah lebar petak supaya tidak ada petak
    // sempit yang terlompati di antara dua titik GPS yang berjauhan.
    final langkahMaks = lebarMeter / 2;

    for (var i = 0; i < jalur.length - 1; i++) {
      final a = jalur[i];
      final b = jalur[i + 1];
      hasil.add(petakDi(a));

      final jarak = a.jarakKe(b);
      final bagian = (jarak / langkahMaks).ceil();
      for (var s = 1; s < bagian; s++) {
        final t = s / bagian;
        hasil.add(petakDi(Koordinat(
          a.lat + (b.lat - a.lat) * t,
          a.lng + (b.lng - a.lng) * t,
        )));
      }
    }
    hasil.add(petakDi(jalur.last));
    return hasil;
  }

  /// Pembulatan kubik — mengubah koordinat aksial pecahan ke petak terdekat.
  static IdPetak _bulatkan(double q, double r) {
    final x = q;
    final z = r;
    final y = -x - z;

    var rx = x.roundToDouble();
    var ry = y.roundToDouble();
    var rz = z.roundToDouble();

    final dx = (rx - x).abs();
    final dy = (ry - y).abs();
    final dz = (rz - z).abs();

    // Komponen dengan simpangan terbesar dihitung ulang agar x+y+z tetap 0.
    if (dx > dy && dx > dz) {
      rx = -ry - rz;
    } else if (dy > dz) {
      ry = -rx - rz;
    } else {
      rz = -rx - ry;
    }

    return IdPetak(rx.toInt(), rz.toInt());
  }
}
