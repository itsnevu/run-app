import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/rukun_motion.dart';
import '../../core/theme/rukun_theme.dart';
import '../../core/theme/rukun_typography.dart';

/// **Penyingkapan Kabut** — animasi tanda tangan Rukun. DESIGN.md §5.2
///
/// Ini momen yang orang akan rekam layarnya dan kirim ke grup WhatsApp.
///
/// Urutannya:
/// ```
/// 0ms    petak berkabut, abu kebiruan, blur 8
/// 80ms   denyut halus di titik pengguna (skala 1,0 → 1,06)
/// 150ms  kabut larut dari tengah keluar (mask radial menyebar)
///        blur 8 → 0 · saturasi 0,2 → 1,0
/// 400ms  garis tepi menyala gradient fajar
/// 500ms  angka +1 melayang naik, memudar
/// 600ms  selesai · haptic impactLight
/// ```
///
/// Butuh 600 ms tapi terasa seperti 200 ms karena mengalir keluar dari titik
/// posisi pengguna. **Jangan pernah** menggantinya dengan fade sederhana —
/// kecuali saat `reduceMotion` menyala, yang dihormati di sini.
class KabutSingkap extends StatefulWidget {
  const KabutSingkap({
    super.key,
    required this.child,
    this.tersingkap = false,
    this.asal = Alignment.center,
    this.label = '+1 petak',
    this.tampilkanLabel = true,
    this.onSelesai,
  });

  /// Konten yang berada di balik kabut — biasanya peta.
  final Widget child;

  /// Pemicu. Ubah dari false ke true untuk menjalankan penyingkapan.
  final bool tersingkap;

  /// Titik asal penyingkapan — posisi pengguna di layar.
  final Alignment asal;

  final String label;
  final bool tampilkanLabel;
  final VoidCallback? onSelesai;

  @override
  State<KabutSingkap> createState() => _KabutSingkapState();
}

