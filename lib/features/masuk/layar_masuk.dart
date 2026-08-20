import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/rukun_motion.dart';
import '../../core/theme/rukun_spacing.dart';
import '../../core/theme/rukun_theme.dart';
import '../../core/theme/rukun_typography.dart';
import '../../core/util/bentuk.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/kolom_teks.dart';
import '../../state/akun.dart';
import '../../state/aksi_profil.dart';

/// Lembar masuk & daftar. **Selalu dipanggil pengguna, tidak pernah memaksa.**
///
/// App Store Review Guideline §5.1.1(v) melarang aplikasi mewajibkan akun
/// untuk fitur yang tidak membutuhkannya. Rukun mengambil sikap yang lebih
/// jauh dari sekadar lolos tinjauan: seluruh mekanik inti — membuka petak,
/// Jejak pribadi, misi — jalan penuh tanpa akun. Lembar ini hanya muncul
/// kalau pengguna sendiri yang menekan "Masuk" di tab Aku.
///
/// Karena itu tombol tutupnya selalu ada, tidak ada layar yang menghadang,
/// dan tidak ada satu pun fitur yang berubah abu-abu tanpa akun.
class LembarMasuk extends ConsumerStatefulWidget {
  const LembarMasuk({super.key});

  /// Menampilkan lembar. Mengembalikan true bila pengguna berhasil masuk.
  static Future<bool?> tampilkan(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LembarMasuk(),
    );
  }

  @override
  ConsumerState<LembarMasuk> createState() => _LembarMasukState();
}

class _LembarMasukState extends ConsumerState<LembarMasuk> {
  final _email = TextEditingController();
  final _sandi = TextEditingController();

  int _mode = 0; // 0 = masuk, 1 = daftar
  bool _sibuk = false;
  String? _galat;
  bool _perluKonfirmasi = false;

