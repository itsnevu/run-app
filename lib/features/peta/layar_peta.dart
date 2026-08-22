import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/rukun_colors.dart';
import '../../core/theme/rukun_spacing.dart';
import '../../core/theme/rukun_theme.dart';
import '../../core/theme/rukun_typography.dart';
import '../../domain/grid/grid_petak.dart';
import '../../domain/model/kelurahan.dart';
import '../../domain/model/koordinat.dart';
import '../../shared/pesan_izin.dart';
import '../../shared/widgets/bilah_tab.dart';
import '../../shared/widgets/frosted_card.dart';
import '../../shared/widgets/petak_bar.dart';
import '../../state/aksi_profil.dart';
import '../../state/penyedia.dart';
import 'peta_rukun.dart';

/// Layar Peta — rumah aplikasi. DESIGN.md §7.2
///
/// Peta layar penuh dengan antarmuka yang **mengambang, tidak pernah
/// menutup**. Peta adalah produknya; semua UI adalah lapisan tipis di atasnya.
///
/// Tanpa izin lokasi pun layar ini tetap hidup: peta tampil berkabut penuh di
/// titik acuan, dengan satu ajakan yang bisa diabaikan. Layar kosong dengan
/// tulisan "izin diperlukan" adalah jalan buntu, bukan antarmuka.
class LayarPeta extends ConsumerStatefulWidget {
  const LayarPeta({super.key});

  static const acuan = Koordinat(-6.2264, 106.8556);

  @override
  ConsumerState<LayarPeta> createState() => _LayarPetaState();
}

class _LayarPetaState extends ConsumerState<LayarPeta> {
  final _kendali = MapController();
  bool _sibuk = false;

  @override
  void dispose() {
    _kendali.dispose();
    super.dispose();
  }

  Future<void> _keLokasiku() async {
    setState(() => _sibuk = true);
    final izin = await ref.read(aksiProfilProvider).nyalakanLokasi();
    if (!mounted) return;

    if (izin.bolehMelacak) {
      final posisi = await ref.read(posisiProvider.future);
      if (!mounted) return;
      if (posisi != null) {
        _kendali.move(LatLng(posisi.lat, posisi.lng), 16);
      }
    } else {
      await tampilkanPesanIzin(context, ref.read(lokasiProvider), izin);
    }

    if (mounted) setState(() => _sibuk = false);
  }

