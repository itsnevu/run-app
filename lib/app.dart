import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/rukun_theme.dart';
import 'features/aku/layar_aku.dart';
import 'features/misi/layar_misi.dart';
import 'features/onboarding/layar_onboarding.dart';
import 'features/peta/layar_peta.dart';
import 'features/sesi/layar_ringkasan.dart';
import 'features/sesi/layar_sesi.dart';
import 'features/tim/layar_tim.dart';
import 'data/lokasi.dart';
import 'shared/pesan_izin.dart';
import 'shared/widgets/bilah_tab.dart';
import 'shared/widgets/perayaan_klaim.dart';
import 'state/aksi_profil.dart';
import 'state/kendali_sesi.dart';
import 'data/notifikasi.dart';
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

/// Menentukan apakah pengguna perlu pembuka atau langsung ke peta.
///
/// **Tidak ada layar masuk di sini, dan itu disengaja.** Aplikasi terbuka
/// langsung ke isinya; akun ditawarkan belakangan lewat tab Aku, hanya kalau
/// pengguna sendiri yang mau. Selain lebih sopan, ini syarat App Store
/// §5.1.1(v) — memaksa pendaftaran di detik pertama adalah alasan penolakan
/// yang paling sering terjadi.
///
/// Yang menentukan hanya satu hal: apakah pembuka sudah pernah dilewati.
/// Sengaja bukan "apakah profil sudah ada" — profil bisa lahir di tengah
/// pembuka (begitu lokasi diberikan), dan gerbang yang mengintip profil akan
/// melempar pengguna keluar tepat di tengah kalimat.
class GerbangRukun extends ConsumerWidget {
  const GerbangRukun({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(pembukaSelesaiProvider)) return const CangkangRukun();

    return LayarOnboarding(
      onSelesai: () {
        ref.invalidate(profilProvider);
        ref.invalidate(kelurahanSayaProvider);
      },
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

    // Pengguna yang menunda lokasi di pembuka belum punya kelurahan. Diminta
    // di sini, bukan di tempat lain, supaya sesi pertamanya langsung tercatat
    // untuk sebuah tim — bukan jadi jejak yatim yang nanti tidak bisa naik ke
    // server karena barisnya butuh kelurahan.
    final kelurahan = await ref.read(kelurahanSayaProvider.future);
    if (!mounted) return;

    if (kelurahan == null) {
      final izin = await ref.read(aksiProfilProvider).nyalakanLokasi();
      if (!mounted) return;
      if (!izin.bolehMelacak) {
        await tampilkanPesanIzin(context, ref.read(lokasiProvider), izin);
        return;
      }
    }

    final berhasil = await kendali.mulai();
    if (!mounted) return;

    // Tombol utama aplikasi tidak boleh diam saat ditolak. Sebelum ini
    // `mulai()` mengembalikan false dan layar tidak berubah sedikit pun —
    // di iOS, penolakan pertama membuat dialog sistem tidak pernah muncul
    // lagi, jadi tombol Rekam mati permanen tanpa satu pun penjelasan.
    if (!berhasil) {
      await tampilkanPesanIzin(
        context,
        ref.read(lokasiProvider),
        ref.read(kendaliSesiProvider).izin ?? StatusIzin.ditolak,
      );
      return;
    }

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

    if (hasil.petakDibuka == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi tersimpan.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LayarRingkasan(hasil: hasil)),
    );

    await _jadwalkanPengingat();
  }

  /// Menjadwalkan satu pengingat untuk besok.
  ///
  /// Izin diminta **setelah sesi pertama selesai**, bukan saat aplikasi
  /// pertama dibuka: pada titik ini pengguna sudah tahu apa gunanya, jadi
  /// permintaannya masuk akal dan lebih mungkin diterima. Meminta di layar
  /// pembuka adalah cara tercepat mendapat penolakan permanen.
  Future<void> _jadwalkanPengingat() async {
    final notif = ref.read(notifikasiProvider);
    if (!await notif.mintaIzin()) return;

    final hangus = ref.read(petakHangusProvider).valueOrNull ?? const {};
    final kelurahan = ref.read(kelurahanSayaProvider).valueOrNull;

    final pesan = PesanHarian.susun(
      petakHangus: hangus.length,
      namaKelurahan: kelurahan?.nama ?? 'kelurahanmu',
    );

    // Jam 16.30 — sore, sebelum gelap, saat jalan kaki paling masuk akal
    // di kota Indonesia.
    await notif.jadwalkanHarian(
      jam: 16,
      menit: 30,
      judul: pesan.judul,
      isi: pesan.isi,
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