class _KabutSingkapState extends State<KabutSingkap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _kendali;
  bool _sudahGetar = false;

  // Tahapan sesuai DESIGN.md §5.2, dinormalkan ke 0..1 dari 600 ms.
  static const _denyut = Interval(0.13, 0.33, curve: Curves.easeOutCubic);
  static const _larut = Interval(0.25, 0.83, curve: Curves.easeOutCubic);
  static const _tepi = Interval(0.66, 1.0, curve: Curves.easeOut);
  static const _angka = Interval(0.83, 1.0, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _kendali = AnimationController(
      vsync: this,
      duration: Gerak.singkap,
      value: widget.tersingkap ? 1.0 : 0.0,
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onSelesai?.call();
      });
  }

  @override
  void didUpdateWidget(covariant KabutSingkap lama) {
    super.didUpdateWidget(lama);
    if (widget.tersingkap == lama.tersingkap) return;

    _kendali.duration = Gerak.singkapEfektif(context);
    if (widget.tersingkap) {
      _sudahGetar = false;
      _kendali.forward(from: 0);
    } else {
      _kendali.reverse();
    }
  }

  @override
  void dispose() {
    _kendali.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kurangiGerak = Gerak.kurangiGerak(context);

    return AnimatedBuilder(
      animation: _kendali,
      builder: (context, _) {
        final t = _kendali.value;

        // Haptic tepat saat kabut selesai larut, bukan di akhir animasi —
        // supaya sentuhan terasa sinkron dengan yang dilihat mata.
        if (!_sudahGetar && t >= _larut.end) {
          _sudahGetar = true;
          HapticFeedback.lightImpact();
        }

        return Stack(
          fit: StackFit.passthrough,
          children: [
            _KontenBerdenyut(
              denyut: kurangiGerak ? 0 : _denyut.transform(t),
              asal: widget.asal,
              child: widget.child,
            ),
            if (t < 1.0)
              Positioned.fill(
                child: IgnorePointer(
                  child: _LapisanKabut(
                    larut: _larut.transform(t),
                    asal: widget.asal,
                    child: widget.child,
                  ),
                ),
              ),
            if (t > _tepi.begin)
              Positioned.fill(
                child: IgnorePointer(
                  child: _TepiMenyala(nyala: _tepi.transform(t)),
                ),
              ),
            if (widget.tampilkanLabel && t > _angka.begin)
              Positioned.fill(
                child: IgnorePointer(
                  child: _AngkaMelayang(
                    maju: _angka.transform(t),
                    label: widget.label,
                    asal: widget.asal,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Denyut halus di bawah posisi pengguna — 1,0 → 1,06 → 1,0.
class _KontenBerdenyut extends StatelessWidget {
  const _KontenBerdenyut({
    required this.denyut,
    required this.asal,
    required this.child,
  });

  final double denyut;
  final Alignment asal;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Naik lalu turun kembali dalam satu tahap.
    final skala = 1.0 + 0.06 * (denyut <= 0.5 ? denyut * 2 : (1 - denyut) * 2);
    return Transform.scale(
      scale: denyut == 0 ? 1.0 : skala,
      alignment: asal,
      child: child,
    );
  }
}

/// Salinan berkabut dari konten, dilarutkan oleh mask radial.
class _LapisanKabut extends StatelessWidget {
  const _LapisanKabut({
    required this.larut,
    required this.asal,
    required this.child,
  });

  final double larut;
  final Alignment asal;
  final Widget child;

  /// Matriks saturasi standar (luminansi Rec. 709).
  static List<double> _saturasi(double s) {
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final n = 1 - s;
    return [
      lr * n + s, lg * n, lb * n, 0, 0,
      lr * n, lg * n + s, lb * n, 0, 0,
      lr * n, lg * n, lb * n + s, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final blur = 8.0 * (1 - larut);
    final sat = 0.2 + 0.8 * larut;

    return ShaderMask(
      // Mask menyingkirkan kabut dari tengah ke luar. Di luar radius,
      // TileMode.clamp membuat sisanya tetap buram — kabut bertahan.
      shaderCallback: (r) => RadialGradient(
        center: asal,
        radius: larut * 1.6,
        colors: const [
          Colors.transparent,
          Colors.transparent,
          Colors.white,
        ],
        stops: const [0.0, 0.75, 1.0],
      ).createShader(r),
      blendMode: BlendMode.dstIn,
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
          tileMode: TileMode.decal,
        ),
        child: ColorFiltered(
          colorFilter: ColorFilter.matrix(_saturasi(sat)),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              child,
              // Rona abu kebiruan — warna kabut.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: context.gradients.kabut,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Garis tepi yang menyala gradient fajar saat petak terbuka.
class _TepiMenyala extends StatelessWidget {
  const _TepiMenyala({required this.nyala});

  final double nyala;

  @override
  Widget build(BuildContext context) {
    // Ketebalan 2 → 3 → 2, seperti denyut cahaya.
    final tebal = 2.0 + (nyala <= 0.5 ? nyala * 2 : (1 - nyala) * 2);
    final opasitas = (1 - nyala).clamp(0.0, 1.0);

    return CustomPaint(
      painter: _PelukisTepi(
        gradient: context.gradients.fajar,
        tebal: tebal,
        opasitas: opasitas,
      ),
    );
  }
}

class _PelukisTepi extends CustomPainter {
  const _PelukisTepi({
    required this.gradient,
    required this.tebal,
    required this.opasitas,
  });

  final Gradient gradient;
  final double tebal;
  final double opasitas;

  @override
  void paint(Canvas canvas, Size size) {
    if (opasitas <= 0) return;
    final rect = Offset.zero & size;
    final cat = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = tebal
      ..color = Colors.white.withValues(alpha: opasitas);
    canvas.drawRect(rect.deflate(tebal / 2), cat);
  }

  @override
  bool shouldRepaint(_PelukisTepi lama) =>
      lama.tebal != tebal || lama.opasitas != opasitas;
}

/// "+1 petak" melayang naik lalu memudar.
class _AngkaMelayang extends StatelessWidget {
  const _AngkaMelayang({
    required this.maju,
    required this.label,
    required this.asal,
  });

  final double maju;
  final String label;
  final Alignment asal;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: asal,
      child: Transform.translate(
        offset: Offset(0, -28 * maju),
        child: Opacity(
          opacity: (1 - maju * 0.7).clamp(0.0, 1.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: ShapeDecoration(
              gradient: context.gradients.fajar,
              shape: const StadiumBorder(),
            ),
            child: Text(
              label,
              style: RukunText.caption.copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
