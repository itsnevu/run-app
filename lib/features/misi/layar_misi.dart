import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../core/theme/rukun_motion.dart';
import '../../core/theme/rukun_spacing.dart';
import '../../core/theme/rukun_theme.dart';
import '../../core/theme/rukun_typography.dart';
import '../../core/util/bentuk.dart';
import '../../domain/model/misi.dart';
import '../../shared/widgets/daftar_rukun.dart';
import '../../shared/widgets/frosted_card.dart';
import '../../state/penyedia.dart';

/// Layar Misi — Lapis 3: ke mana hari ini?
///
/// Menghapus kelumpuhan "mau ngapain hari ini" yang muncul kalau peta cuma
/// berisi petak tanpa tujuan.
///
/// Penyaring tingkat sengaja menaruh **Santai** sejajar dengan yang lain,
/// bukan di bawahnya: jalur pemula adalah jalur penuh, bukan versi kecil.
class LayarMisi extends ConsumerStatefulWidget {
  const LayarMisi({super.key});

  @override
  ConsumerState<LayarMisi> createState() => _LayarMisiState();
}

class _LayarMisiState extends ConsumerState<LayarMisi> {
  TingkatMisi? _saring;

  @override
  Widget build(BuildContext context) {
    // Kemajuan dihitung dari sesi dan jejak yang benar-benar tercatat,
    // bukan angka statis yang bisa melenceng dari layar lain.
    final semua = ref.watch(misiProvider).valueOrNull ?? Misi.contoh;
    final daftar = _saring == null
        ? semua
        : semua.where((m) => m.tingkat == _saring).toList();

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
        const SizedBox(height: Jarak.xl),

        // Penyaring — satu baris, bisa digeser, tidak pernah membungkus.
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            children: [
              _Saringan(
                label: 'Semua',
                aktif: _saring == null,
                onTap: () => setState(() => _saring = null),
              ),
              for (final t in TingkatMisi.values)
                _Saringan(
                  label: t.label,
                  aktif: _saring == t,
                  onTap: () => setState(() => _saring = t),
                ),
            ],
          ),
        ),
        const SizedBox(height: Jarak.xl),

        if (daftar.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: Jarak.huge),
            child: KeadaanKosong(
              ikon: Icons.flag_outlined,
              judul: 'Belum ada misi di sini',
              pesan: 'Coba tingkat lain, atau balik lagi besok — '
                  'misi harian ganti tiap pagi.',
            ),
          )
        else
          for (final m in daftar)
            Padding(
              padding: const EdgeInsets.only(bottom: Jarak.antarKartu),
              child: _KartuMisi(misi: m),
            ),
      ],
    );
  }
}

/// Chip penyaring.
class _Saringan extends StatelessWidget {
  const _Saringan({
    required this.label,
    required this.aktif,
    required this.onTap,
  });

  final String label;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: Jarak.sm),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: Gerak.sigap,
          curve: Gerak.sigapKurva,
          padding: const EdgeInsets.symmetric(horizontal: Jarak.lg),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            gradient: aktif ? context.gradients.terang : null,
            color: aktif
                ? null
                : (context.modeGelap
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04)),
            shape: const StadiumBorder(),
          ),
          child: Text(
            label,
            style: RukunText.subhead.copyWith(
              color: aktif ? Colors.white : context.teksSekunder,
              fontWeight: aktif ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _KartuMisi extends StatelessWidget {
  const _KartuMisi({required this.misi});

  final Misi misi;

  /// Warna tingkat: santai memakai gradient tumbuh — hijau yang menenangkan,
  /// bukan abu-abu yang berarti "kelas dua".
  Gradient _gradient(BuildContext context) => switch (misi.tingkat) {
        TingkatMisi.santai => context.gradients.tumbuh,
        TingkatMisi.sedang => context.gradients.misi,
        TingkatMisi.menantang => context.gradients.fajar,
      };

  @override
  Widget build(BuildContext context) {
    final g = _gradient(context);
    final warna = g is LinearGradient ? g.colors.first : context.warna.primary;

    return KartuRukun(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: Bentuk.dekorasi(radius: Sudut.sm, gradient: g),
                child: Icon(
                  misi.selesai ? Icons.check_rounded : Icons.flag_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: Jarak.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(misi.judul,
                        style: RukunText.headline,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: Jarak.xs),
                    PilRukun(misi.tingkat.label, gradient: g, padat: true),
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
                    minHeight: 6,
                    backgroundColor: context.modeGelap
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation(warna),
                  ),
                ),
              ),
              const SizedBox(width: Jarak.md),
              Text(
                '${misi.kemajuan}/${misi.target}',
                style: RukunText.caption.copyWith(
                  color: context.teksSekunder,
                  fontWeight: FontWeight.w600,
                ),
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
