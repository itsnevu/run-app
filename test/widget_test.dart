import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukun/core/theme/rukun_colors.dart';
import 'package:rukun/core/theme/rukun_gradients.dart';
import 'package:rukun/core/theme/rukun_theme.dart';
import 'package:rukun/main.dart';
import 'package:rukun/shared/widgets/petak_bar.dart';

void main() {
  group('Aturan Delta Kecil (DESIGN.md §2.2)', () {
    /// Gradient yang bagus tidak terlihat sebagai gradient. Batas keras ini
    /// yang membedakan "clean" dari "norak" — diuji, bukan sekadar ditulis.
    void cekDelta(String nama, LinearGradient g, {double maksHue = 40}) {
      final a = HSLColor.fromColor(g.colors.first);
      final b = HSLColor.fromColor(g.colors.last);

      var deltaHue = (a.hue - b.hue).abs();
      if (deltaHue > 180) deltaHue = 360 - deltaHue;
      final deltaLight = (a.lightness - b.lightness).abs();
      final deltaSat = (a.saturation - b.saturation).abs();

      expect(deltaHue, lessThanOrEqualTo(maksHue),
          reason: '$nama: pergeseran hue ${deltaHue.toStringAsFixed(1)}° '
              'melebihi batas $maksHue°');
      expect(deltaLight, lessThanOrEqualTo(0.22),
          reason: '$nama: delta lightness '
              '${(deltaLight * 100).toStringAsFixed(1)}% melebihi 22%');
      expect(deltaSat, lessThanOrEqualTo(0.20),
          reason: '$nama: delta saturation '
              '${(deltaSat * 100).toStringAsFixed(1)}% melebihi 20%');
    }

    test('gradient brand patuh batas', () {
      final g = RukunGradients.terangTheme;
      cekDelta('terang', g.terang);
      cekDelta('fajar', g.fajar);
      cekDelta('misi', g.misi);
      cekDelta('kabut', g.kabut);
      cekDelta('tumbuh', g.tumbuh);
      cekDelta('hangus', g.hangus);
      cekDelta('bahaya', g.bahaya);
    });

    test('semua gradient tim patuh batas', () {
      for (final t in TimWarna.values) {
        cekDelta('tim ${t.label}', t.gradient);
      }
    });

    test('semua gradient mengalir 135° — satu sumber cahaya', () {
      final g = RukunGradients.terangTheme;
      for (final grad in [g.terang, g.fajar, g.misi, g.kabut, g.latar]) {
        expect(grad.begin, Alignment.topLeft);
        expect(grad.end, Alignment.bottomRight);
      }
      for (final t in TimWarna.values) {
        expect(t.gradient.begin, Alignment.topLeft);
        expect(t.gradient.end, Alignment.bottomRight);
      }
    });

    test('gradient permukaan nyaris tak terlihat', () {
      final g = RukunGradients.terangTheme;
      final a = HSLColor.fromColor(g.permukaan.colors.first);
      final b = HSLColor.fromColor(g.permukaan.colors.last);
      expect((a.lightness - b.lightness).abs(), lessThan(0.05),
          reason: 'permukaan harus delta 2-4% — kamu tidak boleh sadar ia ada');
    });
  });

  group('Kontras teks di atas gradient (DESIGN.md §2.7)', () {
    test('kuning menolak teks putih', () {
      // Kuning gagal 4.5:1 — harus pakai teks gelap.
      expect(TimWarna.kuning.teksPutihAman, isFalse);
    });

    test('tim gelap menerima teks putih', () {
      expect(TimWarna.biru.teksPutihAman, isTrue);
      expect(TimWarna.ungu.teksPutihAman, isTrue);
    });
  });

  group('Bilah Petak — mekanik inti 3-orang-berbeda', () {
    Widget bungkus(Widget anak) => MaterialApp(
          theme: RukunTheme.terang,
          home: Scaffold(body: anak),
        );

    testWidgets('2 dari 3 orang → belum terklaim, minta 1 lagi',
        (tester) async {
      await tester.pumpWidget(bungkus(const BilahPetak(
        namaPetak: 'Petak Tebet Barat',
        pelintas: [
          Pelintas(nama: 'Sari'),
          Pelintas(nama: 'Kamu', kamu: true),
        ],
        tim: TimWarna.biru,
        buram: false,
      )));

      expect(find.text('Tinggal 1 orang lagi buat klaim petak ini.'),
          findsOneWidget);
      expect(find.text('Terklaim'), findsNothing);
    });

    testWidgets('3 orang berbeda → terklaim, menyebut nama tetangga',
        (tester) async {
      await tester.pumpWidget(bungkus(const BilahPetak(
        namaPetak: 'Petak Tebet Barat',
        pelintas: [
          Pelintas(nama: 'Sari'),
          Pelintas(nama: 'Kamu', kamu: true),
          Pelintas(nama: 'Budi'),
        ],
        tim: TimWarna.biru,
        buram: false,
      )));

      expect(find.text('Terklaim'), findsOneWidget);
      // Salinan teks harus menyebut orangnya — DESIGN.md §8
      expect(find.textContaining('Sari'), findsWidgets);
    });

    testWidgets('petak kosong mengundang, tidak menghakimi', (tester) async {
      await tester.pumpWidget(bungkus(const BilahPetak(
        namaPetak: 'Petak Baru',
        pelintas: [],
        tim: TimWarna.hijau,
        buram: false,
      )));

      expect(find.textContaining('Kamu bisa jadi yang pertama'),
          findsOneWidget);
    });
  });

  group('Aplikasi', () {
    testWidgets('showcase tampil di mode terang & gelap', (tester) async {
      await tester.pumpWidget(const AplikasiRukun());
      await tester.pumpAndSettle();

      expect(find.text('Rukun'), findsOneWidget);
      expect(find.text('Petak Tebet Barat'), findsOneWidget);
    });
  });

  group('Tata letak di lebar HP nyata', () {
    /// Mayoritas pasar Indonesia adalah Android kelas menengah dengan layar
    /// sempit. Overflow di 360px adalah kegagalan produk, bukan kosmetik.
    Future<void> cekLebar(WidgetTester tester, Size ukuran) async {
      tester.view.physicalSize = ukuran;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const AplikasiRukun());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull,
          reason: 'overflow pada lebar ${ukuran.width.toInt()}px');
    }

    testWidgets('iPhone 430×932 tanpa overflow', (tester) async {
      await cekLebar(tester, const Size(430, 932));
    });

    testWidgets('Android sempit 360×800 tanpa overflow', (tester) async {
      await cekLebar(tester, const Size(360, 800));
    });

    testWidgets('Android sangat sempit 320×640 tanpa overflow',
        (tester) async {
      await cekLebar(tester, const Size(320, 640));
    });
  });
}
