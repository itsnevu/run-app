import 'package:flutter/material.dart';

import '../../core/theme/rukun_spacing.dart';
import '../../core/theme/rukun_theme.dart';
import '../../core/theme/rukun_typography.dart';
import '../../core/util/bentuk.dart';
import 'gradient_button.dart';
import 'kolom_teks.dart';

/// Dialog konfirmasi untuk aksi yang tidak bisa dibatalkan.
///
/// Hanya dipakai kalau langkahnya benar-benar permanen. Konfirmasi yang
/// dihamburkan mengajari pengguna menekan "Ya" tanpa membaca.
class DialogKonfirmasi extends StatelessWidget {
  const DialogKonfirmasi({
    super.key,
    required this.judul,
    required this.pesan,
    required this.labelLanjut,
    this.destruktif = false,
  });

  final String judul;
  final String pesan;
  final String labelLanjut;
  final bool destruktif;

  static Future<bool> tampilkan(
    BuildContext context, {
    required String judul,
    required String pesan,
    required String labelLanjut,
    bool destruktif = false,
  }) async {
    final hasil = await showDialog<bool>(
      context: context,
      builder: (_) => DialogKonfirmasi(
        judul: judul,
        pesan: pesan,
        labelLanjut: labelLanjut,
        destruktif: destruktif,
      ),
    );
    return hasil ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(Jarak.xxl),
      child: Container(
        padding: const EdgeInsets.all(Jarak.xxl),
        decoration: Bentuk.dekorasi(
          radius: Sudut.xl,
          gradient: context.gradients.permukaanTinggi,
          bayangan: Elevasi.tiga,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(judul, style: RukunText.judul3),
            const SizedBox(height: Jarak.sm),
            Text(
              pesan,
              style: RukunText.subhead.copyWith(color: context.teksSekunder),
            ),
            const SizedBox(height: Jarak.xl),
            TombolRukun(
              label: labelLanjut,
              varian:
                  destruktif ? VarianTombol.destruktif : VarianTombol.primer,
              onTap: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: Jarak.sm),
            TombolRukun(
              label: 'Batal',
              varian: VarianTombol.hantu,
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lembar kecil untuk mengubah satu isian teks — misalnya nama panggilan.
class LembarIsian extends StatefulWidget {
  const LembarIsian({
    super.key,
    required this.judul,
    required this.petunjuk,
    this.nilaiAwal = '',
    this.labelSimpan = 'Simpan',
  });

  final String judul;
  final String petunjuk;
  final String nilaiAwal;
  final String labelSimpan;

  static Future<String?> tampilkan(
    BuildContext context, {
    required String judul,
    required String petunjuk,
    String nilaiAwal = '',
    String labelSimpan = 'Simpan',
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LembarIsian(
        judul: judul,
        petunjuk: petunjuk,
        nilaiAwal: nilaiAwal,
        labelSimpan: labelSimpan,
      ),
    );
  }

  @override
  State<LembarIsian> createState() => _LembarIsianState();
}

class _LembarIsianState extends State<LembarIsian> {
  late final _kendali = TextEditingController(text: widget.nilaiAwal);

  @override
  void dispose() {
    _kendali.dispose();
    super.dispose();
  }

  void _simpan() => Navigator.of(context).pop(_kendali.text.trim());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: Bentuk.dekorasi(
          radius: Sudut.xxl,
          gradient: context.gradients.permukaanTinggi,
        ),
        padding: const EdgeInsets.fromLTRB(
            Jarak.tepiLayar, Jarak.xxl, Jarak.tepiLayar, Jarak.xxl),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.judul, style: RukunText.judul3),
              const SizedBox(height: Jarak.lg),
              KolomTeksRukun(
                kendali: _kendali,
                petunjuk: widget.petunjuk,
                kapitalisasi: TextCapitalization.words,
                aksi: TextInputAction.done,
                fokusOtomatis: true,
                onKirim: (_) => _simpan(),
              ),
              const SizedBox(height: Jarak.xl),
              TombolRukun(label: widget.labelSimpan, onTap: _simpan),
            ],
          ),
        ),
      ),
    );
  }
}
