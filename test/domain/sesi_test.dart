import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rukun/domain/aturan/moda_gerak.dart';
import 'package:rukun/domain/aturan/zona_privat.dart';
import 'package:rukun/domain/grid/grid_heks.dart';
import 'package:rukun/domain/model/koordinat.dart';
import 'package:rukun/domain/model/sesi.dart';

void main() {
  final mulai = DateTime(2026, 8, 21, 6, 0);
  const tebet = Koordinat(-6.2264, 106.8556);
  const grid = GridHeks();

  /// Membangun sesi bergerak lurus ke timur dengan [kecepatan] m/detik
  /// selama [menit] menit, disampel tiap [detikSampel] detik.
  Sesi sesiKecepatan({
    required double kecepatan,
    required int menit,
    int detikSampel = 10,
    Koordinat awal = tebet,
    DateTime? waktuMulai,
  }) {
    final t0 = waktuMulai ?? mulai;
    final meterPerDerajat = 111320 * math.cos(awal.lat * math.pi / 180);
    final jumlahSampel = (menit * 60 / detikSampel).round();

    return Sesi(
      id: 's',
      mulai: t0,
      selesai: t0.add(Duration(minutes: menit)),
      titik: [
        for (var i = 0; i <= jumlahSampel; i++)
          TitikJejak(
            Koordinat(
              awal.lat,
              awal.lng + (kecepatan * i * detikSampel) / meterPerDerajat,
            ),
            t0.add(Duration(seconds: i * detikSampel)),
          ),
      ],
    );
  }

  group('Klasifikasi moda gerak', () {
    test('ambang sesuai kecepatan manusia', () {
      expect(ModaGerak.dariKecepatan(0.2), ModaGerak.diam);
      expect(ModaGerak.dariKecepatan(1.4), ModaGerak.jalan); // ~5 km/jam
      expect(ModaGerak.dariKecepatan(3.0), ModaGerak.lari); // ~11 km/jam
      expect(ModaGerak.dariKecepatan(12.0), ModaGerak.kendaraan); // ~43 km/jam
    });

    test('hanya jalan & lari yang dihitung', () {
      expect(ModaGerak.jalan.dihitung, isTrue);
      expect(ModaGerak.lari.dihitung, isTrue);
      expect(ModaGerak.diam.dihitung, isFalse);
      expect(ModaGerak.kendaraan.dihitung, isFalse);
    });
  });

  group('⭐ Dua mata uang: jalan dan lari harus adil', () {
    test('30 menit jalan = 30 menit lari dalam Poin Klaim', () {
      // Inti janji keadilan produk. Kalau ini gagal, pejalan kaki jadi
      // warga kelas dua dan pemula berhenti di minggu kedua.
      final jalan = sesiKecepatan(kecepatan: 1.4, menit: 30);
      final lari = sesiKecepatan(kecepatan: 3.5, menit: 30);

      expect(jalan.menitBergerak, 30);
      expect(lari.menitBergerak, 30);
      expect(jalan.menitBergerak, lari.menitBergerak);
    });

    test('pelari menempuh jarak lebih jauh dalam Cakupan Jejak', () {
      // Dan ini tidak apa-apa: lapisan Jejak bersifat pribadi.
      final jalan = sesiKecepatan(kecepatan: 1.4, menit: 30);
      final lari = sesiKecepatan(kecepatan: 3.5, menit: 30);

      expect(lari.jarakMeter, greaterThan(jalan.jarakMeter * 2));
      expect(jalan.jarakMeter, closeTo(1.4 * 30 * 60, 100));
      expect(lari.jarakMeter, closeTo(3.5 * 30 * 60, 200));
    });

    test('moda dominan terdeteksi benar', () {
      expect(sesiKecepatan(kecepatan: 1.4, menit: 20).modaDominan,
          ModaGerak.jalan);
      expect(sesiKecepatan(kecepatan: 3.5, menit: 20).modaDominan,
          ModaGerak.lari);
    });
  });

  group('⭐ Anti-curang: kendaraan tidak menghasilkan apa pun', () {
    test('naik motor 30 menit → 0 menit bergerak, 0 jarak', () {
      final motor = sesiKecepatan(kecepatan: 11.0, menit: 30); // ~40 km/jam

      expect(motor.menitBergerak, 0);
      expect(motor.jarakMeter, 0);
    });

    test('naik motor tidak membuka petak satu pun', () {
      final motor = sesiKecepatan(kecepatan: 11.0, menit: 30);
      expect(motor.petakDilewati(grid), isEmpty);
    });

    test('jalan kaki dengan durasi sama membuka banyak petak', () {
      final jalan = sesiKecepatan(kecepatan: 1.4, menit: 30);
      expect(jalan.petakDilewati(grid).length, greaterThan(15));
    });

    test('HP diam di meja tidak menghasilkan menit bergerak', () {
      final diam = sesiKecepatan(kecepatan: 0.1, menit: 60);
      expect(diam.menitBergerak, 0);
      expect(diam.petakDilewati(grid), isEmpty);
    });

    test('sesi campuran hanya menghitung bagian jalan/lari', () {
      // Naik motor 10 menit ke taman, lalu jalan 20 menit.
      final motor = sesiKecepatan(kecepatan: 11.0, menit: 10);
      final akhirMotor = motor.titik.last;
      final jalan = sesiKecepatan(
        kecepatan: 1.4,
        menit: 20,
        awal: akhirMotor.koordinat,
        waktuMulai: akhirMotor.waktu,
      );

      final campuran = Sesi(
        id: 'c',
        mulai: mulai,
        selesai: jalan.selesai,
        titik: [...motor.titik, ...jalan.titik],
      );

      // Hanya bagian jalan yang dihitung (toleransi 1 menit untuk ruas
      // sambungan antara akhir motor dan awal jalan).
      expect(campuran.menitBergerak, closeTo(20, 1));
      expect(campuran.jarakMeter, closeTo(1.4 * 20 * 60, 200));
    });
  });

  group('Zona privat rumah', () {
    test('petak di dalam radius rumah tidak pernah jadi klaim', () {
      final jalan = sesiKecepatan(kecepatan: 1.4, menit: 30);
      final semua = jalan.petakDilewati(grid);

      final rumah = [const ZonaPrivat(pusat: tebet, label: 'Rumah')];
      final publik = Privasi.saring(semua, rumah, grid);

      expect(publik.length, lessThan(semua.length),
          reason: 'petak dekat rumah harus tersaring');
      // Tidak ada petak publik yang pusatnya di dalam radius rumah.
      for (final p in publik) {
        expect(tebet.jarakKe(grid.pusat(p)),
            greaterThan(Privasi.radiusBakuMeter));
      }
    });

    test('tanpa zona privat, semua petak lolos', () {
      final jalan = sesiKecepatan(kecepatan: 1.4, menit: 10);
      final semua = jalan.petakDilewati(grid);
      expect(Privasi.saring(semua, const [], grid), semua);
    });

    test('titik di dalam zona terdeteksi', () {
      final rumah = [const ZonaPrivat(pusat: tebet)];
      expect(Privasi.tertutup(tebet, rumah), isTrue);
      expect(Privasi.tertutup(const Koordinat(-6.1751, 106.8650), rumah),
          isFalse);
    });
  });

  group('Kasus tepi sesi', () {
    test('sesi kosong aman', () {
      final kosong = Sesi(id: 'k', mulai: mulai);
      expect(kosong.jarakMeter, 0);
      expect(kosong.menitBergerak, 0);
      expect(kosong.petakDilewati(grid), isEmpty);
      expect(kosong.segmen, isEmpty);
      expect(kosong.berjalan, isTrue);
    });

    test('sesi satu titik tidak punya segmen', () {
      final satu = Sesi(id: 's1', mulai: mulai, titik: [
        TitikJejak(tebet, mulai),
      ]);
      expect(satu.segmen, isEmpty);
      expect(satu.jarakMeter, 0);
    });
  });
}
