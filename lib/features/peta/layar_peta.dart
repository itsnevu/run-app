import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/rukun_colors.dart';
import '../../core/theme/rukun_spacing.dart';
import '../../core/theme/rukun_theme.dart';
import '../../core/theme/rukun_typography.dart';
import '../../domain/grid/grid_petak.dart';
import '../../domain/model/koordinat.dart';
import '../../shared/widgets/frosted_card.dart';
import '../../shared/widgets/petak_bar.dart';
import '../../state/penyedia.dart';
import 'peta_rukun.dart';

/// Layar Peta — rumah aplikasi. DESIGN.md §7.2
///
/// Peta layar penuh dengan antarmuka yang **mengambang, tidak pernah
/// menutup**. Peta adalah produknya; semua UI adalah lapisan tipis di atasnya.
class LayarPeta extends ConsumerWidget {
  const LayarPeta({super.key});

  static const _acuan = Koordinat(-6.2264, 106.8556);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posisi = ref.watch(posisiProvider).valueOrNull ?? _acuan;
    final jejak = ref.watch(jejakProvider).valueOrNull ?? const <IdPetak>{};
    final petakSekarang = ref.watch(petakSekarangProvider).valueOrNull;
    final kelurahan = ref.watch(kelurahanSayaProvider).valueOrNull;

    return Stack(
      children: [
        Positioned.fill(
          child: PetaRukun(
            pusat: posisi,
            jejak: jejak,
            wilayah: {
              if (kelurahan != null)
                for (final p in jejak) p: kelurahan.warna,
            },
          ),
        ),

        // Chip status di atas — angka tim, bukan angka pribadi.
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Jarak.lg),
            child: Align(
              alignment: Alignment.topLeft,
              child: KartuBuram(
                buram: Buram.tipis,
                radius: Sudut.penuh,
                padding: const EdgeInsets.symmetric(
                    horizontal: Jarak.lg, vertical: Jarak.sm),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (kelurahan != null) ...[
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: kelurahan.warna.gradient,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: Jarak.sm),
                      Text(
                        '${kelurahan.nama} '
                        '${kelurahan.persenWilayah.toStringAsFixed(0)}%',
                        style: RukunText.caption
                            .copyWith(color: context.warna.onSurface),
                      ),
                      const SizedBox(width: Jarak.sm),
                      Text(
                        '↑${kelurahan.selisihPersen.abs().toStringAsFixed(0)}%',
                        style: RukunText.caption.copyWith(
                          color: RukunColors.tumbuhA,
                        ),
                      ),
                    ] else
                      Text('Rukun', style: RukunText.caption),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Sheet bawah — petak tempat kamu berdiri.
        if (petakSekarang != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  Jarak.lg, 0, Jarak.lg, 110),
              child: _SheetPetak(petak: petakSekarang),
            ),
          ),
      ],
    );
  }
}

class _SheetPetak extends ConsumerWidget {
  const _SheetPetak({required this.petak});

  final IdPetak petak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(statusPetakProvider(petak));
    final kelurahan = ref.watch(kelurahanSayaProvider).valueOrNull;

    return status.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (hasil) {
        if (kelurahan == null) return const SizedBox.shrink();
        final pelintas = hasil.pelintasTim(kelurahan.id);

        return BilahPetak(
          namaPetak: 'Petak ${kelurahan.nama}',
          pelintas: pelintas,
          tim: kelurahan.warna,
          onAjak: () {},
        );
      },
    );
  }
}
