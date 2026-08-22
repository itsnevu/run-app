import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/rukun_motion.dart';
import '../../core/theme/rukun_spacing.dart';
import '../../core/theme/rukun_theme.dart';
import '../../core/theme/rukun_typography.dart';
import '../../core/util/bentuk.dart';
import 'frosted_card.dart';

/// Judul bagian. Satu tingkat hirarki, tidak pernah dua.
///
/// Layar yang bersih dibangun dari pengulangan yang sama persis: judul,
/// keterangan sebaris, lalu isinya. Begitu pola ini konsisten, mata berhenti
/// bekerja keras dan tinggal membaca.
class JudulBagian extends StatelessWidget {
  const JudulBagian(
    this.judul, {
    super.key,
    this.keterangan,
    this.labelAksi,
    this.onAksi,
  });

  final String judul;
  final String? keterangan;
  final String? labelAksi;
  final VoidCallback? onAksi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Jarak.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judul, style: RukunText.judul3),
                if (keterangan != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    keterangan!,
                    style: RukunText.footnote
                        .copyWith(color: context.teksTersier),
                  ),
                ],
              ],
            ),
          ),
          if (labelAksi != null && onAksi != null)
            GestureDetector(
              onTap: onAksi,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: Jarak.md),
                child: TeksGradient(
                  labelAksi!,
                  gradient: context.gradients.terang,
                  style: RukunText.subhead.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Sekelompok baris dalam satu kartu, dengan pemisah rambut otomatis.
class GrupBaris extends StatelessWidget {
  const GrupBaris({super.key, required this.baris});

  final List<Widget> baris;

  @override
  Widget build(BuildContext context) {
    final isi = <Widget>[];
    for (var i = 0; i < baris.length; i++) {
      if (i > 0) {
        // Pemisah menjorok sejauh lebar ikon — garis berhenti di tempat
        // teks dimulai, seperti daftar iOS.
        isi.add(const Padding(
          padding: EdgeInsets.only(left: 52),
          child: Divider(height: 0.5),
        ));
      }
      isi.add(baris[i]);
    }

    return KartuRukun(
      padding: EdgeInsets.zero,
      child: Column(mainAxisSize: MainAxisSize.min, children: isi),
    );
  }
}

/// Satu baris daftar: ikon, judul, keterangan, ekor.
class BarisRukun extends StatelessWidget {
  const BarisRukun({
    super.key,
    required this.judul,
    this.keterangan,
    this.ikon,
    this.gradient,
    this.ekor,
    this.onTap,
    this.destruktif = false,
  });

  final String judul;
  final String? keterangan;
  final IconData? ikon;

  /// Warna ikon. Bila kosong, ikon tampil netral — sebagian besar baris
  /// memang tidak perlu warna.
  final Gradient? gradient;

  final Widget? ekor;
  final VoidCallback? onTap;

  /// Aksi merusak: teks dan ikon memakai gradient bahaya.
  final bool destruktif;

  @override
  Widget build(BuildContext context) {
    final g = context.gradients;
    final warnaJudul =
        destruktif ? g.bahaya.colors.first : context.warna.onSurface;

    return Semantics(
      button: onTap != null,
      label: judul,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Jarak.lg, vertical: Jarak.md),
          child: Row(
            children: [
              if (ikon != null) ...[
                _Lencana(
                  ikon: ikon!,
                  gradient: destruktif ? g.bahaya : gradient,
                ),
                const SizedBox(width: Jarak.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      style: RukunText.callout.copyWith(
                        color: warnaJudul,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (keterangan != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        keterangan!,
                        style: RukunText.footnote
                            .copyWith(color: context.teksTersier),
                      ),
                    ],
                  ],
                ),
              ),
              if (ekor != null) ...[
                const SizedBox(width: Jarak.md),
                ekor!,
              ] else if (onTap != null) ...[
                const SizedBox(width: Jarak.sm),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: context.teksTersier),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Ikon dalam kotak lembut 32×32.
class _Lencana extends StatelessWidget {
  const _Lencana({required this.ikon, this.gradient});

  final IconData ikon;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final warna = gradient is LinearGradient
        ? (gradient! as LinearGradient).colors.first
        : null;

    return Container(
      width: 32,
      height: 32,
      decoration: Bentuk.dekorasi(
        radius: Sudut.xs,
        warna: (warna ?? context.warna.onSurface).withValues(alpha: 0.10),
      ),
      child: Icon(ikon, size: 18, color: warna ?? context.teksSekunder),
    );
  }
}

/// Kartu angka ringkas — dipakai berdampingan dua kolom.
///
/// Menggantikan kartu raksasa satu-per-baris: angka yang sama terbaca,
/// tapi layar tidak lagi habis oleh dua blok besar.
class KartuAngka extends StatelessWidget {
  const KartuAngka({
    super.key,
    required this.nilai,
    required this.label,
    required this.gradient,
    this.satuan,
    this.ikon,
    this.catatan,
  });

  final String nilai;
  final String label;
  final Gradient gradient;
  final String? satuan;
  final IconData? ikon;
  final String? catatan;

  @override
  Widget build(BuildContext context) {
    return KartuRukun(
      padding: const EdgeInsets.all(Jarak.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (ikon != null) ...[
                Icon(ikon, size: 14, color: context.teksTersier),
                const SizedBox(width: Jarak.xs),
              ],
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style:
                      RukunText.caption.copyWith(color: context.teksTersier),
                ),
              ),
            ],
          ),
          const SizedBox(height: Jarak.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: TeksGradient(
                  nilai,
                  gradient: gradient,
                  style: RukunText.angkaSedang,
                ),
              ),
              if (satuan != null) ...[
                const SizedBox(width: Jarak.xs),
                Text(
                  satuan!,
                  style: RukunText.subhead
                      .copyWith(color: context.teksSekunder),
                ),
              ],
            ],
          ),
          if (catatan != null) ...[
            const SizedBox(height: Jarak.sm),
            Text(
              catatan!,
              style: RukunText.footnote.copyWith(color: context.teksTersier),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pil kecil untuk status dan label.
class PilRukun extends StatelessWidget {
  const PilRukun(
    this.teks, {
    super.key,
    this.gradient,
    this.ikon,
    this.padat = false,
    this.warnaTeks,
  });

  final String teks;
  final Gradient? gradient;
  final IconData? ikon;

  /// Versi tanpa isian warna — untuk label netral.
  final bool padat;

  /// Warna teks di atas isian berwarna.
  ///
  /// Wajib diisi kalau gradientnya bisa berupa warna tim: putih gagal
  /// kontras 4.5:1 di atas kuning (DESIGN.md §2.7), dan pil yang memaksa
  /// putih membuat labelnya nyaris tak terbaca.
  final Color? warnaTeks;

  @override
  Widget build(BuildContext context) {
    final berwarna = gradient != null && !padat;
    final warna =
        berwarna ? (warnaTeks ?? Colors.white) : context.teksSekunder;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Jarak.md, vertical: Jarak.xs + 1),
      decoration: ShapeDecoration(
        gradient: berwarna ? gradient : null,
        color: berwarna
            ? null
            : (context.modeGelap
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.05)),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon != null) ...[
            Icon(ikon, size: 13, color: warna),
            const SizedBox(width: Jarak.xs),
          ],
          Text(teks, style: RukunText.caption.copyWith(color: warna)),
        ],
      ),
    );
  }
}

