import 'package:flutter_test/flutter_test.dart';
import 'package:rukun/domain/aturan/aturan_klaim.dart';
import 'package:rukun/domain/model/pelintas.dart';

void main() {
  // Waktu acuan tetap — tidak boleh memakai DateTime.now() di dalam uji.
  final sekarang = DateTime(2026, 8, 21, 18, 0);

  const sari = Pelintas(id: 'u1', nama: 'Sari');
  const kamu = Pelintas(id: 'u2', nama: 'Navy', kamu: true);
  const budi = Pelintas(id: 'u3', nama: 'Budi');
  const rina = Pelintas(id: 'u4', nama: 'Rina');

  Lintasan lewat(Pelintas p, String tim, {Duration lalu = Duration.zero}) =>
      Lintasan(pelintas: p, timId: tim, waktu: sekarang.subtract(lalu));

  group('Aturan inti: 3 orang BERBEDA', () {
    test('⭐ satu orang lewat 3 kali TIDAK mengklaim petak', () {
      // Ini pengujian terpenting di seluruh basis kode.
      // Kalau ini gagal, seluruh tesis produk runtuh: atlet super akan
      // bisa menguasai kota sendirian dan pemula jadi tidak berarti.
      final hasil = AturanKlaim.evaluasi(
        [
          lewat(sari, 'tebet', lalu: const Duration(days: 3)),
          lewat(sari, 'tebet', lalu: const Duration(days: 2)),
          lewat(sari, 'tebet', lalu: const Duration(days: 1)),
        ],
        sekarang: sekarang,
        timSudutPandang: 'tebet',
      );

      expect(hasil.terklaim, isFalse);
      expect(hasil.pelintasTim('tebet'), hasLength(1));
      expect(hasil.sisaUntukKlaim, 2);
    });

    test('3 orang berbeda dari tim yang sama MENGKLAIM petak', () {
      final hasil = AturanKlaim.evaluasi(
        [
          lewat(sari, 'tebet', lalu: const Duration(days: 3)),
          lewat(kamu, 'tebet', lalu: const Duration(days: 2)),
          lewat(budi, 'tebet', lalu: const Duration(days: 1)),
        ],
        sekarang: sekarang,
        timSudutPandang: 'tebet',
      );

      expect(hasil.terklaim, isTrue);
      expect(hasil.timPemilik, 'tebet');
      expect(hasil.sisaUntukKlaim, 0);
    });

    test('2 orang belum cukup — sisa 1', () {
      final hasil = AturanKlaim.evaluasi(
        [lewat(sari, 'tebet'), lewat(kamu, 'tebet')],
        sekarang: sekarang,
        timSudutPandang: 'tebet',
      );

      expect(hasil.terklaim, isFalse);
      expect(hasil.sisaUntukKlaim, 1);
    });

    test('3 orang dari tim BERBEDA tidak mengklaim apa pun', () {
      // Aturannya "3 anggota dari tim yang SAMA".
      final hasil = AturanKlaim.evaluasi(
        [
          lewat(sari, 'tebet'),
          lewat(kamu, 'menteng'),
          lewat(budi, 'kuningan'),
        ],
        sekarang: sekarang,
        timSudutPandang: 'tebet',
      );

      expect(hasil.terklaim, isFalse);
      expect(hasil.sisaUntukKlaim, 2);
    });

    test('pelintas unik terurut dari yang paling awal lewat', () {
      final hasil = AturanKlaim.evaluasi(
        [
          lewat(budi, 'tebet', lalu: const Duration(days: 1)),
          lewat(sari, 'tebet', lalu: const Duration(days: 3)),
          lewat(kamu, 'tebet', lalu: const Duration(days: 2)),
        ],
        sekarang: sekarang,
      );

      expect(
        hasil.pelintasTim('tebet').map((p) => p.nama),
        ['Sari', 'Navy', 'Budi'],
      );
    });
  });

  group('Jendela 7 hari', () {
    test('lintasan lebih dari 7 hari lalu tidak dihitung', () {
      final hasil = AturanKlaim.evaluasi(
        [
          lewat(sari, 'tebet', lalu: const Duration(days: 8)),
          lewat(kamu, 'tebet', lalu: const Duration(days: 9)),
          lewat(budi, 'tebet', lalu: const Duration(days: 1)),
        ],
        sekarang: sekarang,
        timSudutPandang: 'tebet',
      );

      expect(hasil.terklaim, isFalse);
      expect(hasil.pelintasTim('tebet'), hasLength(1));
      expect(hasil.sisaUntukKlaim, 2);
    });

    test('tepat di dalam jendela masih dihitung', () {
      final hasil = AturanKlaim.evaluasi(
        [
          lewat(sari, 'tebet', lalu: const Duration(days: 6, hours: 23)),
          lewat(kamu, 'tebet', lalu: const Duration(days: 1)),
          lewat(budi, 'tebet'),
        ],
        sekarang: sekarang,
        timSudutPandang: 'tebet',
      );

      expect(hasil.terklaim, isTrue);
    });

    test('petak hangus 7 hari setelah lintasan terakhir', () {
      final terakhir = sekarang.subtract(const Duration(days: 6, hours: 12));
      expect(AturanKlaim.akanHangus(terakhir, sekarang), isTrue);

      final baru = sekarang.subtract(const Duration(days: 1));
      expect(AturanKlaim.akanHangus(baru, sekarang), isFalse);
    });
  });

  group('Perebutan antar tim', () {
    test('tim dengan orang TERBANYAK menang, bukan yang tercepat', () {
      // Nilai produk: yang dihargai adalah jumlah orang yang digerakkan.
      final hasil = AturanKlaim.evaluasi(
        [
          // Tebet: 4 orang
          lewat(sari, 'tebet', lalu: const Duration(days: 4)),
          lewat(kamu, 'tebet', lalu: const Duration(days: 4)),
          lewat(budi, 'tebet', lalu: const Duration(days: 4)),
          lewat(rina, 'tebet', lalu: const Duration(days: 4)),
          // Menteng: 3 orang, tapi lebih baru
          lewat(const Pelintas(id: 'm1', nama: 'Andi'), 'menteng'),
          lewat(const Pelintas(id: 'm2', nama: 'Dewi'), 'menteng'),
          lewat(const Pelintas(id: 'm3', nama: 'Eko'), 'menteng'),
        ],
        sekarang: sekarang,
      );

      expect(hasil.timPemilik, 'tebet',
          reason: '4 orang harus mengalahkan 3 orang yang lebih baru');
    });

    test('seri dipecahkan oleh aktivitas terbaru', () {
      final hasil = AturanKlaim.evaluasi(
        [
          lewat(sari, 'tebet', lalu: const Duration(days: 5)),
          lewat(kamu, 'tebet', lalu: const Duration(days: 5)),
          lewat(budi, 'tebet', lalu: const Duration(days: 5)),
          lewat(const Pelintas(id: 'm1', nama: 'Andi'), 'menteng',
              lalu: const Duration(days: 1)),
          lewat(const Pelintas(id: 'm2', nama: 'Dewi'), 'menteng',
              lalu: const Duration(days: 1)),
          lewat(const Pelintas(id: 'm3', nama: 'Eko'), 'menteng',
              lalu: const Duration(hours: 2)),
        ],
        sekarang: sekarang,
      );

      expect(hasil.timPemilik, 'menteng');
    });

    test('wilayah bisa berpindah tangan', () {
      final lintasan = [
        lewat(sari, 'tebet', lalu: const Duration(days: 6)),
        lewat(kamu, 'tebet', lalu: const Duration(days: 6)),
        lewat(budi, 'tebet', lalu: const Duration(days: 6)),
      ];
      expect(
        AturanKlaim.evaluasi(lintasan, sekarang: sekarang).timPemilik,
        'tebet',
      );

      // Menteng mengerahkan 4 orang.
      lintasan.addAll([
        lewat(const Pelintas(id: 'm1', nama: 'Andi'), 'menteng'),
        lewat(const Pelintas(id: 'm2', nama: 'Dewi'), 'menteng'),
        lewat(const Pelintas(id: 'm3', nama: 'Eko'), 'menteng'),
        lewat(const Pelintas(id: 'm4', nama: 'Fitri'), 'menteng'),
      ]);
      expect(
        AturanKlaim.evaluasi(lintasan, sekarang: sekarang).timPemilik,
        'menteng',
      );
    });
  });

  group('Kasus tepi', () {
    test('tanpa lintasan → tidak terklaim, butuh 3 orang', () {
      final hasil = AturanKlaim.evaluasi([],
          sekarang: sekarang, timSudutPandang: 'tebet');
      expect(hasil.terklaim, isFalse);
      expect(hasil.sisaUntukKlaim, 3);
      expect(hasil.pelintasTim('tebet'), isEmpty);
    });

    test('lebih dari 3 orang tetap terklaim dan semuanya tercatat', () {
      final hasil = AturanKlaim.evaluasi(
        [
          lewat(sari, 'tebet'),
          lewat(kamu, 'tebet'),
          lewat(budi, 'tebet'),
          lewat(rina, 'tebet'),
        ],
        sekarang: sekarang,
        timSudutPandang: 'tebet',
      );
      expect(hasil.terklaim, isTrue);
      expect(hasil.pelintasTim('tebet'), hasLength(4));
      expect(hasil.sisaUntukKlaim, 0);
    });
  });
}
