import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/rukun_colors.dart';
import '../../core/theme/rukun_spacing.dart';
import '../../core/theme/rukun_theme.dart';
import '../../core/theme/rukun_typography.dart';
import '../../core/util/bentuk.dart';
import '../../data/lokasi.dart';
import '../../domain/model/kelurahan.dart';
import '../../shared/widgets/daftar_rukun.dart';
import '../../shared/widgets/frosted_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../state/aksi_profil.dart';
import '../../state/penyedia.dart';

/// Layar Tim. DESIGN.md §7.5
///
/// Daftar kontribusi **di dalam tim** — ini suportif, mereka tetangga.
/// Diurutkan berdasarkan **menit bergerak**, bukan jarak, sehingga pejalan
/// kaki dan pelari bercampur secara alami.
///
/// Tidak ada peringkat melawan orang asing. Selamanya.
class LayarTim extends ConsumerStatefulWidget {
  const LayarTim({super.key});

  @override
  ConsumerState<LayarTim> createState() => _LayarTimState();
}

class _LayarTimState extends ConsumerState<LayarTim> {
  bool _sibuk = false;

  Future<void> _nyalakanLokasi() async {
    setState(() => _sibuk = true);
    final izin = await ref.read(aksiProfilProvider).nyalakanLokasi();
    if (!mounted) return;
    setState(() => _sibuk = false);
    if (izin.bolehMelacak) return;

    final pesan = switch (izin) {
      StatusIzin.layananMati => 'Layanan lokasi di HP kamu lagi mati.',
      StatusIzin.ditolakPermanen =>
        'Izin lokasinya perlu dinyalakan lewat Pengaturan.',
      _ => 'Belum diizinkan. Nggak apa-apa, bisa kapan-kapan.',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kelurahan = ref.watch(kelurahanSayaProvider);
    final semua = ref.watch(semuaKelurahanProvider);
    final kontribusi = ref.watch(kontribusiTimProvider);

    return kelurahan.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => KeadaanKosong(
        ikon: Icons.cloud_off_rounded,
        judul: 'Data tim belum kebaca',
        pesan: 'Coba buka lagi sebentar lagi ya.',
      ),
      data: (k) {
        if (k == null) {
          // Tanpa kelurahan, layar ini tidak punya isi — tapi tetap tidak
          // boleh jadi jalan buntu.
          return KeadaanKosong(
            ikon: Icons.groups_outlined,
            judul: 'Timmu nyusul',
            pesan: 'Kelurahanmu ketahuan dari lokasi. Nyalakan sekarang, '
                'atau nanti waktu kamu siap.',
            aksi: TombolRukun(
              label: _sibuk ? 'Sebentar...' : 'Aktifkan lokasi',
              penuh: false,
              padat: true,
              onTap: _sibuk ? null : _nyalakanLokasi,
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(
              Jarak.tepiLayar, Jarak.lg, Jarak.tepiLayar, 120),
          children: [
            _Kepala(kelurahan: k),
            const SizedBox(height: Jarak.antarBagian),
            const JudulBagian(
              'Yang bergerak minggu ini',
              keterangan: 'Diurutkan dari menit bergerak — '
                  'jalan dan lari dihitung sama.',
            ),
            kontribusi.when(
              loading: () => const KartuRukun(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => KartuRukun(child: Text('$e')),
              data: (daftar) {
                if (daftar.isEmpty) {
                  return KartuRukun(
                    child: Text(
                      'Belum ada yang bergerak minggu ini. '
                      'Kamu bisa jadi yang pertama.',
                      style: RukunText.subhead
                          .copyWith(color: context.teksSekunder),
                    ),
                  );
                }
                final maks = daftar.first.menitBergerak.clamp(1, 1 << 30);
                return KartuRukun(
                  padding: const EdgeInsets.symmetric(vertical: Jarak.sm),
                  child: Column(
                    children: [
                      for (final a in daftar)
                        _Baris(
                          nama: a.kamu ? 'Kamu' : a.nama,
                          menit: a.menitBergerak,
                          maks: maks,
                          warna: k.warna,
                          kamu: a.kamu,
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: Jarak.antarBagian),
            const JudulBagian('Kelurahan lain'),
            semua.maybeWhen(
              data: (daftar) {
                final lain = daftar.where((x) => x.id != k.id).toList();
                if (lain.isEmpty) return const SizedBox.shrink();
                return GrupBaris(
                  baris: [
                    for (final l in lain)
                      BarisRukun(
                        judul: l.nama,
                        keterangan: '${l.jumlahAnggota} warga bergerak',
                        ikon: Icons.hexagon_rounded,
                        gradient: l.warna.gradient,
                        ekor: Text(
                          '${l.persenWilayah.toStringAsFixed(0)}%',
                          style: RukunText.headline
                              .copyWith(color: context.warna.onSurface),
                        ),
                      ),
                  ],
                );
              },
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
    final putihAman = kelurahan.warna.teksPutihAman;
    final atas = putihAman ? Colors.white : const Color(0xFF0B0D12);

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kelurahan ${kelurahan.nama}',
                  overflow: TextOverflow.ellipsis,
                  style: RukunText.headline
                      .copyWith(color: atas.withValues(alpha: 0.9)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Jarak.md, vertical: Jarak.xs),
                decoration: ShapeDecoration(
                  color: atas.withValues(alpha: 0.18),
                  shape: const StadiumBorder(),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      naik
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 13,
                      color: atas,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${kelurahan.selisihPersen.abs().toStringAsFixed(0)}%',
                      style: RukunText.caption.copyWith(color: atas),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Jarak.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                kelurahan.persenWilayah.toStringAsFixed(0),
                style: RukunText.angkaBesar.copyWith(color: atas),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child:
                    Text('%', style: RukunText.judul2.copyWith(color: atas)),
              ),
            ],
          ),
          Text(
            'wilayah dikuasai',
            style:
                RukunText.subhead.copyWith(color: atas.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: Jarak.xl),
          Divider(color: atas.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: Jarak.lg),
          // Angka absolut, bukan peringkat.
          Row(
            children: [
              Icon(Icons.groups_rounded, size: 16, color: atas),
              const SizedBox(width: Jarak.sm),
              Expanded(
                child: Text(
                  '${kelurahan.jumlahAnggota} warga bergerak minggu ini',
                  style: RukunText.subhead.copyWith(color: atas),
                ),
              ),
            ],
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
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: kamu ? warna.gradient : null,
              color: kamu
                  ? null
                  : (context.modeGelap
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.05)),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                nama.trim()[0].toUpperCase(),
                style: RukunText.caption.copyWith(
                  color: kamu ? Colors.white : context.teksSekunder,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: Jarak.md),
          SizedBox(
            width: 74,
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
                minHeight: 6,
                backgroundColor: context.modeGelap
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation(
                  kamu ? warna.a : warna.a.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          const SizedBox(width: Jarak.md),
          SizedBox(
            width: 52,
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