  bool get _daftar => _mode == 1;

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    final email = _email.text.trim();
    final sandi = _sandi.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _galat = 'Emailnya belum kelihatan benar.');
      return;
    }
    if (sandi.length < 8) {
      setState(() => _galat = 'Kata sandi minimal 8 karakter.');
      return;
    }

    setState(() {
      _sibuk = true;
      _galat = null;
    });

    final akun = ref.read(akunProvider.notifier);
    try {
      if (_daftar) {
        final perlu = await akun.daftar(email: email, sandi: sandi);
        if (perlu) {
          if (mounted) setState(() => _perluKonfirmasi = true);
          return;
        }
      } else {
        await akun.masuk(email: email, sandi: sandi);
      }

      // Progres tamu ikut pindah — janji "nggak ada yang hilang" harus
      // ditepati di sini, bukan di halaman pemasaran.
      try {
        await ref.read(aksiProfilProvider).selarasSetelahMasuk();
      } catch (_) {
        // Selaras gagal bukan alasan menggagalkan masuk: data lokal tetap
        // utuh dan bisa diangkat lagi di percobaan berikutnya.
      }

      if (mounted) Navigator.of(context).pop(true);
    } on GagalAkun catch (e) {
      if (mounted) setState(() => _galat = e.pesan);
    } catch (e) {
      if (mounted) setState(() => _galat = 'Ada yang gagal. Coba lagi ya.');
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bisa = ref.watch(akunProvider).bisaPunyaAkun;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: double.infinity,
        decoration: Bentuk.dekorasi(
          radius: Sudut.xxl,
          gradient: context.gradients.permukaanTinggi,
        ),
        padding: const EdgeInsets.fromLTRB(
            Jarak.tepiLayar, Jarak.md, Jarak.tepiLayar, Jarak.xxl),
        child: SafeArea(
          top: false,
          child: AnimatedSize(
            duration: Gerak.sigap,
            curve: Gerak.sigapKurva,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: ShapeDecoration(
                      color: context.teksTersier.withValues(alpha: 0.4),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: Jarak.xxl),
                if (_perluKonfirmasi)
                  _KonfirmasiEmail(email: _email.text.trim())
                else if (!bisa)
                  const _BelumAktif()
                else
                  ..._formulir(context),
                const SizedBox(height: Jarak.lg),
                TombolRukun(
                  label: _perluKonfirmasi || !bisa ? 'Tutup' : 'Nanti aja',
                  varian: VarianTombol.hantu,
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _formulir(BuildContext context) => [
        Text(
          _daftar ? 'Bikin akun Rukun' : 'Masuk ke Rukun',
          style: RukunText.judul2,
        ),
        const SizedBox(height: Jarak.sm),
        Text(
          'Akun bikin Jejakmu aman waktu ganti HP, dan bikin klaim bareng '
          'tetangga jalan.\n\nNggak wajib — semua fitur tetap kebuka tanpa ini.',
          style: RukunText.subhead.copyWith(color: context.teksSekunder),
        ),
        const SizedBox(height: Jarak.xl),
        PilihanSegmen(
          label: const ['Masuk', 'Daftar'],
          terpilih: _mode,
          onPilih: (i) => setState(() {
            _mode = i;
            _galat = null;
          }),
        ),
        const SizedBox(height: Jarak.lg),
        KolomTeksRukun(
          kendali: _email,
          petunjuk: 'Email',
          ikon: Icons.alternate_email_rounded,
          jenis: TextInputType.emailAddress,
          otomatis: const [AutofillHints.email],
          aktif: !_sibuk,
        ),
        const SizedBox(height: Jarak.md),
        KolomTeksRukun(
          kendali: _sandi,
          petunjuk: 'Kata sandi',
          ikon: Icons.lock_outline_rounded,
          rahasia: true,
          aksi: TextInputAction.done,
          otomatis: [
            _daftar ? AutofillHints.newPassword : AutofillHints.password,
          ],
          onKirim: (_) => _kirim(),
          aktif: !_sibuk,
        ),
        if (_galat != null) ...[
          const SizedBox(height: Jarak.md),
          _PesanGalat(_galat!),
        ],
        const SizedBox(height: Jarak.xl),
        TombolRukun(
          label: _sibuk
              ? 'Sebentar...'
              : (_daftar ? 'Bikin akun' : 'Masuk'),
          onTap: _sibuk ? null : _kirim,
        ),
        const SizedBox(height: Jarak.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 14, color: context.teksTersier),
            const SizedBox(width: Jarak.xs),
            Expanded(
              child: Text(
                'Kecepatan dan rutemu nggak pernah ikut terkirim — '
                'kolomnya memang nggak ada di server.',
                style:
                    RukunText.footnote.copyWith(color: context.teksTersier),
              ),
            ),
          ],
        ),
      ];
}

/// Ditampilkan saat build ini memang belum punya backend.
///
/// Lebih baik jujur daripada memberi tombol yang tidak menuju ke mana pun.
class _BelumAktif extends StatelessWidget {
  const _BelumAktif();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Akun belum aktif di versi ini', style: RukunText.judul3),
        const SizedBox(height: Jarak.sm),
        Text(
          'Semua progresmu tersimpan di HP ini dan tetap jalan penuh: '
          'petak kebuka, Jejak kecatat, misi tetap ada.',
          style: RukunText.subhead.copyWith(color: context.teksSekunder),
        ),
      ],
    );
  }
}

class _KonfirmasiEmail extends StatelessWidget {
  const _KonfirmasiEmail({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: Bentuk.dekorasi(
            radius: Sudut.md,
            gradient: context.gradients.tumbuh,
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              color: Colors.white, size: 24),
        ),
        const SizedBox(height: Jarak.lg),
        Text('Cek email kamu', style: RukunText.judul3),
        const SizedBox(height: Jarak.sm),
        Text(
          'Kami kirim tautan konfirmasi ke $email. Buka tautannya, '
          'terus masuk lagi dari sini.',
          style: RukunText.subhead.copyWith(color: context.teksSekunder),
        ),
      ],
    );
  }
}

class _PesanGalat extends StatelessWidget {
  const _PesanGalat(this.pesan);

  final String pesan;

  @override
  Widget build(BuildContext context) {
    final warna = context.gradients.bahaya.colors.first;

    return Container(
      padding: const EdgeInsets.all(Jarak.md),
      decoration: Bentuk.dekorasi(
        radius: Sudut.sm,
        warna: warna.withValues(alpha: 0.10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: warna),
          const SizedBox(width: Jarak.sm),
          Expanded(
            child: Text(
              pesan,
              style: RukunText.footnote.copyWith(color: warna),
            ),
          ),
        ],
      ),
    );
  }
}
