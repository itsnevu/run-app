import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/rukun_motion.dart';
import '../../core/theme/rukun_spacing.dart';
import '../../core/theme/rukun_theme.dart';
import '../../core/theme/rukun_typography.dart';
import 'frosted_card.dart';

class TabRukun {
  const TabRukun(this.label, this.ikon, this.ikonAktif);

  final String label;
  final IconData ikon;
  final IconData ikonAktif;
}

/// Bilah tab mengambang. DESIGN.md §6.4
///
/// ```
///   Peta      Tim     ( ● )     Misi      Aku
///                    REKAM
/// ```
///
/// Tombol rekam di tengah memakai gradient fajar dan mengambang di atas
/// bilah. Saat sesi berjalan ia berdenyut lembut — bukan berkedip.
class BilahTab extends StatelessWidget {
  const BilahTab({
    super.key,
    required this.terpilih,
    required this.onPilih,
    required this.onRekam,
    this.sedangMerekam = false,
  });

  final int terpilih;
  final ValueChanged<int> onPilih;
  final VoidCallback onRekam;
  final bool sedangMerekam;

  /// Tinggi bilah ini di luar area aman.
  ///
  /// Diumumkan supaya layar yang mengambang di atas peta bisa berhenti
  /// menebak: sebelumnya posisi tombol dan sheet dikunci ke angka ajaib yang
  /// tidak pernah cocok dengan tinggi sebenarnya.
  static const tinggi = 82.0;

  static const tab = [
    TabRukun('Peta', Icons.map_outlined, Icons.map_rounded),
    TabRukun('Tim', Icons.groups_outlined, Icons.groups_rounded),
    TabRukun('Misi', Icons.flag_outlined, Icons.flag_rounded),
    TabRukun('Aku', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    // SafeArea sendiri, bukan titipan Scaffold: dengan `extendBody: true`
    // bilah ini melayang di atas peta, dan tanpa penyesuaian ia menabrak
    // indikator home iPhone.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Jarak.lg, 0, Jarak.lg, Jarak.sm),
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            KartuBuram(
              buram: Buram.tebal,
              radius: Sudut.penuh,
              padding: const EdgeInsets.symmetric(vertical: Jarak.md),
              child: Row(
                children: [
                  _slot(context, 0),
                  _slot(context, 1),
                  const SizedBox(width: 68), // ruang untuk tombol rekam
                  _slot(context, 2),
                  _slot(context, 3),
                ],
              ),
            ),
            Positioned(
              top: -8,
              child: _TombolRekam(aktif: sedangMerekam, onTap: onRekam),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slot(BuildContext context, int i) {
    final t = tab[i];
    final aktif = terpilih == i;

    return Expanded(
      child: Semantics(
        selected: aktif,
        button: true,
        label: t.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onPilih(i);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (aktif)
                ShaderMask(
                  shaderCallback: (r) =>
                      context.gradients.terang.createShader(r),
                  blendMode: BlendMode.srcIn,
                  child: Icon(t.ikonAktif, size: 24, color: Colors.white),
                )
              else
                Icon(t.ikon, size: 24, color: context.teksTersier),
              const SizedBox(height: 2),
              Text(
                t.label,
                style: RukunText.caption.copyWith(
                  color: aktif ? context.warna.onSurface : context.teksTersier,
                  fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TombolRekam extends StatefulWidget {
  const _TombolRekam({required this.aktif, required this.onTap});

  final bool aktif;
  final VoidCallback onTap;

  @override
  State<_TombolRekam> createState() => _TombolRekamState();
}

class _TombolRekamState extends State<_TombolRekam>
    with SingleTickerProviderStateMixin {
  late final AnimationController _denyut = AnimationController(
    vsync: this,
    duration: Gerak.denyut,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _perbaruiDenyut();
  }

  @override
  void didUpdateWidget(covariant _TombolRekam lama) {
    super.didUpdateWidget(lama);
    if (widget.aktif != lama.aktif) _perbaruiDenyut();
  }

  void _perbaruiDenyut() {
    // reduceMotion: denyut dimatikan sepenuhnya. DESIGN.md §9
    if (widget.aktif && !Gerak.kurangiGerak(context)) {
      _denyut.repeat(reverse: true);
    } else {
      _denyut.stop();
      _denyut.value = 0;
    }
  }

  @override
  void dispose() {
    _denyut.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = context.gradients;

    return Semantics(
      button: true,
      label: widget.aktif ? 'Sesi berjalan' : 'Mulai sesi',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _denyut,
          builder: (context, anak) =>
              Transform.scale(scale: 1.0 + 0.04 * _denyut.value, child: anak),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: g.fajar,
              shape: BoxShape.circle,
              boxShadow: Elevasi.pendar(g.fajar.colors.first),
              border: Border.all(
                color: context.modeGelap
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.6),
                width: 3,
              ),
            ),
            child: Icon(
              widget.aktif ? Icons.stop_rounded : Icons.directions_walk_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
