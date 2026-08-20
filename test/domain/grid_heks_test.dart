import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rukun/domain/grid/grid_heks.dart';
import 'package:rukun/domain/grid/grid_petak.dart';
import 'package:rukun/domain/model/koordinat.dart';

void main() {
  const grid = GridHeks();

  // Tebet, Jakarta Selatan — lokasi acuan sepanjang pengujian.
  const tebet = Koordinat(-6.2264, 106.8556);

  group('Geometri petak', () {
    test('lebar petak ~132 m, setara H3 resolusi 10', () {
      expect(grid.lebarMeter, closeTo(131.6, 1.0));
    });

    test('luas petak ~15.000 m², setara H3 resolusi 10', () {
      // Luas heksagon beraturan = (3√3 / 2) · sisi²
      final luas = 3 * math.sqrt(3) / 2 * math.pow(grid.ukuranMeter, 2);
      expect(luas, closeTo(15000, 600));
    });

    test('titik di dalam petak selalu memetakan balik ke petak itu', () {
      final id = grid.petakDi(tebet);
      final tengah = grid.pusat(id);
      expect(grid.petakDi(tengah), id,
          reason: 'pusat petak harus jatuh di petak itu sendiri');
    });

    test('pusat petak dekat dengan titik asal (< setengah lebar)', () {
      final id = grid.petakDi(tebet);
      expect(tebet.jarakKe(grid.pusat(id)), lessThan(grid.lebarMeter / 2 + 5));
    });

    test('batas punya 6 sudut, semua berjarak ~ukuran dari pusat', () {
      final id = grid.petakDi(tebet);
      final sudut = grid.batas(id);
      final tengah = grid.pusat(id);

      expect(sudut, hasLength(6));
      for (final s in sudut) {
        // Mercator meregang ~0,6% di lintang Jakarta — toleransi 3%.
        expect(tengah.jarakKe(s),
            closeTo(grid.ukuranMeter, grid.ukuranMeter * 0.03));
      }
    });

    test('petak berbeda untuk lokasi yang berjauhan', () {
      final a = grid.petakDi(tebet);
      final b = grid.petakDi(const Koordinat(-6.1751, 106.8650)); // Monas
      expect(a, isNot(b));
    });

    test('kode petak bisa pulang-pergi', () {
      final id = grid.petakDi(tebet);
      expect(IdPetak.dariKode(id.kode), id);
    });

    test('kode tidak sah ditolak', () {
      expect(() => IdPetak.dariKode('bukan-kode'), throwsFormatException);
    });
  });

  group('Tetangga', () {
    test('setiap petak punya 6 tetangga langsung, semua berbeda', () {
      final id = grid.petakDi(tebet);
      final t = grid.tetangga(id);
      expect(t, hasLength(6));
      expect(t.toSet(), hasLength(6));
      expect(t.contains(id), isFalse);
    });

    test('tetangga berjarak ~satu lebar petak dari pusat', () {
      final id = grid.petakDi(tebet);
      final tengah = grid.pusat(id);
      for (final t in grid.tetangga(id)) {
        expect(tengah.jarakKe(grid.pusat(t)),
            closeTo(grid.lebarMeter, grid.lebarMeter * 0.05));
      }
    });

    test('cincin radius 1 berisi 7 petak (pusat + 6)', () {
      final id = grid.petakDi(tebet);
      expect(grid.cincin(id, 1).toSet(), hasLength(7));
    });

    test('cincin radius 2 berisi 19 petak', () {
      final id = grid.petakDi(tebet);
      expect(grid.cincin(id, 2).toSet(), hasLength(19));
    });
  });

  group('Jalur', () {
    /// Membuat jalur lurus ke timur sepanjang [meter].
    List<Koordinat> jalurLurus(Koordinat awal, double meter, int titik) {
      // 1 derajat bujur ≈ 111.320·cos(lat) meter
      final meterPerDerajat = 111320 * math.cos(awal.lat * math.pi / 180);
      return [
        for (var i = 0; i <= titik; i++)
          Koordinat(awal.lat, awal.lng + (meter * i / titik) / meterPerDerajat),
      ];
    }

    test('jalan kaki 5 menit (~400 m) melintasi ~3 petak', () {
      // Klaim ini ada di DESIGN.md §10.3 dan menjadi dasar janji onboarding
      // "jalan 5 menit buat buka petak pertamamu".
      final petak = grid.petakSepanjang(jalurLurus(tebet, 400, 40));
      expect(petak.length, inInclusiveRange(3, 5),
          reason: 'dapat ${petak.length} petak untuk 400 m');
    });

    test('titik GPS yang berjauhan tidak melewatkan petak di antaranya', () {
      // Dua titik 1 km terpisah, hanya diberikan sebagai 2 sampel.
      final kasar = grid.petakSepanjang(jalurLurus(tebet, 1000, 1));
      final rapat = grid.petakSepanjang(jalurLurus(tebet, 1000, 200));

      expect(kasar.length, greaterThanOrEqualTo(7),
          reason: 'interpolasi harus mengisi petak di antara sampel');
      // Interpolasi kasar harus menghasilkan rangkaian yang sama dengan rapat.
      expect(kasar, equals(rapat));
    });

    test('jalur kosong menghasilkan himpunan kosong', () {
      expect(grid.petakSepanjang([]), isEmpty);
    });

    test('satu titik menghasilkan satu petak', () {
      expect(grid.petakSepanjang([tebet]), {grid.petakDi(tebet)});
    });

    test('petak sepanjang jalur saling bertetangga (tidak ada lompatan)', () {
      final petak = grid.petakSepanjang(jalurLurus(tebet, 600, 60)).toList();
      // Setiap petak (kecuali yang pertama) harus bertetangga dengan
      // setidaknya satu petak lain dalam himpunan.
      for (final p in petak) {
        final punyaTetangga =
            grid.tetangga(p).any((t) => petak.contains(t));
        expect(punyaTetangga, isTrue, reason: '$p terisolasi dari jalur');
      }
    });
  });

  group('Konsistensi lintas Indonesia', () {
    test('ukuran petak stabil dari Aceh sampai Papua', () {
      const lokasi = {
        'Banda Aceh': Koordinat(5.5483, 95.3238),
        'Jakarta': Koordinat(-6.2088, 106.8456),
        'Surabaya': Koordinat(-7.2575, 112.7521),
        'Jayapura': Koordinat(-2.5337, 140.7181),
        'Kupang': Koordinat(-10.1772, 123.6070),
      };

      for (final entri in lokasi.entries) {
        final id = grid.petakDi(entri.value);
        final tengah = grid.pusat(id);
        final sudut = grid.batas(id);
        final jari = tengah.jarakKe(sudut.first);
        // Simpangan Mercator di rentang lintang Indonesia harus < 2%.
        expect(jari, closeTo(grid.ukuranMeter, grid.ukuranMeter * 0.02),
            reason: '${entri.key}: jari-jari ${jari.toStringAsFixed(1)} m');
      }
    });
  });
}