  @override
  Widget build(BuildContext context) {
    final posisi = ref.watch(posisiProvider).valueOrNull ?? LayarPeta.acuan;
    final jejak = ref.watch(jejakProvider).valueOrNull ?? const <IdPetak>{};
    final petakSekarang = ref.watch(petakSekarangProvider).valueOrNull;
    final kelurahan = ref.watch(kelurahanSayaProvider).valueOrNull;
    final hangus =
        ref.watch(petakHangusProvider).valueOrNull ?? const <IdPetak>{};

    return Stack(
      children: [
        Positioned.fill(
          child: PetaRukun(
            pusat: posisi,
            kendali: _kendali,
            jejak: jejak,
            kabutPenuh: kelurahan == null && jejak.isEmpty,
            tampilkanTitikPengguna: kelurahan != null,
            wilayah: {
              if (kelurahan != null)
                for (final p in jejak) p: kelurahan.warna,
            },
            petakHangus: hangus,
          ),
        ),

        // Bilah atas mengambang: identitas tim di kiri, jejak pribadi di
        // kanan. Dua angka, dua kepemilikan — tidak pernah dicampur.
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Jarak.lg, vertical: Jarak.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: kelurahan == null
                      ? _PilAjakan(
                          sibuk: _sibuk,
                          onTap: _sibuk ? null : _keLokasiku,
                        )
                      : _PilTim(kelurahan: kelurahan),
                ),
                const Spacer(),
                if (jejak.isNotEmpty) _PilJejak(jumlah: jejak.length),
              ],
            ),
          ),
        ),

        // Tumpukan bawah: tombol "ke lokasiku" duduk di atas sheet, dan
        // keduanya berhenti tepat di atas bilah tab.
        //
        // Satu Column, bukan dua Positioned dengan angka ajaib: tinggi sheet
        // berubah menurut isinya (rantai pelintas bertambah, pesan memanjang),
        // jadi posisi yang dikunci ke angka pasti tertimbun cepat atau lambat.
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              Jarak.lg,
              0,
              Jarak.lg,
              MediaQuery.viewPaddingOf(context).bottom +
                  BilahTab.tinggi +
                  Jarak.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: _TombolBulat(
                    ikon: Icons.my_location_rounded,
                    aktif: !_sibuk,
                    onTap: _keLokasiku,
                  ),
                ),
                if (petakSekarang != null) ...[
                  const SizedBox(height: Jarak.md),
                  _SheetPetak(petak: petakSekarang),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Pil identitas tim: warna, nama, dan penguasaan wilayah.
class _PilTim extends StatelessWidget {
  const _PilTim({required this.kelurahan});

  final Kelurahan kelurahan;

  @override
  Widget build(BuildContext context) {
    final naik = kelurahan.selisihPersen >= 0;

    return KartuBuram(
      buram: Buram.tipis,
      radius: Sudut.penuh,
      padding: const EdgeInsets.symmetric(
          horizontal: Jarak.lg, vertical: Jarak.sm + 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              gradient: kelurahan.warna.gradient,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: Jarak.sm),
          Flexible(
            child: Text(
              kelurahan.nama,
              overflow: TextOverflow.ellipsis,
              style: RukunText.caption.copyWith(
                color: context.warna.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: Jarak.sm),
          Text(
            '${kelurahan.persenWilayah.toStringAsFixed(0)}%',
            style: RukunText.caption.copyWith(color: context.teksSekunder),
          ),
          const SizedBox(width: Jarak.xs),
          Icon(
            naik ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 12,
            color: naik ? RukunColors.tumbuhA : context.teksTersier,
          ),
          Text(
            kelurahan.selisihPersen.abs().toStringAsFixed(0),
            style: RukunText.caption.copyWith(
              color: naik ? RukunColors.tumbuhA : context.teksTersier,
            ),
          ),
        ],
      ),
    );
  }
}

/// Jumlah petak pribadi yang sudah terbuka.
class _PilJejak extends StatelessWidget {
  const _PilJejak({required this.jumlah});

  final int jumlah;

  @override
  Widget build(BuildContext context) {
    return KartuBuram(
      buram: Buram.tipis,
      radius: Sudut.penuh,
      padding: const EdgeInsets.symmetric(
          horizontal: Jarak.md, vertical: Jarak.sm + 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hexagon_outlined,
              size: 13, color: context.gradients.fajar.colors.first),
          const SizedBox(width: Jarak.xs),
          Text(
            '$jumlah',
            style: RukunText.caption.copyWith(
              color: context.warna.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ajakan menyalakan lokasi — sebuah pil, bukan sebuah dinding.
class _PilAjakan extends StatelessWidget {
  const _PilAjakan({required this.sibuk, this.onTap});

  final bool sibuk;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: KartuBuram(
        buram: Buram.tipis,
        radius: Sudut.penuh,
        padding: const EdgeInsets.symmetric(
            horizontal: Jarak.lg, vertical: Jarak.sm + 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.my_location_rounded,
                size: 13, color: context.gradients.terang.colors.first),
            const SizedBox(width: Jarak.sm),
            Flexible(
              child: Text(
                sibuk ? 'Sebentar...' : 'Nyalakan lokasi',
                overflow: TextOverflow.ellipsis,
                style: RukunText.caption.copyWith(
                  color: context.warna.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol bundar mengambang di atas peta.
class _TombolBulat extends StatelessWidget {
  const _TombolBulat({
    required this.ikon,
    required this.onTap,
    this.aktif = true,
  });

  final IconData ikon;
  final VoidCallback onTap;
  final bool aktif;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ke lokasiku',
      child: GestureDetector(
        onTap: aktif ? onTap : null,
        child: Opacity(
          opacity: aktif ? 1 : 0.5,
          child: KartuBuram(
            buram: Buram.tebal,
            radius: Sudut.penuh,
            padding: const EdgeInsets.all(Jarak.md),
            child: Icon(ikon, size: 22, color: context.warna.onSurface),
          ),
        ),
      ),
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
