import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/rukun_colors.dart';
import 'core/theme/rukun_spacing.dart';
import 'core/theme/rukun_theme.dart';
import 'core/theme/rukun_typography.dart';
import 'core/util/bentuk.dart';
import 'domain/model/pelintas.dart';
import 'shared/widgets/frosted_card.dart';
import 'shared/widgets/gradient_button.dart';
import 'shared/widgets/petak_bar.dart';

void main() {
  runApp(const AplikasiRukun());
}

class AplikasiRukun extends StatefulWidget {
  const AplikasiRukun({super.key});

  @override
  State<AplikasiRukun> createState() => _AplikasiRukunState();
}

class _AplikasiRukunState extends State<AplikasiRukun> {
  ThemeMode _mode = ThemeMode.light;

  void _ganti() => setState(
        () => _mode =
            _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rukun',
      debugShowCheckedModeBanner: false,
      theme: RukunTheme.terang,
      darkTheme: RukunTheme.gelap,
      themeMode: _mode,
      home: LayarShowcase(onGantiMode: _ganti),
    );
  }
}

/// Galeri design system — cara tercepat memvalidasi token secara visual.
/// Layar ini akan diganti oleh alur Onboarding → Peta yang sebenarnya.
class LayarShowcase extends StatefulWidget {
  const LayarShowcase({super.key, required this.onGantiMode});

  final VoidCallback onGantiMode;

  @override
  State<LayarShowcase> createState() => _LayarShowcaseState();
}

class _LayarShowcaseState extends State<LayarShowcase> {
  // Demo langsung dari mekanik inti: 3 orang berbeda mengklaim satu petak.
  List<Pelintas> _pelintas = const [
    Pelintas(id: 'u1', nama: 'Sari'),
    Pelintas(id: 'u2', nama: 'Kamu', kamu: true),
  ];

