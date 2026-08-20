import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/rukun_colors.dart';
import '../../core/theme/rukun_motion.dart';
import '../../core/theme/rukun_spacing.dart';
import '../../core/theme/rukun_theme.dart';
import '../../core/theme/rukun_typography.dart';
import '../../core/util/bentuk.dart';
import '../../domain/model/pelintas.dart';
import 'gradient_button.dart';

/// **Perayaan klaim.** DESIGN.md §5.3
///
/// Muncul ketika orang ketiga melengkapi sebuah petak.
///
/// **Bukan konfeti** — konfeti murahan. Yang mengembang adalah cahaya lembut
/// berwarna tim, memenuhi 12% layar.
///
/// Salinan teksnya menyebut **orangnya**. Menyebut nama tetangga nyata adalah
/// muatan emosional terbesar yang produk ini punya, dan momen inilah tempat
/// paling tepat untuk memakainya.
class PerayaanKlaim extends StatefulWidget {
  const PerayaanKlaim({
    super.key,
    required this.namaPetak,
    required this.namaTim,
    required this.warna,
    required this.pelintas,
    this.onTutup,
  });

  final String namaPetak;
  final String namaTim;
  final TimWarna warna;

  /// Tiga orang yang melengkapi klaim, termasuk pengguna.
  final List<Pelintas> pelintas;

  final VoidCallback? onTutup;

  /// Menampilkan perayaan sebagai lembar modal.
  static Future<void> tampilkan(
    BuildContext context, {
    required String namaPetak,
    required String namaTim,
    required TimWarna warna,
    required List<Pelintas> pelintas,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PerayaanKlaim(
        namaPetak: namaPetak,
        namaTim: namaTim,
        warna: warna,
        pelintas: pelintas,
      ),
    );
  }

  @override
  State<PerayaanKlaim> createState() => _PerayaanKlaimState();
}

class _PerayaanKlaimState extends State<PerayaanKlaim>
    with SingleTickerProviderStateMixin {
  late final AnimationController _kendali;

  @override
  void initState() {
    super.initState();
    _kendali = AnimationController(vsync: this, duration: Gerak.rayakan);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _kendali.forward();
    });
  }

  @override
  void dispose() {
    _kendali.dispose();
    super.dispose();
  }

  /// Menyebut orangnya, bukan kejadiannya. DESIGN.md §8
  String get _pesan {
    final lain = widget.pelintas.where((p) => !p.kamu).toList();
    if (lain.isEmpty) {
      return 'Petak ini milik ${widget.namaTim} sekarang.';
    }
    if (lain.length == 1) {
      return '${lain.first.nama} lewat sini juga. '
          'Petak ini milik ${widget.namaTim} sekarang.';
    }
    return '${lain[0].nama} dan ${lain[1].nama} lewat sini duluan. '
        'Kamu yang ketiga. Petak ini milik ${widget.namaTim} sekarang.';
  }

  @override
  Widget build(BuildContext context) {
    final kurangiGerak = Gerak.kurangiGerak(context);

    return AnimatedBuilder(
      animation: _kendali,
      builder: (context, _) {
        final t = kurangiGerak ? 1.0 : Curves.easeOutCubic
            .transform(_kendali.value.clamp(0.0, 1.0));

        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Cahaya lembut yang mengembang — bukan konfeti.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomCenter,
                      radius: t * 1.4,
                      colors: [
                        widget.warna.a.withValues(alpha: 0.12 * t),
                        widget.warna.b.withValues(alpha: 0.05 * t),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, 40 * (1 - t)),
              child: Opacity(opacity: t, child: _kartu(context)),
            ),
          ],
        );
      },
    );
  }

  Widget _kartu(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(Jarak.lg),
      padding: const EdgeInsets.all(Jarak.xxl),
      decoration: Bentuk.dekorasi(
        radius: Sudut.xxl,
        gradient: context.gradients.permukaanTinggi,
        bayangan: Elevasi.tiga,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: Jarak.lg, vertical: Jarak.sm),
              decoration: ShapeDecoration(
                gradient: widget.warna.gradient,
                shape: const StadiumBorder(),
              ),
              child: Text(
                'Petak terklaim',
                style: RukunText.caption.copyWith(
                  color: widget.warna.teksPutihAman
                      ? Colors.white
                      : RukunColors.teksPrimerTerang,
                ),
              ),
            ),
            const SizedBox(height: Jarak.xl),
            Text(widget.namaPetak, style: RukunText.judul2),
            const SizedBox(height: Jarak.md),
            Text(
              _pesan,
              style: RukunText.body.copyWith(color: context.teksSekunder),
            ),
            const SizedBox(height: Jarak.xl),
            Row(
              children: [
                for (final p in widget.pelintas)
                  Padding(
                    padding: const EdgeInsets.only(right: Jarak.sm),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: widget.warna.gradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          p.huruf,
                          style: RukunText.subhead.copyWith(
                            color: widget.warna.teksPutihAman
                                ? Colors.white
                                : RukunColors.teksPrimerTerang,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Jarak.xxl),
            TombolRukun(
              label: 'Mantap',
              onTap: () {
                widget.onTutup?.call();
                Navigator.of(context).maybePop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