/// Tampilan saat belum ada apa-apa.
///
/// Layar kosong tanpa penjelasan terasa seperti aplikasi rusak. Setiap
/// keadaan kosong di Rukun menyebut satu langkah berikutnya — dan langkah
/// itu selalu boleh ditunda.
class KeadaanKosong extends StatelessWidget {
  const KeadaanKosong({
    super.key,
    required this.ikon,
    required this.judul,
    required this.pesan,
    this.aksi,
  });

  final IconData ikon;
  final String judul;
  final String pesan;
  final Widget? aksi;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Jarak.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: Gerak.halus,
              width: 64,
              height: 64,
              decoration: Bentuk.dekorasi(
                radius: Sudut.lg,
                warna: context.modeGelap
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
              ),
              child: Icon(ikon, size: 28, color: context.teksTersier),
            ),
            const SizedBox(height: Jarak.xl),
            Text(judul, style: RukunText.judul3, textAlign: TextAlign.center),
            const SizedBox(height: Jarak.sm),
            Text(
              pesan,
              textAlign: TextAlign.center,
              style: RukunText.subhead.copyWith(color: context.teksSekunder),
            ),
            if (aksi != null) ...[
              const SizedBox(height: Jarak.xl),
              aksi!,
            ],
          ],
        ),
      ),
    );
  }
}
