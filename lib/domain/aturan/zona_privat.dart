import '../grid/grid_petak.dart';
import '../model/koordinat.dart';

/// Wilayah yang tidak pernah dibagikan ke publik — biasanya rumah,
/// kantor, atau sekolah anak.
///
/// DESIGN.md §9 menyebut ini **wajib ada di hari pertama, bukan nanti**.
/// Aplikasi yang memetakan pergerakan harian orang tanpa ini membocorkan
/// alamat rumah penggunanya.
class ZonaPrivat {
  const ZonaPrivat({
    required this.pusat,
    this.radiusMeter = Privasi.radiusBakuMeter,
    this.label,
  });

  final Koordinat pusat;
  final double radiusMeter;
  final String? label;

  bool menutupi(Koordinat k) => pusat.jarakKe(k) <= radiusMeter;
}

abstract final class Privasi {
  /// Radius baku. Cukup besar untuk mengaburkan rumah tepat mana di satu
  /// blok, cukup kecil untuk tidak melubangi peta.
  static const radiusBakuMeter = 150.0;

  /// Membuang petak yang jatuh di dalam zona privat mana pun.
  ///
  /// Dipakai sebelum lintasan dikirim ke server: petak yang disaring di sini
  /// tidak pernah menjadi klaim, tidak pernah muncul di peta tim, dan tidak
  /// pernah meninggalkan perangkat.
  static Set<IdPetak> saring(
    Set<IdPetak> petak,
    List<ZonaPrivat> zona,
    GridPetak grid,
  ) {
    if (zona.isEmpty) return petak;
    return petak.where((p) {
      final tengah = grid.pusat(p);
      return !zona.any((z) => z.menutupi(tengah));
    }).toSet();
  }

  /// Apakah sebuah titik berada di zona privat.
  static bool tertutup(Koordinat k, List<ZonaPrivat> zona) =>
      zona.any((z) => z.menutupi(k));
}
