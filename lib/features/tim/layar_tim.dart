import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/rukun_spacing.dart';
import '../../core/theme/rukun_theme.dart';
import '../../core/theme/rukun_typography.dart';
import '../../core/util/bentuk.dart';
import '../../core/theme/rukun_colors.dart';
import '../../domain/model/kelurahan.dart';
import '../../shared/widgets/frosted_card.dart';
import '../../state/penyedia.dart';

/// Layar Tim. DESIGN.md §7.5
///
/// Daftar kontribusi **di dalam tim** — ini suportif, mereka tetangga.
/// Diurutkan berdasarkan **menit bergerak**, bukan jarak, sehingga pejalan
/// kaki dan pelari bercampur secara alami.
///
/// Tidak ada peringkat melawan orang asing. Selamanya.
class LayarTim extends ConsumerWidget {
  const LayarTim({super.key});

  /// Kontribusi tetangga — menit bergerak, bukan kecepatan.
  static const _kontribusi = [
    ('Bu Sari', 214),
    ('Pak Budi', 186),
    ('Rina', 152),
    ('Kamu', 138),
    ('Andi', 121),
    ('Dewi', 96),
    ('Eko', 74),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kelurahan = ref.watch(kelurahanSayaProvider);
    final semua = ref.watch(semuaKelurahanProvider);

    return kelurahan.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (k) {
        if (k == null) return const SizedBox.shrink();
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              Jarak.tepiLayar, Jarak.lg, Jarak.tepiLayar, 120),
          children: [
            _Kepala(kelurahan: k),
            const SizedBox(height: Jarak.antarBagian),
            Text('Yang bergerak minggu ini', style: RukunText.judul3),
            const SizedBox(height: Jarak.xs),
            Text(
              'Diurutkan dari menit bergerak — jalan dan lari dihitung sama.',
              style: RukunText.footnote.copyWith(color: context.teksTersier),
            ),
            const SizedBox(height: Jarak.lg),
            KartuRukun(
              padding: const EdgeInsets.symmetric(vertical: Jarak.sm),
              child: Column(
                children: [
                  for (final (nama, menit) in _kontribusi)
                    _Baris(
                      nama: nama,
                      menit: menit,
                      maks: _kontribusi.first.$2,
                      warna: k.warna,
                      kamu: nama == 'Kamu',
                    ),
                ],
              ),
            ),
            const SizedBox(height: Jarak.antarBagian),
            Text('Kelurahan lain', style: RukunText.judul3),
            const SizedBox(height: Jarak.lg),
            semua.maybeWhen(
              data: (daftar) => Column(
                children: [
                  for (final lain in daftar.where((x) => x.id != k.id))
                    Padding(
                      padding: const EdgeInsets.only(bottom: Jarak.antarKartu),
                      child: _BarisKelurahan(kelurahan: lain),
                    ),
                ],
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}

class _Kepala extends StatelessWidget {
  const _Kepala({required this.kelurahan});

  final Kelurahan kelurahan;

  @override
  Widget build(BuildContext context) {
    final naik = kelurahan.selisihPersen >= 0;

    return Container(
      padding: const EdgeInsets.all(Jarak.xxl),
      decoration: Bentuk.dekorasi(
        radius: Sudut.xl,
        gradient: kelurahan.warna.gradient,
        bayangan: Elevasi.pendar(kelurahan.warna.a),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kelurahan ${kelurahan.nama}',
            style: RukunText.headline.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: Jarak.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                kelurahan.persenWilayah.toStringAsFixed(0),
                style: RukunText.angkaBesar.copyWith(color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('%',
                    style: RukunText.judul2.copyWith(color: Colors.white)),
              ),
              const SizedBox(width: Jarak.md),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      naik
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    Text(
                      '${kelurahan.selisihPersen.abs().toStringAsFixed(0)}%',
                      style: RukunText.footnote.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            'wilayah dikuasai',
            style: RukunText.subhead.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: Jarak.xl),
          // Angka absolut, bukan peringkat.
          Text(
            '${kelurahan.jumlahAnggota} warga bergerak minggu ini',
            style: RukunText.subhead.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _Baris extends StatelessWidget {
  const _Baris({
    required this.nama,
    required this.menit,
    required this.maks,
    required this.warna,
    required this.kamu,
  });

  final String nama;
  final int menit;
  final int maks;
  final TimWarna warna;
  final bool kamu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Jarak.lg, vertical: Jarak.md),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              nama,
              overflow: TextOverflow.ellipsis,
              style: RukunText.subhead.copyWith(
                color: context.warna.onSurface,
                fontWeight: kamu ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Sudut.penuh),
              child: LinearProgressIndicator(
                value: menit / maks,
                minHeight: 8,
                backgroundColor: context.modeGelap
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation(warna.a),
              ),
            ),
          ),
          const SizedBox(width: Jarak.md),
          SizedBox(
            width: 56,
            child: Text(
              '$menit mnt',
              textAlign: TextAlign.right,
              style: RukunText.caption.copyWith(color: context.teksSekunder),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarisKelurahan extends StatelessWidget {
  const _BarisKelurahan({required this.kelurahan});

  final Kelurahan kelurahan;

  @override
  Widget build(BuildContext context) {
    return KartuRukun(
      padding: const EdgeInsets.all(Jarak.lg),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: Bentuk.dekorasi(
              radius: Sudut.sm,
              gradient: kelurahan.warna.gradient,
            ),
          ),
          const SizedBox(width: Jarak.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kelurahan.nama, style: RukunText.headline),
                Text(
                  '${kelurahan.jumlahAnggota} warga',
                  style:
                      RukunText.caption.copyWith(color: context.teksSekunder),
                ),
              ],
            ),
          ),
          Text(
            '${kelurahan.persenWilayah.toStringAsFixed(0)}%',
            style: RukunText.judul3.copyWith(color: context.warna.onSurface),
          ),
        ],
      ),
    );
  }
}
