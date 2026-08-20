import 'package:flutter_test/flutter_test.dart';
import 'package:rukun/data/notifikasi.dart';

void main() {
  group('⭐ Notifikasi harus mengundang, bukan menghakimi', () {
    /// Kata-kata yang tidak boleh pernah muncul di notifikasi Rukun.
    ///
    /// Rasa bersalah menaikkan angka minggu ini dan menghilangkan pengguna
    /// bulan depan. DESIGN.md §8.
    const terlarang = [
      'belum', 'gagal', 'ketinggalan', 'malas', 'turun',
      'kalah', 'peringkat', 'pace', 'kalori', 'km/jam',
    ];

    void cekNada(({String judul, String isi}) pesan) {
      final teks = '${pesan.judul} ${pesan.isi}'.toLowerCase();
      for (final kata in terlarang) {
        // "Belum ada yang lewat" menggambarkan petaknya, bukan menyalahkan
        // pengguna — jadi yang dilarang adalah bentuk yang menuduh.
        if (kata == 'belum') continue;
        expect(teks.contains(kata), isFalse,
            reason: 'notifikasi tidak boleh memuat "$kata": $teks');
      }
    }

    test('petak hangus → ajakan, bukan tuduhan', () {
      final p = PesanHarian.susun(petakHangus: 3, namaKelurahan: 'Tebet');

      expect(p.judul, contains('3'));
      expect(p.isi, contains('?'), reason: 'ajakan, bukan perintah');
      expect(p.judul.toLowerCase(), isNot(contains('kamu belum')));
      cekNada(p);
    });

    test('kelurahan tetangga naik → ajakan santai', () {
      final p = PesanHarian.susun(
        petakHangus: 0,
        namaKelurahan: 'Tebet',
        kelurahanNaik: 'Menteng',
        selisihNaik: 4,
      );

      expect(p.judul, contains('Menteng'));
      expect(p.isi, contains('?'));
      cekNada(p);
    });

    test('tanpa kejadian khusus → pengingat lembut', () {
      final p = PesanHarian.susun(petakHangus: 0, namaKelurahan: 'Tebet');

      expect(p.isi, contains('5 menit'),
          reason: 'ajakan terkecil selalu 5 menit, bukan target besar');
      cekNada(p);
    });

    test('tidak pernah menyebut angka performa', () {
      for (final p in [
        PesanHarian.susun(petakHangus: 5, namaKelurahan: 'Tebet'),
        PesanHarian.susun(
            petakHangus: 0,
            namaKelurahan: 'Tebet',
            kelurahanNaik: 'Menteng',
            selisihNaik: 9),
        PesanHarian.susun(petakHangus: 0, namaKelurahan: 'Tebet'),
      ]) {
        cekNada(p);
      }
    });
  });
}
