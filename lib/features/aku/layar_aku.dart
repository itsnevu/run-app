import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/rukun_colors.dart';
import '../../core/theme/rukun_spacing.dart';
import '../../core/theme/rukun_theme.dart';
import '../../core/theme/rukun_typography.dart';
import '../../domain/model/kelurahan.dart';
import '../../shared/pesan_izin.dart';
import '../../shared/widgets/daftar_rukun.dart';
import '../../shared/widgets/dialog_konfirmasi.dart';
import '../../shared/widgets/frosted_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../state/akun.dart';
import '../../state/aksi_profil.dart';
import '../../state/penyedia.dart';
import '../masuk/layar_masuk.dart';

/// Layar Aku. DESIGN.md §7.6
///
/// Tiga hal, dalam urutan ini: siapa kamu, apa yang kamu punya, dan apa yang
/// aplikasi ini simpan tentang kamu.
///
/// Di sinilah — dan **hanya** di sini — akun ditawarkan. Tidak ada layar
/// masuk di pintu depan, tidak ada fitur yang dikunci sampai mendaftar.
/// Selain lebih sopan, itu syarat App Store §5.1.1(v).
class LayarAku extends ConsumerStatefulWidget {
  const LayarAku({super.key});

  @override
  ConsumerState<LayarAku> createState() => _LayarAkuState();
}

class _LayarAkuState extends ConsumerState<LayarAku> {
  bool _sibuk = false;

  void _pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(teks), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _gantiNama(String sekarang) async {
    final nama = await LembarIsian.tampilkan(
      context,
      judul: 'Tetanggamu lihat kamu sebagai siapa?',
      petunjuk: 'Nama panggilan',
      nilaiAwal: sekarang,
    );
    if (nama == null || nama.isEmpty) return;
    await ref.read(aksiProfilProvider).gantiNama(nama);
  }

  Future<void> _nyalakanLokasi() async {
    setState(() => _sibuk = true);
    final izin = await ref.read(aksiProfilProvider).nyalakanLokasi();
    if (!mounted) return;
    setState(() => _sibuk = false);

    if (izin.bolehMelacak) {
      _pesan('Lokasi nyala. Kelurahanmu ketemu.');
      return;
    }

    // Jangan seret orang ke pengaturan sistem tanpa diminta — tawarkan
    // tombolnya, biarkan dia yang memutuskan.
    await tampilkanPesanIzin(context, ref.read(lokasiProvider), izin);
  }

  Future<void> _masuk() async {
    final berhasil = await LembarMasuk.tampilkan(context);
    if (berhasil == true) _pesan('Kamu udah masuk. Progresmu ikut kebawa.');
  }

  Future<void> _keluar() async {
    final ya = await DialogKonfirmasi.tampilkan(
      context,
      judul: 'Keluar dari akun?',
      pesan: 'Kamu tetap bisa pakai Rukun sebagai tamu. Data di server '
          'nggak kehapus.',
      labelLanjut: 'Keluar',
    );
    if (!ya || !mounted) return;

    try {
      await ref.read(akunProvider.notifier).keluar();
      _pesan('Kamu keluar dari akun.');
    } on GagalAkun catch (e) {
      _pesan(e.pesan);
    }
  }

