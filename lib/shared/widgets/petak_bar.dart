import 'package:flutter/material.dart';

import '../../core/theme/rukun_colors.dart';
import '../../core/theme/rukun_motion.dart';
import '../../core/theme/rukun_spacing.dart';
import '../../core/theme/rukun_theme.dart';
import '../../core/theme/rukun_typography.dart';
import '../../domain/aturan/aturan_klaim.dart';
import '../../domain/model/pelintas.dart';
import 'frosted_card.dart';
import 'gradient_button.dart';

/// **Bilah Petak** — komponen paling penting di Rukun. DESIGN.md §6.3
///
/// Menampilkan mekanik inti produk: sebuah petak diklaim ketika **3 orang
/// BERBEDA** dari tim yang sama melewatinya dalam 7 hari.
///
/// Bukan 1 orang yang lewat 3 kali. Bukan yang paling cepat.
///
/// Aturan ini mengubah strategi optimal dari "latihan lebih keras" menjadi
/// "ajak tetangga" — dan membuat kontribusi pemula bernilai 100%.
/// Komponen ini membuat aturan abstrak itu terlihat dan bisa dikejar.
class BilahPetak extends StatelessWidget {
  const BilahPetak({
    super.key,
    required this.namaPetak,
    required this.pelintas,
    required this.tim,
    this.dibutuhkan = AturanKlaim.orangDibutuhkan,
    this.onAjak,
    this.buram = true,
  });

  final String namaPetak;

  /// Orang berbeda yang sudah lewat minggu ini. Maksimal [dibutuhkan].
  final List<Pelintas> pelintas;

  final TimWarna tim;

  /// Jumlah orang berbeda yang dibutuhkan untuk klaim.
  final int dibutuhkan;

  final VoidCallback? onAjak;

  /// Tampil sebagai material buram (saat mengambang di atas peta).
  final bool buram;

  bool get _terklaim => pelintas.length >= dibutuhkan;
  int get _sisa => (dibutuhkan - pelintas.length).clamp(0, dibutuhkan);

  @override
  Widget build(BuildContext context) {
    final isi = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                namaPetak,
                style: RukunText.headline
                    .copyWith(color: context.warna.onSurface),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_terklaim)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Jarak.md,
                  vertical: Jarak.xs,
                ),
                decoration: BoxDecoration(
                  gradient: context.gradients.tumbuh,
                  borderRadius: BorderRadius.circular(Sudut.penuh),
                ),
                child: Text(
                  'Terklaim',
                  style: RukunText.caption.copyWith(color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: Jarak.xl),
        _Rantai(
          pelintas: pelintas,
          dibutuhkan: dibutuhkan,
          tim: tim,
        ),
        const SizedBox(height: Jarak.lg),
        Text(
          _pesan(),
          style: RukunText.subhead.copyWith(color: context.teksSekunder),
        ),
        if (!_terklaim && onAjak != null) ...[
          const SizedBox(height: Jarak.lg),
          TombolRukun(
            label: 'Ajak tetangga',
            ikon: Icons.ios_share_rounded,
            varian: VarianTombol.sekunder,
            padat: true,
            onTap: onAjak,
          ),
        ],
      ],
    );

    return buram
        ? KartuBuram(child: isi)
        : KartuRukun(child: isi);
  }

  /// Salinan teks selalu menyebut ORANGNYA — muatan emosional terbesar
  /// yang kita punya. DESIGN.md §8
  String _pesan() {
    if (_terklaim) {
      final lain = pelintas.where((p) => !p.kamu).map((p) => p.nama).toList();
      if (lain.isEmpty) return 'Petak ini milik ${tim.label} sekarang.';
      return '${lain.first} lewat sini juga. '
          'Petak ini milik ${tim.label} sekarang.';
    }
    if (pelintas.isEmpty) {
      return 'Belum ada yang lewat sini minggu ini. Kamu bisa jadi yang pertama.';
    }
    final orang = _sisa == 1 ? '1 orang' : '$_sisa orang';
    return 'Tinggal $orang lagi buat klaim petak ini.';
  }
}

/// Rantai titik: ●━━━●━━━○
class _Rantai extends StatelessWidget {
  const _Rantai({
    required this.pelintas,
    required this.dibutuhkan,
    required this.tim,
  });

  final List<Pelintas> pelintas;
  final int dibutuhkan;
  final TimWarna tim;

  @override
  Widget build(BuildContext context) {
    final anak = <Widget>[];

    for (var i = 0; i < dibutuhkan; i++) {
      final terisi = i < pelintas.length;
      final orang = terisi ? pelintas[i] : null;

      if (i > 0) {
        final garisTerisi = i <= pelintas.length - 1;
        anak.add(
          Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: Jarak.sm),
              decoration: BoxDecoration(
                gradient: garisTerisi
                    ? tim.gradient
                    : context.gradients.kabut,
                borderRadius: BorderRadius.circular(Sudut.penuh),
              ),
            ),
          ),
        );
      }

      anak.add(
        Semantics(
          label: terisi
              ? '${orang!.sebutan}, sudah lewat'
              : 'Belum terisi',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: Gerak.kurangiGerak(context)
                    ? const Duration(milliseconds: 120)
                    : Gerak.halus,
                curve: Gerak.halusKurva,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: terisi ? tim.gradient : null,
                  color: terisi ? null : Colors.transparent,
                  shape: BoxShape.circle,
                  border: terisi
                      ? null
                      : Border.all(
                          color: context.gradients.kabut.colors.first
                              .withValues(alpha: 0.5),
                          width: 2,
                        ),
                  boxShadow: terisi ? Elevasi.pendar(tim.a) : null,
                ),
                child: Center(
                  child: terisi
                      ? Text(
                          orang!.huruf,
                          style: RukunText.headline.copyWith(
                            color: tim.teksPutihAman
                                ? Colors.white
                                : RukunColors.teksPrimerTerang,
                          ),
                        )
                      : Icon(
                          Icons.person_outline_rounded,
                          size: 20,
                          color: context.teksTersier,
                        ),
                ),
              ),
              const SizedBox(height: Jarak.sm),
              SizedBox(
                width: 56,
                child: Text(
                  terisi ? (orang!.sebutan) : '?',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: RukunText.caption.copyWith(
                    color: terisi ? context.warna.onSurface : context.teksTersier,
                    fontWeight: terisi && orang!.kamu
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: anak,
    );
  }
}
