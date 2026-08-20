import 'dart:math' as math;

/// Satu sampel akselerometer.
class SampelGerak {
  const SampelGerak(this.x, this.y, this.z, this.waktu);

  final double x;
  final double y;
  final double z;
  final DateTime waktu;

  /// Besar percepatan total, m/detik².
  double get besar => math.sqrt(x * x + y * y + z * z);
}

/// Menghitung irama langkah dari akselerometer.
///
/// **Kenapa ini perlu.** GPS saja tidak bisa membedakan bersepeda dari lari:
/// rentang kecepatannya bertumpuk di 4–8 m/detik. Tanpa ini, orang bisa
/// bersepeda keliling kota dan mengklaim petak seperti pejalan kaki — dan
/// seluruh gagasan "jumlah orang yang bergerak" jadi kehilangan makna.
///
/// **Cara kerjanya.** Jalan dan lari menghasilkan hentakan berulang saat kaki
/// menyentuh tanah. Bersepeda tidak: sepeda menggelinding, dan getarannya
/// tidak berpola seirama langkah. Jadi yang dicari adalah puncak percepatan
/// yang berulang teratur.
abstract final class IramaLangkah {
  /// Ambang puncak di atas gravitasi, m/detik².
  ///
  /// Jalan santai menghasilkan puncak ~1,5–3; lari jauh lebih besar.
  /// Getaran sepeda di jalan aspal umumnya di bawah ini.
  static const ambangPuncak = 1.6;

  /// Jarak minimum antar langkah. 250 ms ≈ 240 langkah/menit — di atas
  /// kemampuan manusia, jadi apa pun yang lebih rapat pasti derau.
  static const jedaMinimum = Duration(milliseconds: 250);

  /// Batas bawah irama yang dianggap langkah manusia.
  ///
  /// Jalan santai sekitar 100–120 langkah/menit. Di bawah 70 berarti tidak
  /// ada pola langkah sama sekali.
  static const iramaMinimum = 70.0;

  /// Menghitung langkah per menit dari serangkaian sampel.
  ///
  /// Mengembalikan 0 bila tidak ada pola langkah yang bisa dikenali.
  static double langkahPerMenit(List<SampelGerak> sampel) {
    if (sampel.length < 4) return 0;

    final rentang = sampel.last.waktu.difference(sampel.first.waktu);
    if (rentang.inMilliseconds <= 0) return 0;

    // Garis dasar = rata-rata besar percepatan. Ini otomatis membuang
    // gravitasi tanpa perlu tahu orientasi perangkat.
    final rata = sampel.fold<double>(0, (j, s) => j + s.besar) / sampel.length;

    var langkah = 0;
    DateTime? terakhir;

    for (var i = 1; i < sampel.length - 1; i++) {
      final b = sampel[i].besar;
      // Puncak lokal yang cukup jauh di atas garis dasar.
      final puncak = b > sampel[i - 1].besar &&
          b >= sampel[i + 1].besar &&
          (b - rata) > ambangPuncak;
      if (!puncak) continue;

      final w = sampel[i].waktu;
      if (terakhir != null && w.difference(terakhir) < jedaMinimum) continue;

      langkah++;
      terakhir = w;
    }

    final menit = rentang.inMilliseconds / 60000;
    return menit <= 0 ? 0 : langkah / menit;
  }

  /// Apakah pola percepatan ini berasal dari langkah kaki.
  static bool adaLangkah(List<SampelGerak> sampel) =>
      langkahPerMenit(sampel) >= iramaMinimum;
}
