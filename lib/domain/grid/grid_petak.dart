import '../model/koordinat.dart';

/// Identitas satu petak pada grid.
///
/// Disimpan sebagai koordinat aksial heksagon (q, r) supaya operasi tetangga
/// dan jarak petak murah, dan supaya kode petak stabil lintas perangkat.
class IdPetak {
  const IdPetak(this.q, this.r);

  final int q;
  final int r;

  /// Kode stabil untuk penyimpanan & sinkronisasi ke server.
  String get kode => 'p.$q.$r';

  static IdPetak dariKode(String kode) {
    final bagian = kode.split('.');
    if (bagian.length != 3 || bagian.first != 'p') {
      throw FormatException('Kode petak tidak sah: $kode');
    }
    return IdPetak(int.parse(bagian[1]), int.parse(bagian[2]));
  }

  @override
  bool operator ==(Object other) =>
      other is IdPetak && other.q == q && other.r == r;

  @override
  int get hashCode => Object.hash(q, r);

  @override
  String toString() => kode;
}

/// Sistem petak: memetakan koordinat bumi ke sel diskrit.
///
/// Antarmuka ini sengaja dipisah supaya implementasinya bisa ditukar.
/// Saat ini dipakai [GridHeks] (pure Dart, bisa diuji tanpa toolchain native).
/// H3 milik Uber bisa menggantikannya nanti lewat `h3_flutter` di perangkat —
/// paket itu butuh FFI + library native sehingga tidak bisa dijalankan di
/// `flutter test`.
abstract interface class GridPetak {
  /// Petak yang memuat [k].
  IdPetak petakDi(Koordinat k);

  /// Titik tengah petak.
  Koordinat pusat(IdPetak id);

  /// Enam sudut poligon petak, untuk digambar di peta.
  List<Koordinat> batas(IdPetak id);

  /// Petak-petak dalam radius [langkah] dari [id] (termasuk [id] sendiri).
  List<IdPetak> cincin(IdPetak id, int langkah);

  /// Semua petak yang dilalui sebuah jalur.
  ///
  /// Jalur diinterpolasi rapat supaya petak sempit di antara dua titik GPS
  /// tidak terlewat.
  Set<IdPetak> petakSepanjang(List<Koordinat> jalur);

  /// Perkiraan lebar petak dari sisi ke sisi, meter.
  double get lebarMeter;
}
