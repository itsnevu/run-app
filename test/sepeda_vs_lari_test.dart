import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukun/data/lokasi.dart';
import 'package:rukun/data/sensor_irama.dart';
import 'package:rukun/domain/aturan/moda_gerak.dart';
import 'package:rukun/domain/model/kelurahan.dart';
import 'package:rukun/domain/model/koordinat.dart';
import 'package:rukun/state/kendali_sesi.dart';
import 'package:rukun/state/penyedia.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const awal = Koordinat(-6.2264, 106.8556);

  /// 5 m/detik — tepat di zona ambigu antara lari dan bersepeda santai.
  const kecepatan = 5.0;
  const langkah = 40.0;

  Future<ProviderContainer> wadah({required bool? adaLangkah}) async {
    SharedPreferences.setMockInitialValues({});
    final pref = await SharedPreferences.getInstance();

    final c = ProviderContainer(overrides: [
      prefProvider.overrideWithValue(pref),
      lokasiProvider.overrideWithValue(LokasiPalsu(
        awal: awal,
        langkahMeter: langkah,
        jedaSampel: const Duration(milliseconds: 20),
      )),
      sensorIramaProvider
          .overrideWithValue(SensorIramaPalsu(melangkah: adaLangkah)),
    ]);
    addTearDown(c.dispose);

    await c.read(repoProvider).simpanProfil(
          const Profil(id: 'saya', nama: 'Navy', kelurahanId: 'tebet'),
        );
    return c;
  }

  /// Jam sintetis: tiap sampel maju `langkah / kecepatan` detik, sehingga
  /// kecepatan terhitung tepat 5 m/detik.
  Future<HasilSesi?> bergerak(ProviderContainer c) async {
    final mulai = DateTime(2026, 8, 21, 6);
    final detikPerSampel = langkah / kecepatan;
    var n = 0;
    DateTime jam() => mulai
        .add(Duration(milliseconds: (n++ * detikPerSampel * 1000).round()));

    final kendali = c.read(kendaliSesiProvider.notifier);
    await kendali.mulai(jam: jam);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return kendali.selesai(jam: jam);
  }

  group('⭐ Sepeda vs lari pada kecepatan yang sama', () {
    test('5 m/detik DENGAN irama langkah → petak terbuka', () async {
      final c = await wadah(adaLangkah: true);
      final hasil = await bergerak(c);

      expect(hasil, isNotNull);
      expect(hasil!.petakDibuka, greaterThan(0),
          reason: 'orang yang benar-benar berlari harus dihitung penuh');
      expect(hasil.sesi.menitBergerak, greaterThan(0));
      expect(hasil.sesi.modaDominan, ModaGerak.lari);
    });

    test('⭐ 5 m/detik TANPA irama langkah → NOL petak', () async {
      // Kecepatan identik, satu-satunya beda adalah irama langkah.
      // Tanpa ini, bersepeda keliling kota bisa mengklaim petak seperti
      // pejalan kaki — dan gagasan "jumlah orang yang bergerak" kehilangan
      // maknanya.
      final c = await wadah(adaLangkah: false);
      final hasil = await bergerak(c);

      expect(hasil, isNotNull);
      expect(hasil!.petakDibuka, 0,
          reason: 'bersepeda tidak boleh membuka petak satu pun');
      expect(hasil.sesi.menitBergerak, 0);
      expect(hasil.sesi.jarakMeter, 0);
    });

    test('tanpa sensor → keuntungan diberikan pada pengguna', () async {
      // Perangkat tanpa akselerometer tidak boleh menghukum penggunanya.
      final c = await wadah(adaLangkah: null);
      final hasil = await bergerak(c);

      expect(hasil, isNotNull);
      expect(hasil!.petakDibuka, greaterThan(0),
          reason: 'tidak tahu bukan berarti menuduh');
    });

    test('jejak pribadi ikut kosong saat bersepeda', () async {
      final c = await wadah(adaLangkah: false);
      await bergerak(c);

      expect(await c.read(repoProvider).muatJejak(), isEmpty,
          reason: 'bersepeda tidak membuka kabut, bahkan untuk diri sendiri');
    });
  });
}
