import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rukun/domain/aturan/irama_langkah.dart';
import 'package:rukun/domain/aturan/moda_gerak.dart';

void main() {
  final t0 = DateTime(2026, 8, 21, 6);

  /// Membuat sampel akselerometer selama [detik] dengan hentakan berulang
  /// pada [langkahPerMenit]. [amplitudo] mengatur seberapa keras hentakannya.
  List<SampelGerak> pola({
    required double langkahPerMenit,
    required int detik,
    double amplitudo = 3.0,
    double derau = 0.15,
    int hz = 50,
  }) {
    final acak = math.Random(42);
    final total = detik * hz;
    final periode = langkahPerMenit <= 0 ? 0.0 : 60 / langkahPerMenit;

    return [
      for (var i = 0; i < total; i++)
        () {
          final d = i / hz;
          // Gravitasi + hentakan berkala + sedikit derau.
          final hentak = periode <= 0
              ? 0.0
              : amplitudo * math.pow(math.sin(math.pi * d / periode), 8);
          final n = (acak.nextDouble() - 0.5) * derau;
          return SampelGerak(
            0, 0, 9.81 + hentak + n,
            t0.add(Duration(milliseconds: (d * 1000).round())),
          );
        }(),
    ];
  }

  group('Deteksi irama langkah', () {
    test('jalan santai terdeteksi ~110 langkah/menit', () {
      final irama =
          IramaLangkah.langkahPerMenit(pola(langkahPerMenit: 110, detik: 10));
      expect(irama, closeTo(110, 15));
      expect(IramaLangkah.adaLangkah(pola(langkahPerMenit: 110, detik: 10)),
          isTrue);
    });

    test('lari terdeteksi ~170 langkah/menit', () {
      final irama = IramaLangkah.langkahPerMenit(
          pola(langkahPerMenit: 170, detik: 10, amplitudo: 6));
      expect(irama, closeTo(170, 25));
    });

    test('⭐ bersepeda: getaran kecil tanpa pola langkah → tidak terdeteksi',
        () {
      // Sepeda menggelinding: getaran ada, tapi jauh di bawah ambang hentakan
      // kaki dan tidak berpola seirama langkah.
      final sepeda = pola(
        langkahPerMenit: 0,
        detik: 10,
        amplitudo: 0,
        derau: 0.8,
      );
      expect(IramaLangkah.adaLangkah(sepeda), isFalse);
    });

    test('perangkat diam tidak menghasilkan langkah', () {
      final diam =
          pola(langkahPerMenit: 0, detik: 10, amplitudo: 0, derau: 0.02);
      expect(IramaLangkah.langkahPerMenit(diam), 0);
    });

    test('sampel terlalu sedikit aman', () {
      expect(IramaLangkah.langkahPerMenit(const []), 0);
      expect(
        IramaLangkah.langkahPerMenit([SampelGerak(0, 0, 9.8, t0)]),
        0,
      );
    });
  });

  group('⭐ ModaGerak memakai irama untuk memisahkan sepeda dari lari', () {
    test('5 m/detik DENGAN langkah → lari', () {
      expect(ModaGerak.dari(5.0, adaLangkah: true), ModaGerak.lari);
    });

    test('5 m/detik TANPA langkah → kendaraan (sepeda)', () {
      // Inti perbaikannya: sebelum ini, bersepeda santai lolos sebagai lari.
      expect(ModaGerak.dari(5.0, adaLangkah: false), ModaGerak.kendaraan);
    });

    test('6,5 m/detik tanpa langkah → kendaraan', () {
      expect(ModaGerak.dari(6.5, adaLangkah: false), ModaGerak.kendaraan);
    });

    test('jalan santai tidak terpengaruh sensor', () {
      // Di bawah zona ambigu, kecepatan sudah cukup menentukan.
      expect(ModaGerak.dari(1.4, adaLangkah: false), ModaGerak.jalan);
      expect(ModaGerak.dari(1.4, adaLangkah: true), ModaGerak.jalan);
    });

    test('tanpa sensor, hasilnya kembali ke kecepatan saja', () {
      // Lebih baik memberi keuntungan pada pengguna daripada menuduh salah
      // orang yang benar-benar berlari.
      expect(ModaGerak.dari(5.0), ModaGerak.lari);
      expect(ModaGerak.dari(11.0), ModaGerak.kendaraan);
    });

    test('kecepatan mobil tetap kendaraan meski sensor bergetar', () {
      expect(ModaGerak.dari(15.0, adaLangkah: true), ModaGerak.lari,
          reason: 'ada pola langkah nyata pada 15 m/detik praktis mustahil, '
              'tapi aturannya tetap konsisten dan bisa diprediksi');
      expect(ModaGerak.dari(15.0, adaLangkah: false), ModaGerak.kendaraan);
    });
  });
}
