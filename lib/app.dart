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
      await kendali.selesai();
      return;
    }

    final berhasil = await kendali.mulai();
    if (!mounted || !berhasil) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LayarSesi(
          onSelesai: (jumlah) {
            Navigator.of(context).pop();
            _tampilkanRingkasan(jumlah);
          },
        ),
      ),
    );
  }

  void _tampilkanRingkasan(int jumlahPetak) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          jumlahPetak == 0
              ? 'Sesi tersimpan.'
              : 'Kamu buka $jumlahPetak petak. Jejakmu nambah.',
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