  void _tambahPelintas() {
    if (_pelintas.length >= 3) {
      setState(() => _pelintas = const [Pelintas(id: 'u1', nama: 'Sari')]);
      HapticFeedback.selectionClick();
    } else {
      setState(() => _pelintas = [..._pelintas, const Pelintas(id: 'u3', nama: 'Budi')]);
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = context.gradients;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: g.latar),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Jarak.tepiLayar,
              Jarak.lg,
              Jarak.tepiLayar,
              Jarak.massive,
            ),
            children: [
              // ── Kepala ──────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TeksGradient(
                          'Rukun',
                          gradient: g.terang,
                          style: RukunText.display,
                        ),
                        const SizedBox(height: Jarak.xs),
                        Text(
                          'Kabut & Cahaya · Design System',
                          style: RukunText.subhead
                              .copyWith(color: context.teksSekunder),
                        ),
                      ],
                    ),
                  ),
                  _TombolBulat(
                    ikon: context.modeGelap
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    onTap: widget.onGantiMode,
                  ),
                ],
              ),
              const SizedBox(height: Jarak.antarBagian),

              // ── Komponen tanda tangan ───────────────────────────
              _Bagian('Bilah Petak', 'Mekanik inti: 3 orang berbeda'),
              GestureDetector(
                onTap: _tambahPelintas,
                child: BilahPetak(
                  namaPetak: 'Petak Tebet Barat',
                  pelintas: _pelintas,
                  tim: TimWarna.biru,
                  buram: false,
                  onAjak: () {},
                ),
              ),
              const SizedBox(height: Jarak.sm),
              Text(
                'Ketuk kartu buat simulasi orang berikutnya lewat →',
                style: RukunText.caption.copyWith(color: context.teksTersier),
              ),
              const SizedBox(height: Jarak.antarBagian),

              // ── Gradient brand ──────────────────────────────────
              _Bagian('Gradient', 'Semua 135°, aturan Delta Kecil'),
              _Petak('terang', 'Primer · kejernihan', g.terang),
              _Petak('fajar', 'Aksen · perayaan', g.fajar),
              _Petak('misi', 'Penemuan · quest', g.misi),
              _Petak('kabut', 'Terkunci', g.kabut, teksGelap: true),
              const SizedBox(height: Jarak.lg),
              _Petak('tumbuh', 'Berhasil', g.tumbuh),
              _Petak('hangus', 'Akan hangus', g.hangus, teksGelap: true),
              _Petak('bahaya', 'Error · jarang dipakai', g.bahaya),
              const SizedBox(height: Jarak.antarBagian),

              // ── Warna tim ───────────────────────────────────────
              _Bagian('Warna Tim', '8 kelurahan · aman untuk buta warna'),
              Wrap(
                spacing: Jarak.md,
                runSpacing: Jarak.md,
                children: [
                  for (final t in TimWarna.values)
                    Column(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: Bentuk.dekorasi(
                            radius: Sudut.lg,
                            gradient: t.gradient,
                            bayangan: Elevasi.pendar(t.a),
                          ),
                        ),
                        const SizedBox(height: Jarak.sm),
                        Text(
                          t.label,
                          style: RukunText.caption
                              .copyWith(color: context.teksSekunder),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: Jarak.antarBagian),

              // ── Tipografi ───────────────────────────────────────
              _Bagian('Tipografi', 'Plus Jakarta Sans + Inter'),
              KartuRukun(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Display 40', style: RukunText.display),
                    const SizedBox(height: Jarak.md),
                    Text('Judul 1 · 32', style: RukunText.judul1),
                    const SizedBox(height: Jarak.md),
                    Text('Judul 2 · 24', style: RukunText.judul2),
                    const SizedBox(height: Jarak.md),
                    Text('Headline · 17 SemiBold', style: RukunText.headline),
                    const SizedBox(height: Jarak.sm),
                    Text(
                      'Body 17 — jalan santai, masih bisa ngobrol. '
                      'Bahasa manusia, tanpa jargon.',
                      style: RukunText.body
                          .copyWith(color: context.teksSekunder),
                    ),
                    const SizedBox(height: Jarak.lg),
                    const Divider(),
                    const SizedBox(height: Jarak.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TeksGradient(
                          '34',
                          gradient: g.fajar,
                          style: RukunText.angkaBesar,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TeksGradient(
                            '%',
                            gradient: g.fajar,
                            style: RukunText.judul2,
                          ),
                        ),
                        const SizedBox(width: Jarak.md),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '47 warga bergerak\nminggu ini',
                              textAlign: TextAlign.right,
                              style: RukunText.footnote
                                  .copyWith(color: context.teksSekunder),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Jarak.antarBagian),

              // ── Tombol ──────────────────────────────────────────
              _Bagian('Tombol', 'Maksimal satu primer per layar'),
              TombolRukun(
                label: 'Mulai jalan 5 menit',
                ikon: Icons.play_arrow_rounded,
                onTap: () {},
              ),
              const SizedBox(height: Jarak.antarKartu),
              TombolRukun(
                label: 'Lihat kelurahan',
                varian: VarianTombol.sekunder,
                onTap: () {},
              ),
              const SizedBox(height: Jarak.antarKartu),
              TombolRukun(
                label: 'Nanti aja',
                varian: VarianTombol.hantu,
                onTap: () {},
              ),
              const SizedBox(height: Jarak.antarBagian),

              // ── Material buram ──────────────────────────────────
              _Bagian('Material Buram', 'Kaca = kabut, secara harfiah'),
              Container(
                height: 200,
                decoration: Bentuk.dekorasi(radius: Sudut.lg, gradient: g.misi),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(Jarak.xxl),
                    child: KartuBuram(
                      buram: Buram.sedang,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Misi Hari Ini', style: RukunText.headline),
                          const SizedBox(height: Jarak.sm),
                          Text(
                            'Jalan sore ke Taman Tebet',
                            style: RukunText.subhead
                                .copyWith(color: context.teksSekunder),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bagian extends StatelessWidget {
  const _Bagian(this.judul, this.sub);

  final String judul;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Jarak.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(judul, style: RukunText.judul2),
          const SizedBox(height: 2),
          Text(
            sub,
            style: RukunText.footnote.copyWith(color: context.teksTersier),
          ),
        ],
      ),
    );
  }
}

class _Petak extends StatelessWidget {
  const _Petak(this.nama, this.guna, this.gradient, {this.teksGelap = false});

  final String nama;
  final String guna;
  final Gradient gradient;
  final bool teksGelap;

  @override
  Widget build(BuildContext context) {
    final warna = teksGelap ? RukunColors.teksPrimerTerang : Colors.white;
    return Container(
      margin: const EdgeInsets.only(bottom: Jarak.antarKartu),
      padding: const EdgeInsets.symmetric(
        horizontal: Jarak.xl,
        vertical: Jarak.lg,
      ),
      decoration: Bentuk.dekorasi(radius: Sudut.md, gradient: gradient),
      child: Row(
        children: [
          Text(nama, style: RukunText.headline.copyWith(color: warna)),
          const SizedBox(width: Jarak.md),
          Expanded(
            child: Text(
              guna,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: RukunText.footnote
                  .copyWith(color: warna.withValues(alpha: 0.75)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TombolBulat extends StatelessWidget {
  const _TombolBulat({required this.ikon, required this.onTap});

  final IconData ikon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: context.gradients.permukaan,
          shape: BoxShape.circle,
          boxShadow: Elevasi.satu,
        ),
        child: Icon(ikon, size: 20, color: context.warna.onSurface),
      ),
    );
  }
}
