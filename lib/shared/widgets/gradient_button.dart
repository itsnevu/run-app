import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/rukun_motion.dart';
import '../../core/theme/rukun_spacing.dart';
import '../../core/theme/rukun_theme.dart';
import '../../core/theme/rukun_typography.dart';

enum VarianTombol { primer, sekunder, hantu, destruktif }

/// Tombol Rukun. DESIGN.md §6.1
///
/// ATURAN: maksimal satu tombol [VarianTombol.primer] per layar.
/// Kalau butuh dua aksi primer, layarnya yang bermasalah.
class TombolRukun extends StatefulWidget {
  const TombolRukun({
    super.key,
    required this.label,
    required this.onTap,
    this.varian = VarianTombol.primer,
    this.ikon,
    this.penuh = true,
    this.padat = false,
  });

  final String label;
  final VoidCallback? onTap;
  final VarianTombol varian;
  final IconData? ikon;

  /// Melebar memenuhi induknya.
  final bool penuh;

  /// Tinggi 44 alih-alih 52.
  final bool padat;

  @override
  State<TombolRukun> createState() => _TombolRukunState();
}

class _TombolRukunState extends State<TombolRukun> {
  bool _ditekan = false;

  bool get _aktif => widget.onTap != null;

  void _tekan(bool nilai) {
    if (!_aktif) return;
    setState(() => _ditekan = nilai);
    if (nilai) HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final g = context.gradients;
    final tinggi = widget.padat ? 44.0 : 52.0;

    final (gradient, warnaTeks, latar, tepi) = switch (widget.varian) {
      VarianTombol.primer => (g.terang, Colors.white, null, null),
      VarianTombol.sekunder => (
          null,
          context.warna.onSurface,
          context.modeGelap
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          null,
        ),
      VarianTombol.hantu => (null, null, null, null),
      VarianTombol.destruktif => (
          null,
          null,
          null,
          g.bahaya.colors.first,
        ),
    };

    Widget isi = Row(
      mainAxisSize: widget.penuh ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.ikon != null) ...[
          Icon(widget.ikon, size: 20, color: warnaTeks),
          const SizedBox(width: Jarak.sm),
        ],
        Flexible(
          child: Text(
            widget.label,
            overflow: TextOverflow.ellipsis,
            style: RukunText.headline.copyWith(color: warnaTeks),
          ),
        ),
      ],
    );

    // Varian hantu & destruktif memakai gradient sebagai warna TEKS.
    if (widget.varian == VarianTombol.hantu ||
        widget.varian == VarianTombol.destruktif) {
      final gradTeks =
          widget.varian == VarianTombol.hantu ? g.terang : g.bahaya;
      isi = ShaderMask(
        shaderCallback: (r) => gradTeks.createShader(r),
        blendMode: BlendMode.srcIn,
        child: DefaultTextStyle(
          style: RukunText.headline.copyWith(color: Colors.white),
          child: IconTheme(
            data: const IconThemeData(color: Colors.white, size: 20),
            child: isi,
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      enabled: _aktif,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => _tekan(true),
        onTapUp: (_) => _tekan(false),
        onTapCancel: () => _tekan(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          // reduceMotion: tanpa skala, hanya haptic + perubahan opasitas.
          scale: (_ditekan && !Gerak.kurangiGerak(context)) ? 0.96 : 1.0,
          duration: Gerak.sigap,
          curve: Gerak.sigapKurva,
          child: AnimatedOpacity(
            opacity: _aktif ? 1.0 : 0.4,
            duration: Gerak.sigap,
            child: Container(
              height: tinggi,
              width: widget.penuh ? double.infinity : null,
              padding: EdgeInsets.symmetric(
                horizontal: widget.penuh ? Jarak.xl : Jarak.xxl,
              ),
              decoration: BoxDecoration(
                gradient: gradient,
                color: latar,
                borderRadius: BorderRadius.circular(Sudut.penuh),
                border: tepi != null
                    ? Border.all(color: tepi.withValues(alpha: 0.4), width: 1.5)
                    : null,
                // Pendar berwarna — satu-satunya bayangan mencolok
                // yang diizinkan. DESIGN.md §4.3
                boxShadow: widget.varian == VarianTombol.primer && _aktif
                    ? Elevasi.pendar(g.terang.colors.first)
                    : null,
              ),
              child: Center(child: isi),
            ),
          ),
        ),
      ),
    );
  }
}
