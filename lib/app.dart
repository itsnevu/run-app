import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/rukun_theme.dart';
import 'features/aku/layar_aku.dart';
import 'features/misi/layar_misi.dart';
import 'features/onboarding/layar_onboarding.dart';
import 'features/peta/layar_peta.dart';
import 'features/sesi/layar_sesi.dart';
import 'features/tim/layar_tim.dart';
import 'shared/widgets/bilah_tab.dart';
import 'shared/widgets/perayaan_klaim.dart';
import 'state/kendali_sesi.dart';
import 'state/penyedia.dart';

class AplikasiRukun extends StatelessWidget {
  const AplikasiRukun({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rukun',
      debugShowCheckedModeBanner: false,
      theme: RukunTheme.terang,
      darkTheme: RukunTheme.gelap,
      // Mode gelap bukan renungan belakangan — metafora kabut justru lebih
      // bagus dalam gelap, dan sesi subuh/malam nyata di Indonesia.
      themeMode: ThemeMode.system,
      home: const GerbangRukun(),
    );
  }
}

/// Menentukan apakah pengguna perlu onboarding atau langsung ke peta.
class GerbangRukun extends ConsumerWidget {
  const GerbangRukun({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(profilProvider);

    return profil.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (p) => p == null
          ? LayarOnboarding(onSelesai: () => ref.invalidate(profilProvider))
          : const CangkangRukun(),
    );
  }
}

/// Cangkang utama dengan bilah tab mengambang.
class CangkangRukun extends ConsumerStatefulWidget {
  const CangkangRukun({super.key});

  @override
  ConsumerState<CangkangRukun> createState() => _CangkangRukunState();
}

class _CangkangRukunState extends ConsumerState<CangkangRukun> {
  int _tab = 0;

  static const _layar = [
    LayarPeta(),
    LayarTim(),
    LayarMisi(),
    LayarAku(),
  ];

  Future<void> _tekanRekam() async {
    final kendali = ref.read(kendaliSesiProvider.notifier);
    final status = ref.read(kendaliSesiProvider);

    if (status.merekam) {
      final hasil = await kendali.selesai();
      if (hasil != null) await _tampilkanHasil(hasil);
      return;
    }

    final berhasil = await kendali.mulai();
    if (!mounted || !berhasil) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LayarSesi(
          onSelesaiSesi: (hasil) async {
            Navigator.of(context).pop();
            await _tampilkanHasil(hasil);
          },
        ),
      ),
    );
  }

  /// Perayaan didahulukan sebelum ringkasan — momen "kamu yang melengkapi"
  /// adalah yang paling berharga, jangan sampai tertutup notifikasi biasa.
  Future<void> _tampilkanHasil(HasilSesi hasil) async {
    if (!mounted) return;

    if (hasil.baruTerklaim.isNotEmpty) {
      final kelurahan = ref.read(kelurahanSayaProvider).valueOrNull;
      if (kelurahan != null) {
        final pertama = hasil.baruTerklaim.first;
        await PerayaanKlaim.tampilkan(
          context,
          namaPetak: 'Petak ${kelurahan.nama}',
          namaTim: kelurahan.nama,
          warna: kelurahan.warna,
          pelintas: pertama.pelintas,
        );
        if (!mounted) return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hasil.petakDibuka == 0
              ? 'Sesi tersimpan.'
              : 'Kamu buka ${hasil.petakDibuka} petak. Jejakmu nambah.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final merekam = ref.watch(kendaliSesiProvider).merekam;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _tab, children: _layar),
      bottomNavigationBar: BilahTab(
        terpilih: _tab,
        onPilih: (i) => setState(() => _tab = i),
        onRekam: _tekanRekam,
        sedangMerekam: merekam,
      ),
    );
  }
}
