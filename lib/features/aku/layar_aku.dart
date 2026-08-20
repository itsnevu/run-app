import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/rukun_spacing.dart';
import '../../core/theme/rukun_theme.dart';
import '../../core/theme/rukun_typography.dart';
import '../../shared/widgets/frosted_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../domain/aturan/zona_privat.dart';
import '../../state/penyedia.dart';

/// Layar Aku. DESIGN.md §7.6
///
/// Peta Jejak pribadi — dibuka permanen, tidak pernah reset, bahkan antar
/// musim. Statistik pribadi lengkap ada di sini dan **privat secara default**.
class LayarAku extends ConsumerWidget {
  const LayarAku({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(profilProvider);
    final jejak = ref.watch(jejakProvider);
    final hariAktif = ref.watch(hariAktifProvider);
    final kelurahan = ref.watch(kelurahanSayaProvider);
    final g = context.gradients;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          Jarak.tepiLayar, Jarak.lg, Jarak.tepiLayar, 120),
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: g.fajar,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  profil.valueOrNull?.huruf ?? '?',
                  style: RukunText.judul2.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: Jarak.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profil.valueOrNull?.nama ?? 'Kamu',
                      style: RukunText.judul2, overflow: TextOverflow.ellipsis),
                  Text(
                    kelurahan.valueOrNull == null
                        ? '—'
                        : 'Kelurahan ${kelurahan.valueOrNull!.nama}',
                    style: RukunText.subhead
                        .copyWith(color: context.teksSekunder),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Jarak.antarBagian),

        // Satu-satunya angka yang publik: kehadiran.
        KartuRukun(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.public_rounded, size: 16, color: context.teksTersier),
                  const SizedBox(width: Jarak.xs),
                  Text('Terlihat tetangga',
                      style: RukunText.caption
                          .copyWith(color: context.teksTersier)),
                ],
              ),
              const SizedBox(height: Jarak.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TeksGradient(
                    '${hariAktif.valueOrNull ?? 0}',
                    gradient: g.tumbuh,
                    style: RukunText.angkaBesar,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(' dari 7 hari',
                        style: RukunText.judul3
                            .copyWith(color: context.teksSekunder)),
                  ),
                ],
              ),
              const SizedBox(height: Jarak.sm),
              Text(
                'Konsistensi — satu-satunya angka yang dilihat orang lain.',
                style: RukunText.footnote.copyWith(color: context.teksTersier),
              ),
            ],
          ),
        ),
        const SizedBox(height: Jarak.antarKartu),

        // Jejak pribadi — permanen.
        KartuRukun(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 16, color: context.teksTersier),
                  const SizedBox(width: Jarak.xs),
                  Text('Privat — cuma kamu',
                      style: RukunText.caption
                          .copyWith(color: context.teksTersier)),
                ],
              ),
              const SizedBox(height: Jarak.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TeksGradient(
                    '${jejak.valueOrNull?.length ?? 0}',
                    gradient: g.fajar,
                    style: RukunText.angkaBesar,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(' petak dibuka',
                        style: RukunText.judul3
                            .copyWith(color: context.teksSekunder)),
                  ),
                ],
              ),
              const SizedBox(height: Jarak.sm),
              Text(
                'Jejakmu nggak pernah reset. Nggak bisa direbut siapa pun, '
                'bahkan waktu musim berganti.',
                style: RukunText.footnote.copyWith(color: context.teksTersier),
              ),
            ],
          ),
        ),
        const SizedBox(height: Jarak.antarBagian),

        Text('Privasi', style: RukunText.judul3),
        const SizedBox(height: Jarak.lg),
        KartuRukun(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Poin(
                ikon: Icons.speed_rounded,
                judul: 'Kecepatan & pace disembunyikan',
                isi: 'Nggak pernah muncul di mana pun yang bisa dilihat '
                    'orang lain. Ini keputusan produk, bukan pengaturan.',
              ),
              const SizedBox(height: Jarak.lg),
              _Poin(
                ikon: Icons.home_outlined,
                judul: 'Radius buta 150 m di sekitar rumah',
                isi: 'Petak dekat rumah nggak pernah jadi klaim dan nggak '
                    'pernah keluar dari HP kamu.',
              ),
              const SizedBox(height: Jarak.lg),
              _ZonaPrivat(zona: ref.watch(zonaPrivatProvider)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Daftar zona privat yang aktif.
///
/// Dibuat otomatis setelah sesi pertama — pengguna tidak perlu menemukannya
/// dulu. Yang ditampilkan di sini adalah bukti bahwa ia menyala, plus jalan
/// keluar bila pengguna memang ingin mematikannya.
class _ZonaPrivat extends ConsumerWidget {
  const _ZonaPrivat({required this.zona});

  final AsyncValue<List<ZonaPrivat>> zona;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daftar = zona.valueOrNull ?? const <ZonaPrivat>[];

    if (daftar.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(Jarak.lg),
        decoration: BoxDecoration(
          color: context.modeGelap
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(Sudut.sm),
        ),
        child: Text(
          'Belum ada zona privat. Satu akan dibuat otomatis di titik awal '
          'sesi pertamamu.',
          style: RukunText.footnote.copyWith(color: context.teksSekunder),
        ),
      );
    }

    return Column(
      children: [
        for (final z in daftar)
          Container(
            margin: const EdgeInsets.only(bottom: Jarak.sm),
            padding: const EdgeInsets.all(Jarak.lg),
            decoration: BoxDecoration(
              color: context.modeGelap
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(Sudut.sm),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined,
                    size: 20, color: context.gradients.tumbuh.colors.first),
                const SizedBox(width: Jarak.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(z.label ?? 'Zona privat',
                          style: RukunText.subhead.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.warna.onSurface,
                          )),
                      Text(
                        'Aktif · radius ${z.radiusMeter.toStringAsFixed(0)} m',
                        style: RukunText.caption
                            .copyWith(color: context.teksSekunder),
                      ),
                    ],
                  ),
                ),
                TombolRukun(
                  label: 'Hapus',
                  varian: VarianTombol.hantu,
                  penuh: false,
                  padat: true,
                  onTap: () async {
                    final sisa = daftar.where((x) => x != z).toList();
                    await ref.read(repoProvider).simpanZonaPrivat(sisa);
                    ref.invalidate(zonaPrivatProvider);
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Poin extends StatelessWidget {
  const _Poin({required this.ikon, required this.judul, required this.isi});

  final IconData ikon;
  final String judul;
  final String isi;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(ikon, size: 20, color: context.teksSekunder),
        const SizedBox(width: Jarak.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(judul, style: RukunText.subhead.copyWith(
                fontWeight: FontWeight.w600,
                color: context.warna.onSurface,
              )),
              const SizedBox(height: 2),
              Text(isi,
                  style: RukunText.footnote
                      .copyWith(color: context.teksSekunder)),
            ],
          ),
        ),
      ],
    );
  }
}
