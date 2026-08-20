import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukun/data/lokasi.dart';
import 'package:rukun/domain/aturan/aturan_klaim.dart';
import 'package:rukun/domain/aturan/zona_privat.dart';
import 'package:rukun/domain/grid/grid_heks.dart';
import 'package:rukun/domain/model/kelurahan.dart';
import 'package:rukun/domain/model/koordinat.dart';
import 'package:rukun/state/kendali_sesi.dart';
import 'package:rukun/state/penyedia.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const rumah = Koordinat(-6.2264, 106.8556);
  const grid = GridHeks();

  /// Jarak per sampel. 40 m cukup untuk keluar dari radius privasi 150 m
  /// dalam beberapa sampel saja.
  const langkah = 40.0;

  /// Kecepatan jalan santai. Dipakai untuk menghitung jam sintetis supaya
  /// ModaGerak tetap membaca "jalan", bukan "kendaraan".
  const kecepatan = 1.4;

  Future<ProviderContainer> wadah({double langkahMeter = langkah}) async {
    SharedPreferences.setMockInitialValues({});
    final pref = await SharedPreferences.getInstance();

    final c = ProviderContainer(overrides: [
      prefProvider.overrideWithValue(pref),
      lokasiProvider.overrideWithValue(LokasiPalsu(
        awal: rumah,
        langkahMeter: langkahMeter,
        jedaSampel: const Duration(milliseconds: 20),
      )),
    ]);
    addTearDown(c.dispose);

    await c.read(repoProvider).simpanProfil(
          const Profil(id: 'saya', nama: 'Navy', kelurahanId: 'tebet'),
        );
    return c;
  }

  /// Menjalankan satu sesi dari [rumah] pada linimasa yang dimampatkan.
  ///
  /// Jam sintetis maju sejauh `langkah / kecepatan` detik tiap sampel,
  /// sehingga kecepatan terhitung tetap 1,4 m/detik — terbaca sebagai
  /// jalan kaki, bukan kendaraan.
  Future<HasilSesi?> jalanSebentar(
    ProviderContainer c, {
    double langkahMeter = langkah,
  }) async {
    final mulai = DateTime(2026, 8, 21, 6);
    final detikPerSampel = langkahMeter / kecepatan;
    var n = 0;
    DateTime jam() =>
        mulai.add(Duration(milliseconds: (n++ * detikPerSampel * 1000).round()));

    final kendali = c.read(kendaliSesiProvider.notifier);
    await kendali.mulai(jam: jam);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return kendali.selesai(jam: jam);
  }

  group('⭐ Zona privat rumah menyala sendiri', () {
    test('sesi pertama membuat zona rumah otomatis', () async {
      final c = await wadah();
      expect(await c.read(repoProvider).muatZonaPrivat(), isEmpty);

      await jalanSebentar(c);

      final zona = await c.read(repoProvider).muatZonaPrivat();
      expect(zona, hasLength(1),
          reason: 'privasi harus opt-out, bukan menunggu ditemukan pengguna');
      expect(zona.first.label, 'Rumah');
      expect(zona.first.radiusMeter, Privasi.radiusBakuMeter);
      expect(zona.first.pusat.jarakKe(rumah), lessThan(50));
    });

    test('sesi berikutnya tidak menggandakan zona', () async {
      final c = await wadah();
      await jalanSebentar(c);
      await jalanSebentar(c);

      expect(await c.read(repoProvider).muatZonaPrivat(), hasLength(1));
    });

    test('⭐ petak dekat rumah tidak pernah tercatat sebagai lintasan',
        () async {
      final c = await wadah();
      await jalanSebentar(c);

      final repo = c.read(repoProvider);
      final zona = await repo.muatZonaPrivat();
      expect(zona, isNotEmpty);

      // Jejak pribadi HARUS memuat petak rumah — itu milik pengguna.
      final jejak = await repo.muatJejak();
      final petakRumah = grid.petakDi(rumah);
      expect(jejak, contains(petakRumah),
          reason: 'jejak pribadi menyimpan semua petak, termasuk rumah');

      // Tapi lintasan publik untuk petak rumah TIDAK boleh memuat pengguna.
      final lintasan = await repo.lintasanPetak(petakRumah);
      final klaim = AturanKlaim.evaluasi(
        lintasan,
        sekarang: DateTime.now(),
        timSudutPandang: 'tebet',
      );
      final aku = klaim.pelintasTim('tebet').where((p) => p.kamu);
      expect(aku, isEmpty,
          reason: 'petak rumah tidak boleh pernah jadi klaim tim');
    });

    test('petak jauh dari rumah tetap tercatat normal', () async {
      final c = await wadah();
      await jalanSebentar(c);

      final repo = c.read(repoProvider);
      final jejak = await repo.muatJejak();
      expect(jejak.length, greaterThan(1));

      // Setidaknya satu petak di luar radius rumah harus tercatat.
      final zona = await repo.muatZonaPrivat();
      final diLuar = jejak.where(
        (p) => !zona.any((z) => z.menutupi(grid.pusat(p))),
      );
      expect(diLuar, isNotEmpty,
          reason: 'zona privat tidak boleh melubangi seluruh peta');

      var adaLintasan = false;
      for (final p in diLuar) {
        final l = await repo.lintasanPetak(p);
        if (l.any((x) => x.pelintas.kamu)) adaLintasan = true;
      }
      expect(adaLintasan, isTrue,
          reason: 'petak di luar rumah harus tetap jadi kontribusi tim');
    });
  });
}
