import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukun/core/theme/rukun_colors.dart';
import 'package:rukun/core/theme/rukun_theme.dart';
import 'package:rukun/domain/model/pelintas.dart';
import 'package:rukun/shared/widgets/perayaan_klaim.dart';

void main() {
  Widget bungkus(Widget anak) => MaterialApp(
        theme: RukunTheme.terang,
        home: Scaffold(body: anak),
      );

  group('Perayaan klaim menyebut ORANGNYA', () {
    testWidgets('menyebut dua tetangga dan menempatkan kamu sebagai ketiga',
        (tester) async {
      await tester.pumpWidget(bungkus(const PerayaanKlaim(
        namaPetak: 'Petak Tebet',
        namaTim: 'Tebet',
        warna: TimWarna.biru,
        pelintas: [
          Pelintas(id: 'a', nama: 'Sari'),
          Pelintas(id: 'b', nama: 'Budi'),
          Pelintas(id: 'c', nama: 'Navy', kamu: true),
        ],
      )));
      await tester.pumpAndSettle();

      // Muatan emosional terbesar produk: nama tetangga nyata.
      expect(
        find.textContaining('Sari dan Budi lewat sini duluan'),
        findsOneWidget,
      );
      expect(find.textContaining('Kamu yang ketiga'), findsOneWidget);
      expect(find.textContaining('milik Tebet sekarang'), findsOneWidget);
    });

    testWidgets('tidak pernah memakai konfeti atau kata kemenangan agresif',
        (tester) async {
      await tester.pumpWidget(bungkus(const PerayaanKlaim(
        namaPetak: 'Petak Tebet',
        namaTim: 'Tebet',
        warna: TimWarna.biru,
        pelintas: [
          Pelintas(id: 'a', nama: 'Sari'),
          Pelintas(id: 'b', nama: 'Budi'),
          Pelintas(id: 'c', nama: 'Navy', kamu: true),
        ],
      )));
      await tester.pumpAndSettle();

      for (final terlarang in ['Menang', 'Kalah', 'Juara', 'Peringkat']) {
        expect(find.textContaining(terlarang), findsNothing);
      }
    });

    testWidgets('tiga avatar ditampilkan', (tester) async {
      await tester.pumpWidget(bungkus(const PerayaanKlaim(
        namaPetak: 'Petak Tebet',
        namaTim: 'Tebet',
        warna: TimWarna.hijau,
        pelintas: [
          Pelintas(id: 'a', nama: 'Sari'),
          Pelintas(id: 'b', nama: 'Budi'),
          Pelintas(id: 'c', nama: 'Navy', kamu: true),
        ],
      )));
      await tester.pumpAndSettle();

      expect(find.text('S'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('N'), findsOneWidget);
    });

    testWidgets('warna kuning memakai teks gelap, bukan putih',
        (tester) async {
      // Kuning gagal kontras 4.5:1 dengan teks putih. DESIGN.md §2.7
      await tester.pumpWidget(bungkus(const PerayaanKlaim(
        namaPetak: 'Petak Senayan',
        namaTim: 'Senayan',
        warna: TimWarna.kuning,
        pelintas: [
          Pelintas(id: 'a', nama: 'Sari'),
          Pelintas(id: 'b', nama: 'Budi'),
          Pelintas(id: 'c', nama: 'Navy', kamu: true),
        ],
      )));
      await tester.pumpAndSettle();

      final teks = tester.widget<Text>(find.text('Petak terklaim'));
      expect(teks.style?.color, RukunColors.teksPrimerTerang);
    });
  });
}
