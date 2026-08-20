import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/rukun_spacing.dart';
import '../../core/theme/rukun_theme.dart';
import '../../core/theme/rukun_typography.dart';
import '../../domain/aturan/moda_gerak.dart';
import '../../domain/model/koordinat.dart';
import '../../shared/widgets/frosted_card.dart';
import '../../shared/widgets/kabut_singkap.dart';
import '../../state/kendali_sesi.dart';
import '../../state/penyedia.dart';
import '../peta/peta_rukun.dart';

/// Layar sesi berjalan. DESIGN.md §7.3
///
/// Minimal secara ekstrem — dipakai sambil bergerak, sering di bawah sinar
/// matahari.
///
/// **Pace tidak pernah ditampilkan.** Ini keputusan produk, bukan kelalaian.
/// Angka besar yang ditampilkan adalah durasi, karena itulah yang menentukan
/// kontribusi ke tim.
class LayarSesi extends ConsumerStatefulWidget {
  const LayarSesi({super.key, this.onSelesaiSesi});

  final ValueChanged<HasilSesi>? onSelesaiSesi;

  @override
  ConsumerState<LayarSesi> createState() => _LayarSesiState();
}

class _LayarSesiState extends ConsumerState<LayarSesi> {
  static const _acuan = Koordinat(-6.2264, 106.8556);

  /// Memicu Penyingkapan Kabut. Dinaikkan setiap ada petak baru terbuka.
  bool _menyingkap = false;
  int _petakTerakhir = 0;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(kendaliSesiProvider);

    // Petak baru terbuka → jalankan animasi tanda tangan.
    if (status.petakSesi.length != _petakTerakhir) {
      _petakTerakhir = status.petakSesi.length;
      if (_petakTerakhir > 0 && !_menyingkap) {
        _menyingkap = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    }

    final posisi = ref.watch(posisiProvider).valueOrNull ?? _acuan;

    final d = status.durasi;
    final jam = d.inHours;
    final menit = d.inMinutes % 60;
    final detik = d.inSeconds % 60;
    final teksDurasi = jam > 0
        ? '$jam:${menit.toString().padLeft(2, '0')}:'
            '${detik.toString().padLeft(2, '0')}'
        : '${menit.toString().padLeft(2, '0')}:'
            '${detik.toString().padLeft(2, '0')}';

    return Scaffold(
      body: Column(
        children: [
          // Peta menyusut jadi kartu 40% — kabut terbuka secara langsung.
          Expanded(
            flex: 4,
            child: KabutSingkap(
              tersingkap: _menyingkap,
              label: '+${status.petakSesi.length} petak',
              onSelesai: () {
                // Siap dipicu lagi untuk petak berikutnya.
                if (mounted) setState(() => _menyingkap = false);
                ref.read(kendaliSesiProvider.notifier).bersihkanPetakBaru();
              },
              child: PetaRukun(
                pusat: posisi,
                jejak: status.petakSesi,
                zoom: 17,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(gradient: context.gradients.latar),
              padding: const EdgeInsets.all(Jarak.tepiLayar),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const Spacer(),
                    // Durasi — bukan pace, bukan kecepatan.
                    Text(
                      teksDurasi,
                      style: RukunText.angkaBesar
                          .copyWith(color: context.warna.onSurface),
                    ),
                    Text(
                      status.moda == ModaGerak.lari
                          ? 'waktu lari'
                          : 'waktu jalan',
                      style: RukunText.subhead
                          .copyWith(color: context.teksSekunder),
                    ),
                    const SizedBox(height: Jarak.xxxl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _Angka(
                          nilai: '${status.petakSesi.length}',
                          label: 'petak terbuka',
                          gradient: context.gradients.fajar,
                        ),
                        _Angka(
                          nilai: '${status.menitBergerak}',
                          label: 'menit bergerak',
                          gradient: context.gradients.tumbuh,
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (status.moda == ModaGerak.kendaraan)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Jarak.lg),
                        child: KartuRukun(
                          padding: const EdgeInsets.all(Jarak.lg),
                          child: Text(
                            'Kayaknya kamu lagi naik kendaraan — '
                            'bagian ini nggak dihitung.',
                            style: RukunText.subhead
                                .copyWith(color: context.teksSekunder),
                          ),
                        ),
                      ),
                    // Tekan lama, mencegah tersentuh tak sengaja.
                    _TombolSelesai(
                      onSelesai: () async {
                        final hasil = await ref
                            .read(kendaliSesiProvider.notifier)
                            .selesai();
                        if (hasil != null) widget.onSelesaiSesi?.call(hasil);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Angka extends StatelessWidget {
  const _Angka({
    required this.nilai,
    required this.label,
    required this.gradient,
  });

  final String nilai;
  final String label;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeksGradient(nilai, gradient: gradient, style: RukunText.angkaSedang),
        const SizedBox(height: Jarak.xs),
        Text(label,
            style: RukunText.caption.copyWith(color: context.teksSekunder)),
      ],
    );
  }
}

/// Tombol selesai dengan tekan-lama 800 ms.
class _TombolSelesai extends StatefulWidget {
  const _TombolSelesai({required this.onSelesai});

  final VoidCallback onSelesai;

  @override
  State<_TombolSelesai> createState() => _TombolSelesaiState();
}

class _TombolSelesaiState extends State<_TombolSelesai>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tahan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onSelesai();
    });

  @override
  void dispose() {
    _tahan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _tahan.forward(),
      onTapUp: (_) => _tahan.reverse(),
      onTapCancel: () => _tahan.reverse(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _tahan,
            builder: (context, _) => ClipRRect(
              borderRadius: BorderRadius.circular(Sudut.penuh),
              child: LinearProgressIndicator(
                value: _tahan.value,
                minHeight: 52,
                backgroundColor: context.modeGelap
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                valueColor:
                    AlwaysStoppedAnimation(context.gradients.bahaya.colors.first
                        .withValues(alpha: 0.25)),
              ),
            ),
          ),
          IgnorePointer(
            child: Text(
              'Tahan buat selesai',
              style: RukunText.headline
                  .copyWith(color: context.warna.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