  Future<void> _hapusAkun() async {
    final ya = await DialogKonfirmasi.tampilkan(
      context,
      judul: 'Hapus akun selamanya?',
      pesan: 'Profil, Jejak, dan seluruh lintasanmu di server dihapus '
          'permanen. Ini nggak bisa dibatalkan.',
      labelLanjut: 'Hapus akun',
      destruktif: true,
    );
    if (!ya || !mounted) return;

    setState(() => _sibuk = true);
    try {
      await ref.read(akunProvider.notifier).hapusAkun();
      await ref.read(aksiProfilProvider).hapusDataPerangkat();
      _pesan('Akunmu udah dihapus.');
    } on GagalAkun catch (e) {
      _pesan(e.pesan);
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Future<void> _hapusDataPerangkat() async {
    final ya = await DialogKonfirmasi.tampilkan(
      context,
      judul: 'Hapus data di HP ini?',
      pesan: 'Jejak, sesi, dan zona privat yang tersimpan di perangkat ini '
          'dihapus. Kalau kamu punya akun, data di server tetap aman.',
      labelLanjut: 'Hapus data',
      destruktif: true,
    );
    if (!ya || !mounted) return;

    await ref.read(aksiProfilProvider).hapusDataPerangkat();
    _pesan('Data di perangkat ini udah dibersihin.');
  }

  @override
  Widget build(BuildContext context) {
    final profil = ref.watch(profilProvider).valueOrNull;
    final jejak = ref.watch(jejakProvider).valueOrNull;
    final hariAktif = ref.watch(hariAktifProvider).valueOrNull;
    final kelurahan = ref.watch(kelurahanSayaProvider).valueOrNull;
    final zona = ref.watch(zonaPrivatProvider).valueOrNull;
    final akun = ref.watch(akunProvider);
    final g = context.gradients;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          Jarak.tepiLayar, Jarak.lg, Jarak.tepiLayar, 120),
      children: [
        _Kepala(
          nama: profil?.nama ?? 'Kamu',
          huruf: profil?.huruf ?? '?',
          kelurahan: kelurahan,
          tamu: akun.tamu,
          onGantiNama: () => _gantiNama(profil?.nama ?? ''),
        ),
        const SizedBox(height: Jarak.antarBagian),

        // ── Angka. Dua kartu ringkas, bukan dua blok raksasa ──────────
        // IntrinsicHeight: dua kartu bersebelahan harus setinggi yang
        // tertinggi, kalau tidak catatan di bawahnya bikin baris ini pincang.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: KartuAngka(
                  nilai: '${hariAktif ?? 0}',
                  satuan: '/ 7',
                  label: 'HARI HADIR',
                  ikon: Icons.public_rounded,
                  gradient: g.tumbuh,
                  catatan: 'Satu-satunya angka yang dilihat orang lain.',
                ),
              ),
              const SizedBox(width: Jarak.antarKartu),
              Expanded(
                child: KartuAngka(
                  nilai: '${jejak?.length ?? 0}',
                  label: 'PETAK DIBUKA',
                  ikon: Icons.lock_outline_rounded,
                  gradient: g.fajar,
                  catatan: 'Privat. Nggak pernah reset.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Jarak.antarBagian),

        // ── Akun. Ditawarkan, tidak pernah dipaksakan ─────────────────
        const JudulBagian(
          'Akun',
          keterangan: 'Opsional — Rukun jalan penuh tanpa ini.',
        ),
        if (akun.masuk)
          GrupBaris(
            baris: [
              BarisRukun(
                judul: akun.email ?? 'Akun aktif',
                keterangan: 'Progresmu tersimpan di server',
                ikon: Icons.verified_user_outlined,
                gradient: g.tumbuh,
              ),
              BarisRukun(
                judul: 'Keluar',
                ikon: Icons.logout_rounded,
                onTap: _sibuk ? null : _keluar,
              ),
              BarisRukun(
                judul: 'Hapus akun',
                keterangan: 'Menghapus semua datamu di server, permanen',
                ikon: Icons.person_remove_outlined,
                destruktif: true,
                onTap: _sibuk ? null : _hapusAkun,
              ),
            ],
          )
        else
          _KartuTamu(onMasuk: _sibuk ? null : _masuk),
        const SizedBox(height: Jarak.antarBagian),

        // ── Kelurahan. Muncul hanya kalau memang belum ada ────────────
        if (kelurahan == null) ...[
          const JudulBagian(
            'Kelurahan',
            keterangan: 'Nentuin tim kamu, dan bikin kabut bisa dibuka.',
          ),
          GrupBaris(
            baris: [
              BarisRukun(
                judul: _sibuk ? 'Sebentar...' : 'Aktifkan lokasi',
                keterangan: 'Kecepatanmu tetap nggak dibagikan ke siapa pun',
                ikon: Icons.my_location_rounded,
                gradient: g.terang,
                onTap: _sibuk ? null : _nyalakanLokasi,
              ),
            ],
          ),
          const SizedBox(height: Jarak.antarBagian),
        ],

        // ── Privasi ───────────────────────────────────────────────────
        const JudulBagian(
          'Privasi',
          keterangan: 'Keputusan produk, bukan pengaturan yang bisa lupa.',
        ),
        GrupBaris(
          baris: [
            const BarisRukun(
              judul: 'Kecepatan & pace disembunyikan',
              keterangan: 'Nggak pernah muncul di permukaan publik mana pun',
              ikon: Icons.speed_rounded,
            ),
            BarisRukun(
              judul: 'Radius buta 150 m di sekitar rumah',
              keterangan: zona == null || zona.isEmpty
                  ? 'Nyala otomatis setelah sesi pertamamu'
                  : 'Aktif — ${zona.length} zona tersimpan di HP ini aja',
              ikon: Icons.home_outlined,
              gradient: zona != null && zona.isNotEmpty ? g.tumbuh : null,
            ),
            const BarisRukun(
              judul: 'Rute mentah nggak pernah dikirim',
              keterangan: 'Server cuma tahu kode petak selebar ~132 m',
              ikon: Icons.route_outlined,
            ),
          ],
        ),
        const SizedBox(height: Jarak.antarBagian),

        // ── Data ──────────────────────────────────────────────────────
        const JudulBagian('Data'),
        GrupBaris(
          baris: [
            BarisRukun(
              judul: 'Hapus data di HP ini',
              keterangan: 'Jejak, sesi, dan zona privat di perangkat',
              ikon: Icons.delete_outline_rounded,
              destruktif: true,
              onTap: _sibuk ? null : _hapusDataPerangkat,
            ),
          ],
        ),
        const SizedBox(height: Jarak.xxxl),
        Center(
          child: Text(
            'Rukun · Kabut & Cahaya',
            style: RukunText.footnote.copyWith(color: context.teksTersier),
          ),
        ),
      ],
    );
  }
}

