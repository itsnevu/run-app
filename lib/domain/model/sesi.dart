import '../aturan/moda_gerak.dart';
import '../grid/grid_petak.dart';
import 'koordinat.dart';

/// Satu sampel GPS.
class TitikJejak {
  const TitikJejak(this.koordinat, this.waktu, {this.adaLangkah});

  final Koordinat koordinat;
  final DateTime waktu;

  /// Apakah pola langkah kaki terdeteksi saat sampel ini diambil.
  ///
  /// Null berarti **tidak tahu** — sensor tidak tersedia atau datanya belum
  /// cukup. Itu berbeda dari `false`, yang berarti sensor yakin tidak ada
  /// langkah. Perbedaan ini penting: hanya `false` yang boleh membatalkan
  /// kontribusi seseorang.
  final bool? adaLangkah;
}

/// Ruas antara dua sampel GPS berurutan.
class Segmen {
  const Segmen({
    required this.dari,
    required this.ke,
    required this.jarakMeter,
    required this.durasi,
  });

  final TitikJejak dari;
  final TitikJejak ke;
  final double jarakMeter;
  final Duration durasi;

  double get meterPerDetik {
    final detik = durasi.inMicroseconds / Duration.microsecondsPerSecond;
    return detik <= 0 ? 0 : jarakMeter / detik;
  }

  /// Moda ruas ini.
  ///
  /// Irama langkah diambil dari titik tujuan — itulah yang menggambarkan
  /// gerakan sepanjang ruas, bukan titik asal yang sudah lewat.
  ModaGerak get moda =>
      ModaGerak.dari(meterPerDetik, adaLangkah: ke.adaLangkah);

  bool get dihitung => moda.dihitung;
}

/// Satu sesi bergerak — jalan atau lari.
class Sesi {
  Sesi({
    required this.id,
    required this.mulai,
    this.selesai,
    List<TitikJejak>? titik,
  }) : titik = titik ?? <TitikJejak>[];

  final String id;
  final DateTime mulai;
  final DateTime? selesai;
  final List<TitikJejak> titik;

  bool get berjalan => selesai == null;

  Duration get durasi =>
      (selesai ?? (titik.isNotEmpty ? titik.last.waktu : mulai))
          .difference(mulai);

  /// Ruas-ruas antar sampel.
  List<Segmen> get segmen {
    final hasil = <Segmen>[];
    for (var i = 0; i < titik.length - 1; i++) {
      final a = titik[i];
      final b = titik[i + 1];
      hasil.add(Segmen(
        dari: a,
        ke: b,
        jarakMeter: a.koordinat.jarakKe(b.koordinat),
        durasi: b.waktu.difference(a.waktu),
      ));
    }
    return hasil;
  }

  /// **Mata uang 1 — Cakupan Jejak.** Dari jarak tempuh.
  ///
  /// Pelari unggul di sini, dan itu memang tidak apa-apa: lapisan Jejak
  /// bersifat pribadi dan tidak pernah bisa direbut siapa pun.
  double get jarakMeter => segmen
      .where((s) => s.dihitung)
      .fold(0.0, (jumlah, s) => jumlah + s.jarakMeter);

  /// **Mata uang 2 — Poin Klaim.** Dari menit bergerak.
  ///
  /// Setara antara jalan dan lari: 30 menit jalan = 30 menit lari.
  /// Inilah yang membuat pejalan kaki tetap jadi pahlawan tim.
  Duration get waktuBergerak => segmen
      .where((s) => s.dihitung)
      .fold(Duration.zero, (jumlah, s) => jumlah + s.durasi);

  int get menitBergerak => waktuBergerak.inMinutes;

  /// Petak yang dilewati — hanya dari ruas yang dihitung.
  ///
  /// Ruas naik kendaraan dibuang di sini, sehingga melintas naik motor tidak
  /// pernah menghasilkan petak.
  Set<IdPetak> petakDilewati(GridPetak grid) {
    final hasil = <IdPetak>{};
    for (final s in segmen.where((s) => s.dihitung)) {
      hasil.addAll(grid.petakSepanjang([s.dari.koordinat, s.ke.koordinat]));
    }
    return hasil;
  }

  /// Moda yang paling banyak memakan waktu — untuk label ringkasan.
  ModaGerak get modaDominan {
    final total = <ModaGerak, Duration>{};
    for (final s in segmen) {
      total[s.moda] = (total[s.moda] ?? Duration.zero) + s.durasi;
    }
    final dihitung = total.entries.where((e) => e.key.dihitung).toList();
    if (dihitung.isEmpty) return ModaGerak.diam;
    dihitung.sort((a, b) => b.value.compareTo(a.value));
    return dihitung.first.key;
  }

  Sesi salin({DateTime? selesai, List<TitikJejak>? titik}) => Sesi(
        id: id,
        mulai: mulai,
        selesai: selesai ?? this.selesai,
        titik: titik ?? this.titik,
      );
}
