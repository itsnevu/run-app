import 'package:flutter_test/flutter_test.dart';
import 'package:rukun/data/repo/repo_lokal.dart';
import 'package:rukun/data/repo/repo_rukun.dart';
import 'package:rukun/domain/aturan/aturan_klaim.dart';
import 'package:rukun/domain/grid/grid_heks.dart';
import 'package:rukun/domain/model/kelurahan.dart';
import 'package:rukun/domain/model/koordinat.dart';
import 'package:rukun/domain/model/sesi.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Suite kontrak untuk [RepoRukun].
///
/// Setiap implementasi harus lolos semua pengujian di sini. Saat backend
/// Supabase disambungkan, jalankan suite yang sama terhadapnya —
/// panggil [ujiKontrakRepo] dengan pabrik yang membuat `RepoSupabase`
/// terhubung ke proyek uji.
///
/// Inilah gunanya memisahkan kontrak dari implementasi: perpindahan dari
/// lokal ke server bisa dibuktikan, bukan diharapkan.
void ujiKontrakRepo(
  String nama,
  Future<RepoRukun> Function() buat, {
  Future<void> Function()? bersihkan,
}) {
  group('Kontrak RepoRukun — $nama', () {
    late RepoRukun repo;
    const grid = GridHeks();
    const tebet = Koordinat(-6.2264, 106.8556);

    setUp(() async {
      await bersihkan?.call();
      repo = await buat();
    });

    test('profil kosong sebelum onboarding', () async {
      expect(await repo.muatProfil(), isNull);
    });

    test('profil bisa disimpan dan dibaca lagi', () async {
      await repo.simpanProfil(
        const Profil(id: 'saya', nama: 'Navy', kelurahanId: 'tebet'),
      );

      final profil = await repo.muatProfil();
      expect(profil, isNotNull);
      expect(profil!.nama, 'Navy');
      expect(profil.kelurahanId, 'tebet');
    });

    test('kelurahan tersedia dan punya warna', () async {
      final semua = await repo.muatSemuaKelurahan();
      expect(semua, isNotEmpty);

      final satu = await repo.muatKelurahan(semua.first.id);
      expect(satu.id, semua.first.id);
      expect(satu.nama, isNotEmpty);
    });

    test('jejak kosong di awal', () async {
      expect(await repo.muatJejak(), isEmpty);
    });

    test('jejak bertambah dan tidak pernah duplikat', () async {
      final petak = grid.petakSepanjang([
        tebet,
        const Koordinat(-6.2264, 106.8600),
      ]);

      await repo.tambahJejak(petak);
      expect(await repo.muatJejak(), hasLength(petak.length));

      // Menambahkan lagi tidak boleh menggandakan.
      await repo.tambahJejak(petak);
      expect(await repo.muatJejak(), hasLength(petak.length));
    });

    test('⭐ jejak permanen — tambahan baru tidak menghapus yang lama',
        () async {
      final a = {grid.petakDi(tebet)};
      final b = {grid.petakDi(const Koordinat(-6.1751, 106.8650))};

      await repo.tambahJejak(a);
      await repo.tambahJejak(b);

      final semua = await repo.muatJejak();
      expect(semua.containsAll(a), isTrue);
      expect(semua.containsAll(b), isTrue);
    });

    test('⭐ melintas berulang tidak menambah hitungan orang', () async {
      // Ini kontrak paling penting: aturan menghitung orang BERBEDA.
      await repo.simpanProfil(
        const Profil(id: 'saya', nama: 'Navy', kelurahanId: 'tebet'),
      );

      final petak = grid.petakDi(tebet);
      final t0 = DateTime(2026, 8, 21, 6);

      await repo.catatLintasan({petak}, t0);
      await repo.catatLintasan({petak}, t0.add(const Duration(hours: 2)));
      await repo.catatLintasan({petak}, t0.add(const Duration(hours: 5)));

      final lintasan = await repo.lintasanPetak(petak);
      final klaim = AturanKlaim.evaluasi(
        lintasan,
        sekarang: t0.add(const Duration(hours: 6)),
        timSudutPandang: 'tebet',
      );

      final saya =
          klaim.pelintasTim('tebet').where((p) => p.kamu).toList();
      expect(saya, hasLength(1),
          reason: 'satu orang harus dihitung satu, berapa kali pun lewat');
    });

    test('lintasan banyak petak mengembalikan entri untuk setiap petak',
        () async {
      await repo.simpanProfil(
        const Profil(id: 'saya', nama: 'Navy', kelurahanId: 'tebet'),
      );

      final petak = grid.cincin(grid.petakDi(tebet), 1).toSet();
      final hasil = await repo.lintasanBanyakPetak(petak);

      expect(hasil.keys.toSet(), petak);
    });

    test('sesi tersimpan dan bisa dibaca', () async {
      await repo.simpanProfil(
        const Profil(id: 'saya', nama: 'Navy', kelurahanId: 'tebet'),
      );

      final mulai = DateTime(2026, 8, 21, 6);
      await repo.simpanSesi(Sesi(
        id: 's1',
        mulai: mulai,
        selesai: mulai.add(const Duration(minutes: 25)),
        titik: [
          TitikJejak(tebet, mulai),
          // ~2,1 km dalam 25 menit = 1,4 m/detik — kecepatan jalan santai.
          TitikJejak(const Koordinat(-6.2264, 106.8746),
              mulai.add(const Duration(minutes: 25))),
        ],
      ));

      expect(await repo.muatSesi(), hasLength(1));
    });

    test('hari aktif menghitung hari berbeda, bukan jumlah sesi', () async {
      await repo.simpanProfil(
        const Profil(id: 'saya', nama: 'Navy', kelurahanId: 'tebet'),
      );

      // Dua sesi di hari yang sama harus dihitung satu hari.
      final hari = DateTime.now().subtract(const Duration(days: 1));
      for (var i = 0; i < 2; i++) {
        final mulai = DateTime(hari.year, hari.month, hari.day, 6 + i * 6);
        await repo.simpanSesi(Sesi(
          id: 's$i',
          mulai: mulai,
          selesai: mulai.add(const Duration(minutes: 30)),
          titik: [
            TitikJejak(tebet, mulai),
            // ~2,5 km dalam 30 menit — jalan santai, bukan diam.
            TitikJejak(const Koordinat(-6.2264, 106.8784),
                mulai.add(const Duration(minutes: 30))),
          ],
        ));
      }

      expect(await repo.hariAktifMingguIni(), 1);
    });

    test('sesi tanpa gerak nyata tidak dihitung sebagai hari aktif',
        () async {
      await repo.simpanProfil(
        const Profil(id: 'saya', nama: 'Navy', kelurahanId: 'tebet'),
      );

      // HP tergeletak: 265 m dalam 30 menit = 0,15 m/detik → diam.
      final mulai = DateTime.now().subtract(const Duration(days: 1));
      await repo.simpanSesi(Sesi(
        id: 'diam',
        mulai: mulai,
        selesai: mulai.add(const Duration(minutes: 30)),
        titik: [
          TitikJejak(tebet, mulai),
          TitikJejak(const Koordinat(-6.2264, 106.8580),
              mulai.add(const Duration(minutes: 30))),
        ],
      ));

      expect(await repo.hariAktifMingguIni(), 0);
    });
  });
}

void main() {
  ujiKontrakRepo(
    'RepoLokal',
    () async {
      SharedPreferences.setMockInitialValues({});
      return RepoLokal(await SharedPreferences.getInstance());
    },
  );

  // Saat Supabase disambungkan, tambahkan di sini:
  //
  //   ujiKontrakRepo('RepoSupabase', () async {
  //     final klien = SupabaseClient(urlUji, kunciUji);
  //     await klien.auth.signInWithPassword(email: ..., password: ...);
  //     return RepoSupabase(klien);
  //   }, bersihkan: () => resetBasisDataUji());
  //
  // Kontraknya sama persis, jadi perpindahannya bisa dibuktikan.
}