/// Kepala layar: siapa kamu, dan di tim mana.
class _Kepala extends StatelessWidget {
  const _Kepala({
    required this.nama,
    required this.huruf,
    required this.kelurahan,
    required this.tamu,
    required this.onGantiNama,
  });

  final String nama;
  final String huruf;
  final Kelurahan? kelurahan;
  final bool tamu;
  final VoidCallback onGantiNama;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: kelurahan?.warna.gradient ?? context.gradients.fajar,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              huruf,
              style: RukunText.judul2.copyWith(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: Jarak.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nama,
                  style: RukunText.judul2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: Jarak.sm),
              Wrap(
                spacing: Jarak.xs,
                runSpacing: Jarak.xs,
                children: [
                  if (kelurahan != null)
                    PilRukun(
                      'Kelurahan ${kelurahan!.nama}',
                      gradient: kelurahan!.warna.gradient,
                      // Kuning gagal kontras dengan putih. DESIGN.md §2.7
                      warnaTeks: kelurahan!.warna.teksPutihAman
                          ? Colors.white
                          : RukunColors.teksPrimerTerang,
                    )
                  else
                    const PilRukun('Belum ada kelurahan'),
                  if (tamu) const PilRukun('Tamu', ikon: Icons.person_outline),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: Jarak.sm),
        GestureDetector(
          onTap: onGantiNama,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.modeGelap
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.edit_outlined,
                size: 17, color: context.teksSekunder),
          ),
        ),
      ],
    );
  }
}

/// Tawaran akun untuk pengguna tamu.
///
/// Nadanya sengaja bukan peringatan: tidak ada yang rusak, tidak ada yang
/// terkunci. Ini keuntungan yang ditawarkan, bukan pagar yang dipasang.
class _KartuTamu extends StatelessWidget {
  const _KartuTamu({this.onMasuk});

  final VoidCallback? onMasuk;

  @override
  Widget build(BuildContext context) {
    return KartuRukun(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: context.gradients.terang,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_upload_outlined,
                    size: 19, color: Colors.white),
              ),
              const SizedBox(width: Jarak.md),
              Expanded(
                child: Text('Simpan progresmu', style: RukunText.headline),
              ),
            ],
          ),
          const SizedBox(height: Jarak.md),
          Text(
            'Sekarang semua tersimpan di HP ini. Kalau kamu bikin akun, '
            'Jejakmu ikut pindah waktu ganti HP — dan klaim bareng tetangga '
            'bisa jalan.',
            style: RukunText.subhead.copyWith(color: context.teksSekunder),
          ),
          const SizedBox(height: Jarak.lg),
          TombolRukun(
            label: 'Masuk atau daftar',
            padat: true,
            onTap: onMasuk,
          ),
          const SizedBox(height: Jarak.md),
          Text(
            'Nggak wajib. Semua fitur tetap kebuka tanpa akun.',
            style: RukunText.footnote.copyWith(color: context.teksTersier),
          ),
        ],
      ),
    );
  }
}
