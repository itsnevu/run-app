import 'package:flutter/material.dart';

import '../../core/theme/rukun_spacing.dart';
import '../../core/theme/rukun_theme.dart';
import '../../core/theme/rukun_typography.dart';
import '../../core/util/bentuk.dart';

/// Kolom isian Rukun.
///
/// Isian di aplikasi ini jarang muncul, dan itu disengaja — tapi yang muncul
/// harus terasa setenang komponen lain: tanpa garis tepi keras, tanpa label
/// melayang, cukup permukaan lembut dengan sudut kontinu.
class KolomTeksRukun extends StatelessWidget {
  const KolomTeksRukun({
    super.key,
    required this.kendali,
    required this.petunjuk,
    this.ikon,
    this.rahasia = false,
    this.jenis = TextInputType.text,
    this.aksi = TextInputAction.next,
    this.kapitalisasi = TextCapitalization.none,
    this.otomatis,
    this.onKirim,
    this.aktif = true,
  });

  final TextEditingController kendali;
  final String petunjuk;
  final IconData? ikon;
  final bool rahasia;
  final TextInputType jenis;
  final TextInputAction aksi;
  final TextCapitalization kapitalisasi;
  final Iterable<String>? otomatis;
  final ValueChanged<String>? onKirim;
  final bool aktif;

  @override
  Widget build(BuildContext context) {
    final latar = context.modeGelap
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);

    return Container(
      decoration: Bentuk.dekorasi(radius: Sudut.md, warna: latar),
      child: TextField(
        controller: kendali,
        obscureText: rahasia,
        enabled: aktif,
        keyboardType: jenis,
        textInputAction: aksi,
        textCapitalization: kapitalisasi,
        autofillHints: otomatis,
        onSubmitted: onKirim,
        style: RukunText.callout.copyWith(color: context.warna.onSurface),
        cursorColor: context.gradients.terang.colors.first,
        decoration: InputDecoration(
          hintText: petunjuk,
          hintStyle: RukunText.callout.copyWith(color: context.teksTersier),
          prefixIcon: ikon == null
              ? null
              : Icon(ikon, size: 20, color: context.teksTersier),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: Jarak.lg, vertical: Jarak.lg),
        ),
      ),
    );
  }
}

/// Pemilih dua pilihan bergaya segmented control.
///
/// Dipakai untuk Masuk/Daftar: dua jalan yang setara, jadi tidak boleh
/// tampil sebagai satu tombol besar dan satu tautan kecil.
class PilihanSegmen extends StatelessWidget {
  const PilihanSegmen({
    super.key,
    required this.label,
    required this.terpilih,
    required this.onPilih,
  });

  final List<String> label;
  final int terpilih;
  final ValueChanged<int> onPilih;

  @override
  Widget build(BuildContext context) {
    final latar = context.modeGelap
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: ShapeDecoration(color: latar, shape: const StadiumBorder()),
      child: Row(
        children: [
          for (var i = 0; i < label.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onPilih(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: i == terpilih
                        ? (context.modeGelap
                            ? const Color(0xFF2A2F3A)
                            : Colors.white)
                        : null,
                    shape: const StadiumBorder(),
                    shadows: i == terpilih ? Elevasi.satu : null,
                  ),
                  child: Text(
                    label[i],
                    style: RukunText.subhead.copyWith(
                      color: i == terpilih
                          ? context.warna.onSurface
                          : context.teksSekunder,
                      fontWeight:
                          i == terpilih ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
