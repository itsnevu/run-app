import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/rukun_spacing.dart';
import '../../core/theme/rukun_theme.dart';
import '../../core/theme/rukun_typography.dart';
import '../../core/util/bentuk.dart';
import '../../domain/aturan/aturan_klaim.dart';
import '../../domain/model/koordinat.dart';
import '../../shared/widgets/frosted_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../state/kendali_sesi.dart';
import '../../state/penyedia.dart';
import '../peta/peta_rukun.dart';

/// Ringkasan sesi. DESIGN.md §7.4
///
/// Aturan yang ditegakkan di layar ini:
/// - Statistik pribadi **tersembunyi di balik ketukan** — ada untuk yang mau,
///   tak terlihat untuk yang tidak.
/// - Berbagi hanya membagikan peta, **tanpa satu pun angka performa**.
/// - Yang ditonjolkan adalah petak yang tinggal butuh satu orang lagi:
///   ajakan, bukan pencapaian.
class LayarRingkasan extends ConsumerStatefulWidget {
  const LayarRingkasan({super.key, required this.hasil});

  final HasilSesi hasil;

  @override
  ConsumerState<LayarRingkasan> createState() => _LayarRingkasanState();
}

class _LayarRingkasanState extends ConsumerState<LayarRingkasan> {
  bool _detailTerbuka = false;

  static const _acuan = Koordinat(-6.2264, 106.8556);

  @override
  Widget build(BuildContext context) {
    final hasil = widget.hasil;
    final sesi = hasil.sesi;
    final kelurahan = ref.watch(kelurahanSayaProvider).valueOrNull;
    final posisi = sesi.titik.isNotEmpty
        ? sesi.titik.first.koordinat
        : (ref.watch(posisiProvider).valueOrNull ?? _acuan);
    final g = context.gradients;

    final petak = ref.watch(gridProvider);
    final petakSesi = sesi.petakDilewati(petak);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Jarak.tepiLayar),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Sesi selesai', style: RukunText.judul1),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: Jarak.xl),

                  // Kartu perayaan — petak yang terbuka, bukan kecepatan.
                  Container(
                    padding: const EdgeInsets.all(Jarak.xxl),
                    decoration: Bentuk.dekorasi(
                      radius: Sudut.xl,
                      gradient: g.fajar,
                      bayangan: Elevasi.pendar(g.fajar.colors.first),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${hasil.petakDibuka}',
                              style: RukunText.angkaBesar
                                  .copyWith(color: Colors.white),
                            ),
                            const SizedBox(width: Jarak.sm),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text('petak terbuka',
                                  style: RukunText.judul3
                                      .copyWith(color: Colors.white)),
                            ),
                          ],
                        ),
                        const SizedBox(height: Jarak.sm),
                        Text(
                          'Jejakmu nambah. Petak ini milik kamu selamanya.',
                          style: RukunText.subhead.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Jarak.antarKartu),

                  // Peta rute dengan petak yang baru terbuka.
                  SizedBox(
                    height: 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Sudut.lg),
                      child: PetaRukun(
                        pusat: posisi,
                        jejak: petakSesi,
                        wilayah: {
                          if (kelurahan != null)
                            for (final p in petakSesi) p: kelurahan.warna,
                        },
                        zoom: 15,
                        tampilkanTitikPengguna: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: Jarak.antarKartu),

                  // Ajakan, bukan pencapaian.
                  if (hasil.baruTerklaim.isNotEmpty)
                    _Ajakan(
                      teks: '${hasil.baruTerklaim.length} petak jadi milik '
                          '${kelurahan?.nama ?? "kelurahanmu"} berkat kamu.',
                      ikon: Icons.celebration_rounded,
                    )
                  else
                    _Ajakan(
                      teks: 'Beberapa petak tinggal butuh '
                          '${AturanKlaim.orangDibutuhkan - 1} orang lagi. '
                          'Ajak tetangga jalan bareng?',
                      ikon: Icons.group_add_rounded,
                    ),
                  const SizedBox(height: Jarak.antarBagian),

                  // Statistik pribadi — tersembunyi di balik ketukan.
                  GestureDetector(
                    onTap: () =>
                        setState(() => _detailTerbuka = !_detailTerbuka),
                    child: Row(
                      children: [
                        Text(
                          _detailTerbuka ? 'Sembunyikan' : 'Lihat detail',
                          style: RukunText.subhead
                              .copyWith(color: context.teksSekunder),
                        ),
                        Icon(
                          _detailTerbuka
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 20,
                          color: context.teksSekunder,
                        ),
                        const Spacer(),
                        Icon(Icons.lock_outline_rounded,
                            size: 14, color: context.teksTersier),
                        const SizedBox(width: Jarak.xs),
                        Text('privat',
                            style: RukunText.caption
                                .copyWith(color: context.teksTersier)),
                      ],
                    ),
                  ),
                  if (_detailTerbuka) ...[
                    const SizedBox(height: Jarak.lg),
                    KartuRukun(
                      child: Column(
                        children: [
                          _Baris('Waktu bergerak',
                              '${sesi.menitBergerak} menit'),
                          const SizedBox(height: Jarak.md),
                          _Baris('Jarak',
                              '${(sesi.jarakMeter / 1000).toStringAsFixed(2)} km'),
                          const SizedBox(height: Jarak.md),
                          _Baris('Moda', sesi.modaDominan.label),
                        ],
                      ),
                    ),
                    const SizedBox(height: Jarak.md),
                    Text(
                      'Angka ini cuma buat kamu. Nggak pernah muncul di mana '
                      'pun yang bisa dilihat orang lain.',
                      style: RukunText.footnote
                          .copyWith(color: context.teksTersier),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Jarak.tepiLayar),
              child: TombolRukun(
                label: 'Selesai',
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ajakan extends StatelessWidget {
  const _Ajakan({required this.teks, required this.ikon});

  final String teks;
  final IconData ikon;

  @override
  Widget build(BuildContext context) {
    return KartuRukun(
      child: Row(
        children: [
          Icon(ikon, size: 24, color: context.teksSekunder),
          const SizedBox(width: Jarak.lg),
          Expanded(
            child: Text(
              teks,
              style: RukunText.subhead
                  .copyWith(color: context.warna.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _Baris extends StatelessWidget {
  const _Baris(this.label, this.nilai);

  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: RukunText.subhead.copyWith(color: context.teksSekunder)),
        const Spacer(),
        Text(nilai,
            style: RukunText.headline
                .copyWith(color: context.warna.onSurface)),
      ],
    );
  }
}
