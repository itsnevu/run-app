import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukun/app.dart';
import 'package:rukun/data/lokasi.dart';
import 'package:rukun/features/onboarding/layar_onboarding.dart';
import 'package:rukun/shared/widgets/bilah_tab.dart';
import 'package:rukun/state/penyedia.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences pref;

  /// Membungkus aplikasi dengan penyimpanan kosong dan lokasi palsu —
  /// pengujian tidak boleh bergantung pada GPS atau jaringan.
  Future<Widget> bungkus({Map<String, Object> awal = const {}}) async {
    SharedPreferences.setMockInitialValues(awal);
    pref = await SharedPreferences.getInstance();

    return ProviderScope(
      overrides: [
        prefProvider.overrideWithValue(pref),
        lokasiProvider.overrideWithValue(LokasiPalsu()),
      ],
      child: const AplikasiRukun(),
    );
  }

  group('Gerbang', () {
    testWidgets('pengguna baru masuk ke onboarding', (tester) async {
      await tester.pumpWidget(await bungkus());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LayarOnboarding), findsOneWidget);
      expect(find.text('Rukun'), findsOneWidget);
      expect(find.text('Mulai'), findsOneWidget);
    });

    testWidgets('pengguna lama langsung ke cangkang utama', (tester) async {
      await tester.pumpWidget(await bungkus(awal: {
        'flutter.profil':
            '{"id":"saya","nama":"Navy","kelurahanId":"tebet"}',
      }));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CangkangRukun), findsOneWidget);
      expect(find.byType(BilahTab), findsOneWidget);
    });
  });

  group('⭐ Onboarding tidak boleh meminta hal yang menyisihkan pemula', () {
    testWidgets('tidak ada tinggi, berat, atau level kebugaran',
        (tester) async {
      await tester.pumpWidget(await bungkus());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // DESIGN.md §7.1 — aturan mutlak.
      for (final terlarang in [
        'Tinggi', 'tinggi badan', 'Berat', 'berat badan',
        'Level', 'level kebugaran', 'Umur', 'Usia',
      ]) {
        expect(find.textContaining(terlarang), findsNothing,
            reason: 'onboarding tidak boleh menyebut "$terlarang"');
      }
    });

    testWidgets('kata "lari" tidak muncul di layar pertama', (tester) async {
      // Kata itu baru boleh muncul setelah petak pertama terbuka.
      await tester.pumpWidget(await bungkus());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('lari'), findsNothing);
      expect(find.textContaining('Lari'), findsNothing);
    });

    testWidgets('ajakan pertama adalah 5 menit, bukan 5K', (tester) async {
      await tester.pumpWidget(await bungkus());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Mulai'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Izinkan lokasi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();

      expect(find.text('Jalan 5 menit'), findsOneWidget);
      expect(find.textContaining('5K'), findsNothing);
      expect(find.textContaining('km'), findsNothing);
    });

    testWidgets('tim diberikan sebelum diminta apa pun', (tester) async {
      await tester.pumpWidget(await bungkus());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Mulai'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Izinkan lokasi'));
      await tester.pumpAndSettle();

      expect(find.text('Ini tim kamu'), findsOneWidget);
      expect(find.textContaining('Kamu yang ke-'), findsOneWidget);
    });
  });

  group('⭐ Pace tidak pernah terlihat', () {
    testWidgets('layar utama tidak menampilkan pace atau kecepatan',
        (tester) async {
      await tester.pumpWidget(await bungkus(awal: {
        'flutter.profil':
            '{"id":"saya","nama":"Navy","kelurahanId":"tebet"}',
      }));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // DESIGN.md §8 — daftar kata terlarang.
      for (final terlarang in [
        'pace', 'Pace', 'km/jam', 'menit/km', 'kecepatan', 'Kecepatan',
        'VO2', 'kalori', 'Kalori',
      ]) {
        expect(find.textContaining(terlarang), findsNothing,
            reason: 'permukaan publik tidak boleh menampilkan "$terlarang"');
      }
    });
  });

  group('Navigasi tab', () {
    Future<void> keCangkang(WidgetTester tester) async {
      await tester.pumpWidget(await bungkus(awal: {
        'flutter.profil':
            '{"id":"saya","nama":"Navy","kelurahanId":"tebet"}',
      }));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }

    testWidgets('empat tab tersedia', (tester) async {
      await keCangkang(tester);
      for (final label in ['Peta', 'Tim', 'Misi', 'Aku']) {
        expect(find.text(label), findsWidgets);
      }
    });

    testWidgets('pindah ke Tim menampilkan kelurahan', (tester) async {
      await keCangkang(tester);
      await tester.tap(find.text('Tim').first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Kelurahan'), findsWidgets);
      expect(find.text('Yang bergerak minggu ini'), findsOneWidget);
    });

    testWidgets('pindah ke Aku menampilkan konsistensi, bukan kecepatan',
        (tester) async {
      await keCangkang(tester);
      await tester.tap(find.text('Aku').first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('dari 7 hari'), findsOneWidget);
      expect(find.textContaining('Konsistensi'), findsOneWidget);
    });

    testWidgets('pindah ke Misi menampilkan jalur pemula', (tester) async {
      await keCangkang(tester);
      await tester.tap(find.text('Misi').first);
      await tester.pump(const Duration(milliseconds: 300));

      // Jalur santai harus ada dan setara martabatnya.
      expect(find.text('Santai'), findsWidgets);
    });
  });
}
