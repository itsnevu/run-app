import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukun/app.dart';
import 'package:rukun/data/lokasi.dart';
import 'package:rukun/features/onboarding/layar_onboarding.dart';
import 'package:rukun/shared/widgets/bilah_tab.dart';
import 'package:rukun/state/penyedia.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ⭐ **Masuk tanpa akun.**
///
/// App Store Review Guideline §5.1.1(v): aplikasi tidak boleh mewajibkan
/// pendaftaran untuk fitur yang tidak membutuhkan akun. Layar login yang
/// menghadang di detik pertama adalah alasan penolakan yang paling sering
/// terjadi — dan, terlepas dari tinjauan Apple, gerbang semacam itu membunuh
/// aktivasi jauh sebelum pengguna sempat melihat nilainya.
///
/// Berkas ini menjaga janji itu tetap benar: **tidak ada satu pun jalan di
/// aplikasi ini yang mengharuskan akun.**
void main() {
  Future<Widget> bungkus({
    Map<String, Object> awal = const {},
    StatusIzin izin = StatusIzin.selalu,
  }) async {
    SharedPreferences.setMockInitialValues(awal);
    final pref = await SharedPreferences.getInstance();

    return ProviderScope(
      overrides: [
        prefProvider.overrideWithValue(pref),
        lokasiProvider.overrideWithValue(LokasiPalsu(izin: izin)),
      ],
      child: const AplikasiRukun(),
    );
  }

  Future<void> mulai(WidgetTester tester, Widget aplikasi) async {
    await tester.pumpWidget(aplikasi);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('⭐ Tidak ada gerbang akun di pintu depan', () {
    testWidgets('layar pertama bukan login atau daftar', (tester) async {
      await mulai(tester, await bungkus());

      expect(find.byType(LayarOnboarding), findsOneWidget);

      for (final terlarang in [
        'Masuk', 'Daftar', 'Email', 'Kata sandi', 'Password',
        'Lanjut dengan Google', 'Lanjut dengan Apple',
      ]) {
        expect(find.text(terlarang), findsNothing,
            reason: 'layar pertama tidak boleh menawarkan "$terlarang"');
      }
    });

    testWidgets('"Lihat-lihat dulu" langsung membuka aplikasi',
        (tester) async {
      await mulai(tester, await bungkus());

      await tester.tap(find.text('Lihat-lihat dulu'));
      await tester.pumpAndSettle();

      expect(find.byType(CangkangRukun), findsOneWidget);
      expect(find.byType(BilahTab), findsOneWidget);
    });

    testWidgets('menolak izin lokasi tetap boleh masuk', (tester) async {
      await mulai(tester, await bungkus(izin: StatusIzin.ditolak));

      await tester.tap(find.text('Mulai'));
      await tester.pumpAndSettle();

      // Ditolak sekali pun, pintunya tetap terbuka.
      await tester.tap(find.text('Izinkan lokasi'));
      await tester.pumpAndSettle();
      expect(find.byType(LayarOnboarding), findsOneWidget);

      await tester.tap(find.text('Nanti aja'));
      await tester.pumpAndSettle();

      expect(find.byType(CangkangRukun), findsOneWidget);
    });

    testWidgets('pembuka tidak muncul dua kali', (tester) async {
      await mulai(tester, await bungkus());
      await tester.tap(find.text('Lihat-lihat dulu'));
      await tester.pumpAndSettle();

      // Buka ulang aplikasi dengan penyimpanan yang sama.
      final pref = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefProvider.overrideWithValue(pref),
            lokasiProvider.overrideWithValue(LokasiPalsu()),
          ],
          child: const AplikasiRukun(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LayarOnboarding), findsNothing);
      expect(find.byType(CangkangRukun), findsOneWidget);
    });
  });

  group('⭐ Tamu bukan versi terbatas', () {
    Future<void> keTamu(WidgetTester tester) async {
      await mulai(tester, await bungkus());
      await tester.tap(find.text('Lihat-lihat dulu'));
      await tester.pumpAndSettle();
    }

    testWidgets('akun ditawarkan di tab Aku, bukan dipaksakan',
        (tester) async {
      await keTamu(tester);
      await tester.tap(find.text('Aku').first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Masuk atau daftar'), findsOneWidget);
      expect(find.textContaining('Nggak wajib'), findsOneWidget);
    });

    testWidgets('tanpa lokasi, tab Tim tetap punya jalan keluar',
        (tester) async {
      await keTamu(tester);
      await tester.tap(find.text('Tim').first);
      await tester.pump(const Duration(milliseconds: 300));

      // Bukan layar kosong, bukan "izin diperlukan" tanpa tombol.
      expect(find.text('Timmu nyusul'), findsOneWidget);
      expect(find.text('Aktifkan lokasi'), findsOneWidget);
    });

    testWidgets('misi tetap kebuka penuh tanpa akun', (tester) async {
      await keTamu(tester);
      await tester.tap(find.text('Misi').first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Santai'), findsWidgets);
      expect(find.textContaining('Masuk buat'), findsNothing);
    });
  });
}
