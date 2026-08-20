import 'package:flutter/material.dart';

import '../../core/theme/rukun_spacing.dart';
import '../../core/theme/rukun_theme.dart';
import '../../core/theme/rukun_typography.dart';
import '../../core/util/bentuk.dart';
import '../../domain/model/misi.dart';
import '../../shared/widgets/frosted_card.dart';

/// Layar Misi — Lapis 3: ke mana hari ini?
///
/// Menghapus kelumpuhan "mau ngapain hari ini" yang muncul kalau peta cuma
/// berisi petak tanpa tujuan.
class LayarMisi extends StatelessWidget {
  const LayarMisi({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          Jarak.tepiLayar, Jarak.lg, Jarak.tepiLayar, 120),
      children: [
        Text('Misi', style: RukunText.judul1),
        const SizedBox(height: Jarak.xs),
        Text(
          'Alasan buat keluar rumah hari ini.',
          style: RukunText.subhead.copyWith(color: context.teksSekunder),
        ),
        const SizedBox(height: Jarak.antarBagian),
        for (final m in Misi.contoh)
          Padding(
            padding: const EdgeInsets.only(bottom: Jarak.antarKartu),
            child: _KartuMisi(misi: m),
          ),
      ],
    );
  }
}

class _KartuMisi extends StatelessWidget {
  const _KartuMisi({required this.misi});

  final Misi misi;

  @override
  Widget build(BuildContext context) {
    final g = context.gradients;

    return KartuRukun(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: Bentuk.dekorasi(radius: Sudut.sm, gradient: g.misi),
                child: const Icon(Icons.flag_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: Jarak.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(misi.judul,
                        style: RukunText.headline,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      misi.tingkat.label,
                      style: RukunText.caption
                          .copyWith(color: context.teksTersier),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Jarak.lg),
          Text(
            misi.keterangan,
            style: RukunText.subhead.copyWith(color: context.teksSekunder),
          ),
          const SizedBox(height: Jarak.lg),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Sudut.penuh),
                  child: LinearProgressIndicator(
                    value: misi.rasio,
                    minHeight: 8,
                    backgroundColor: context.modeGelap
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation(g.misi.colors.first),
                  ),
                ),
              ),
              const SizedBox(width: Jarak.md),
              Text(
                '${misi.kemajuan}/${misi.target}',
                style: RukunText.caption.copyWith(color: context.teksSekunder),
              ),
            ],
          ),
          if (misi.bersponsor) ...[
            const SizedBox(height: Jarak.md),
            // Sponsor selalu diungkap terang-terangan.
            Row(
              children: [
                Icon(Icons.storefront_rounded,
                    size: 14, color: context.teksTersier),
                const SizedBox(width: Jarak.xs),
                Flexible(
                  child: Text(
                    'Disponsori ${misi.disponsoriOleh}',
                    overflow: TextOverflow.ellipsis,
                    style: RukunText.caption
                        .copyWith(color: context.teksTersier),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
