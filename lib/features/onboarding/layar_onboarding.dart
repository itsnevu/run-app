import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/rukun_colors.dart';
import '../../core/theme/rukun_motion.dart';
import '../../core/theme/rukun_spacing.dart';
import '../../core/theme/rukun_theme.dart';
import '../../core/theme/rukun_typography.dart';
import '../../data/lokasi.dart';
import '../../data/repo/repo_lokal.dart';
import '../../domain/model/kelurahan.dart';
import '../../domain/model/koordinat.dart';
import '../../shared/pesan_izin.dart';
import '../../shared/widgets/frosted_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/kolom_teks.dart';
import '../../state/aksi_profil.dart';
import '../../state/kendali_sesi.dart';
import '../../state/penyedia.dart';
import '../peta/peta_rukun.dart';

/// Tahapan pembuka.
enum _Tahap { sambutan, izin, tim, ajakan, merekam, berhasil }

/// **Pembuka 6 menit.** DESIGN.md §7.1
///
/// Layar paling penting di aplikasi. Data industri: 70–80% pengguna tidak
/// pernah kembali setelah sesi pertama, dan meraih satu pencapaian di hari
/// pertama menaikkan retensi 64%.
///
/// Aturan mutlak yang ditegakkan di sini:
/// - ❌ Tanpa tinggi/berat badan. Selamanya.
/// - ❌ Tanpa "pilih level kebugaran" — itu yang membuat pemula merasa
///      tersisih di detik pertama.
/// - ❌ Tanpa akun. Tidak di sini, tidak di mana pun sebelum pengguna
///      sendiri memintanya. (App Store §5.1.1(v))
/// - ✅ **Setiap langkah bisa dilewati.** Tombol "Lewati" ada di setiap
///      layar, dan "Lihat-lihat dulu" ada sejak detik pertama. Pembuka yang
///      tidak punya pintu keluar bukan sambutan, itu portal.
class LayarOnboarding extends ConsumerStatefulWidget {
  const LayarOnboarding({super.key, this.onSelesai});

  final VoidCallback? onSelesai;

  @override
  ConsumerState<LayarOnboarding> createState() => _LayarOnboardingState();
}

class _LayarOnboardingState extends ConsumerState<LayarOnboarding> {
  _Tahap _tahap = _Tahap.sambutan;
  Koordinat? _posisi;
  Kelurahan? _kelurahan;
  StatusIzin? _izin;
  bool _sibuk = false;
  final _namaKendali = TextEditingController();

  /// Titik acuan sebelum izin diberikan — peta tetap tampil (berkabut penuh)
  /// supaya layar pertama tidak kosong.
  static const _acuan = Koordinat(-6.2264, 106.8556);

  /// Tahap yang punya titik kemajuan dan tombol lewati.
  static const _tahapAwal = [
    _Tahap.sambutan,
    _Tahap.izin,
    _Tahap.tim,
    _Tahap.ajakan,
  ];

  @override
  void dispose() {
    _namaKendali.dispose();
    super.dispose();
  }

  void _ke(_Tahap t) => setState(() => _tahap = t);

  /// Selesai — dengan atau tanpa lokasi, dengan atau tanpa nama.
  Future<void> _masuk() async {
    await ref.read(pembukaSelesaiProvider.notifier).tandai();
    if (!mounted) return;
    widget.onSelesai?.call();
  }

  /// "Lihat-lihat dulu" — masuk sekarang juga, tanpa izin dan tanpa akun.
  Future<void> _lihatDulu() async {
    await ref.read(aksiProfilProvider).masukSebagaiTamu();
    if (!mounted) return;
    widget.onSelesai?.call();
  }

  Future<void> _mintaIzin() async {
    setState(() => _sibuk = true);
    final izin = await ref.read(aksiProfilProvider).nyalakanLokasi();
    if (!mounted) return;

    if (!izin.bolehMelacak) {
      setState(() {
        _izin = izin;
        _sibuk = false;
      });
      return;
    }

    final posisi = await ref.read(lokasiProvider).posisiSekarang() ?? _acuan;
    if (!mounted) return;

    setState(() {
      _posisi = posisi;
      _kelurahan = RepoLokal.kelurahanDari(posisi);
      _izin = izin;
      _sibuk = false;
    });
    _ke(_Tahap.tim);
  }

  Future<void> _bukaPengaturan() async {
    final lokasi = ref.read(lokasiProvider);
    if (_izin == StatusIzin.layananMati) {
      await lokasi.bukaPengaturanLokasi();
    } else {
      await lokasi.bukaPengaturanAplikasi();
    }
  }

  Future<void> _mulaiJalan() async {
    final berhasil = await ref.read(kendaliSesiProvider.notifier).mulai();
    if (!mounted) return;

    // Izin bisa dicabut di antara dua layar, atau "Allow Once" kedaluwarsa.
    // Jarang — tapi kalau terjadi, tombolnya tidak boleh diam saja.
    if (!berhasil) {
      await tampilkanPesanIzin(
        context,
        ref.read(lokasiProvider),
        ref.read(kendaliSesiProvider).izin ?? StatusIzin.ditolak,
      );
      return;
    }
    _ke(_Tahap.merekam);
  }

  Future<void> _selesaikanJalan() async {
    await ref.read(kendaliSesiProvider.notifier).selesai();
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    _ke(_Tahap.berhasil);
  }

  Future<void> _simpanNama() async {
    final nama = _namaKendali.text.trim();
    if (nama.isNotEmpty) {
      await ref.read(aksiProfilProvider).gantiNama(nama);
    }
    await _masuk();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(kendaliSesiProvider);
    final pusat = _posisi ?? _acuan;
    final berkabut = _tahap == _Tahap.sambutan || _tahap == _Tahap.izin;

    return Scaffold(
      body: Stack(
        children: [
          // Peta selalu ada di belakang — kota kamu, tertutup kabut.
          Positioned.fill(
            child: PetaRukun(
              pusat: pusat,
              zoom: 16,
              kabutPenuh: berkabut,
              jejak: status.petakSesi,
              tampilkanTitikPengguna: _tahap != _Tahap.sambutan,
            ),
          ),

          // Peredup dari bawah: teks tetap terbaca di atas peta apa pun,
          // tanpa harus menutupnya dengan panel penuh.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.45, 1.0],
                    colors: [
                      context.warna.surface.withValues(alpha: 0.0),
                      context.warna.surface.withValues(alpha: 0.35),
                      context.warna.surface.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Jarak.tepiLayar),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Kepala(
                      langkah: _tahapAwal.indexOf(_tahap),
                      jumlah: _tahapAwal.length,
                      onLewati: _tahapAwal.contains(_tahap) ? _lewati : null,
                    ),
                    // Layar kecil dengan teks aksesibilitas besar membuat
                    // kolom di bawah melebihi tinggi layar. Digulirkan, bukan
                    // dipotong — tapi tetap dipaksa setinggi layar saat muat,
                    // supaya tata letaknya tidak melompat ke atas.
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, batas) => SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: batas.maxHeight,
                            ),
                            child: AnimatedSwitcher(
                              duration: Gerak.halus,
                              switchInCurve: Gerak.halusKurva,
                              child: _isi(status),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Lewati: kalau kelurahan sudah ketahuan, ia ikut terbawa; kalau belum,
  /// pengguna masuk sebagai tamu tanpa lokasi.
  Future<void> _lewati() => _kelurahan == null ? _lihatDulu() : _masuk();

  Widget _isi(StatusSesi status) => switch (_tahap) {
    _Tahap.sambutan => _Sambutan(
      key: const ValueKey('sambutan'),
      onLanjut: () => _ke(_Tahap.izin),
      onLihatDulu: _lihatDulu,
    ),
    _Tahap.izin => _Izin(
      key: const ValueKey('izin'),
      izin: _izin,
      sibuk: _sibuk,
      onIzinkan: _mintaIzin,
      onPengaturan: _bukaPengaturan,
      onNanti: _lihatDulu,
    ),
    _Tahap.tim => _Tim(
      key: const ValueKey('tim'),
      kelurahan: _kelurahan!,
      onLanjut: () => _ke(_Tahap.ajakan),
    ),
    _Tahap.ajakan => _Ajakan(
      key: const ValueKey('ajakan'),
      onMulai: _mulaiJalan,
      onNanti: _masuk,
    ),
    _Tahap.merekam => _Merekam(
      key: const ValueKey('merekam'),
      status: status,
      onSelesai: _selesaikanJalan,
    ),
    _Tahap.berhasil => _Berhasil(
      key: const ValueKey('berhasil'),
      jumlahPetak: status.petakSesi.length,
      kendali: _namaKendali,
      onSelesai: _simpanNama,
    ),
  };
}

/// Titik kemajuan di kiri, jalan keluar di kanan.
class _Kepala extends StatelessWidget {
  const _Kepala({required this.langkah, required this.jumlah, this.onLewati});

  final int langkah;
  final int jumlah;
  final VoidCallback? onLewati;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          if (langkah >= 0)
            for (var i = 0; i < jumlah; i++)
              AnimatedContainer(
                duration: Gerak.sigap,
                curve: Gerak.sigapKurva,
                margin: const EdgeInsets.only(right: Jarak.xs),
                width: i == langkah ? 20 : 6,
                height: 6,
                decoration: ShapeDecoration(
                  gradient: i == langkah ? context.gradients.terang : null,
                  color: i == langkah
                      ? null
                      : context.teksTersier.withValues(alpha: 0.35),
                  shape: const StadiumBorder(),
                ),
              ),
          const Spacer(),
          if (onLewati != null)
            GestureDetector(
              onTap: onLewati,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Jarak.sm),
                child: Text(
                  'Lewati',
                  style: RukunText.subhead.copyWith(
                    color: context.teksSekunder,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── 0:00 Sambutan ─────────────────────────────────────────────────
class _Sambutan extends StatelessWidget {
  const _Sambutan({
    super.key,
    required this.onLanjut,
    required this.onLihatDulu,
  });

  final VoidCallback onLanjut;
  final VoidCallback onLihatDulu;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TeksGradient(
          'Rukun',
          gradient: context.gradients.terang,
          style: RukunText.display,
        ),
        const SizedBox(height: Jarak.md),
        Text(
          'Kotamu tertutup kabut.\nSetiap langkah membuka cahaya.',
          style: RukunText.judul3.copyWith(color: context.warna.onSurface),
        ),
        const SizedBox(height: Jarak.xxxl),
        TombolRukun(label: 'Mulai', onTap: onLanjut),
        const SizedBox(height: Jarak.sm),
        // Pintu masuk tanpa syarat apa pun — tanpa izin, tanpa akun.
        TombolRukun(
          label: 'Lihat-lihat dulu',
          varian: VarianTombol.hantu,
          onTap: onLihatDulu,
        ),
      ],
    );
  }
}

// ── 0:15 Izin lokasi ──────────────────────────────────────────────
class _Izin extends StatelessWidget {
  const _Izin({
    super.key,
    required this.izin,
    required this.sibuk,
    required this.onIzinkan,
    required this.onPengaturan,
    required this.onNanti,
  });

  final StatusIzin? izin;
  final bool sibuk;
  final VoidCallback onIzinkan;
  final VoidCallback onPengaturan;
  final VoidCallback onNanti;

  bool get _buntu =>
      izin == StatusIzin.ditolakPermanen || izin == StatusIzin.layananMati;

  String get _pesanGagal => switch (izin) {
    StatusIzin.layananMati =>
      'Layanan lokasi di HP kamu lagi mati. Nyalakan dulu ya.',
    StatusIzin.ditolakPermanen =>
      'Izin lokasinya dimatikan permanen. Bisa dinyalakan lagi lewat '
          'Pengaturan.',
    StatusIzin.ditolak =>
      'Belum diizinkan. Kamu tetap bisa masuk dan lihat-lihat dulu.',
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        KartuBuram(
          buram: Buram.tebal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Boleh tahu kamu di mana?', style: RukunText.judul2),
              const SizedBox(height: Jarak.md),
              // Bahasa manusia, bukan bahasa sistem.
              Text(
                'Rukun perlu lokasimu buat membuka kabut di peta.\n\n'
                'Kecepatanmu nggak pernah dibagikan ke siapa pun — '
                'nggak ke tetangga, nggak ke publik.',
                style: RukunText.body.copyWith(color: context.teksSekunder),
              ),
              if (_pesanGagal.isNotEmpty) ...[
                const SizedBox(height: Jarak.lg),
                Text(
                  _pesanGagal,
                  style: RukunText.subhead.copyWith(
                    color: context.gradients.hangus.colors.first,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Jarak.xl),
        TombolRukun(
          label: sibuk
              ? 'Sebentar...'
              : (_buntu ? 'Buka Pengaturan' : 'Izinkan lokasi'),
          onTap: sibuk ? null : (_buntu ? onPengaturan : onIzinkan),
        ),
        const SizedBox(height: Jarak.sm),
        // Menunda izin tidak pernah jadi jalan buntu.
        TombolRukun(
          label: 'Nanti aja',
          varian: VarianTombol.hantu,
          onTap: onNanti,
        ),
      ],
    );
  }
}

// ── 0:30 Tim-mu ───────────────────────────────────────────────────
class _Tim extends StatelessWidget {
  const _Tim({super.key, required this.kelurahan, required this.onLanjut});

  final Kelurahan kelurahan;
  final VoidCallback onLanjut;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        KartuBuram(
          buram: Buram.tebal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Jarak.lg,
                  vertical: Jarak.sm,
                ),
                decoration: ShapeDecoration(
                  gradient: kelurahan.warna.gradient,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Kelurahan ${kelurahan.nama}',
                  style: RukunText.caption.copyWith(
                    // Kuning gagal kontras dengan putih. DESIGN.md §2.7
                    color: kelurahan.warna.teksPutihAman
                        ? Colors.white
                        : RukunColors.teksPrimerTerang,
                  ),
                ),
              ),
              const SizedBox(height: Jarak.lg),
              Text('Ini tim kamu', style: RukunText.judul2),
              const SizedBox(height: Jarak.md),
              // Identitas dan tim diberikan sebelum diminta apa pun.
              Text(
                'Ada ${kelurahan.jumlahAnggota} orang di sini.\n'
                'Kamu yang ke-${kelurahan.jumlahAnggota + 1}.',
                style: RukunText.body.copyWith(color: context.teksSekunder),
              ),
            ],
          ),
        ),
        const SizedBox(height: Jarak.xl),
        TombolRukun(label: 'Lanjut', onTap: onLanjut),
        const SizedBox(height: Jarak.lg),
      ],
    );
  }
}

// ── 0:45 Ajakan pertama ───────────────────────────────────────────
class _Ajakan extends StatelessWidget {
  const _Ajakan({super.key, required this.onMulai, required this.onNanti});

  final VoidCallback onMulai;
  final VoidCallback onNanti;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        KartuBuram(
          buram: Buram.tebal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // BUKAN 5K. BUKAN 30 MENIT. Lima menit jalan kaki.
              Text('Jalan 5 menit', style: RukunText.judul1),
              const SizedBox(height: Jarak.md),
              Text(
                'Itu aja. Cukup buat membuka petak pertamamu.\n\n'
                'Nggak perlu ganti baju, nggak perlu sepatu khusus.',
                style: RukunText.body.copyWith(color: context.teksSekunder),
              ),
            ],
          ),
        ),
        const SizedBox(height: Jarak.xl),
        TombolRukun(
          label: 'Mulai jalan',
          ikon: Icons.directions_walk_rounded,
          onTap: onMulai,
        ),
        const SizedBox(height: Jarak.sm),
        TombolRukun(
          label: 'Nanti aja',
          varian: VarianTombol.hantu,
          onTap: onNanti,
        ),
      ],
    );
  }
}

// ── Merekam ───────────────────────────────────────────────────────
class _Merekam extends StatelessWidget {
  const _Merekam({super.key, required this.status, required this.onSelesai});

  final StatusSesi status;
  final VoidCallback onSelesai;

  @override
  Widget build(BuildContext context) {
    final jumlah = status.petakSesi.length;
    final menit = status.durasi.inMinutes;
    final detik = status.durasi.inSeconds % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        KartuBuram(
          buram: Buram.sedang,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${menit.toString().padLeft(2, '0')}:'
                      '${detik.toString().padLeft(2, '0')}',
                      style: RukunText.angkaSedang.copyWith(
                        color: context.warna.onSurface,
                      ),
                    ),
                    Text(
                      'waktu jalan',
                      style: RukunText.caption.copyWith(
                        color: context.teksSekunder,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TeksGradient(
                    '$jumlah',
                    gradient: context.gradients.fajar,
                    style: RukunText.angkaSedang,
                  ),
                  Text(
                    'petak terbuka',
                    style: RukunText.caption.copyWith(
                      color: context.teksSekunder,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (jumlah > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: Jarak.lg),
            child: KartuBuram(
              buram: Buram.tipis,
              padding: const EdgeInsets.symmetric(
                horizontal: Jarak.xl,
                vertical: Jarak.lg,
              ),
              child: Text(
                'Kabut kebuka. Petak ini punya kamu selamanya.',
                style: RukunText.subhead.copyWith(
                  color: context.warna.onSurface,
                ),
              ),
            ),
          ),
        TombolRukun(
          label: jumlah > 0 ? 'Selesai' : 'Jalan dulu ya...',
          onTap: jumlah > 0 ? onSelesai : null,
        ),
        const SizedBox(height: Jarak.lg),
      ],
    );
  }
}

// ── Berhasil ──────────────────────────────────────────────────────
class _Berhasil extends StatelessWidget {
  const _Berhasil({
    super.key,
    required this.jumlahPetak,
    required this.kendali,
    required this.onSelesai,
  });

  final int jumlahPetak;
  final TextEditingController kendali;
  final VoidCallback onSelesai;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const SizedBox(height: Jarak.xxxl),
        KartuBuram(
          buram: Buram.tebal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TeksGradient(
                    '+$jumlahPetak',
                    gradient: context.gradients.fajar,
                    style: RukunText.angkaBesar,
                  ),
                  const SizedBox(width: Jarak.sm),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('petak', style: RukunText.judul3),
                  ),
                ],
              ),
              const SizedBox(height: Jarak.sm),
              Text(
                'Petak ini milik kamu selamanya — nggak bisa direbut '
                'siapa pun.',
                style: RukunText.subhead.copyWith(color: context.teksSekunder),
              ),
              const SizedBox(height: Jarak.xl),
              const Divider(),
              const SizedBox(height: Jarak.xl),
              // Nama diminta SETELAH nilai diberikan, bukan sebelumnya —
              // dan tetap boleh dikosongkan.
              Text(
                'Tetanggamu bakal lihat kamu sebagai siapa?',
                style: RukunText.headline,
              ),
              const SizedBox(height: Jarak.md),
              KolomTeksRukun(
                kendali: kendali,
                petunjuk: 'Nama panggilan (boleh dilewati)',
                kapitalisasi: TextCapitalization.words,
                aksi: TextInputAction.done,
                onKirim: (_) => onSelesai(),
              ),
            ],
          ),
        ),
        const SizedBox(height: Jarak.xl),
        TombolRukun(label: 'Masuk ke peta', onTap: onSelesai),
        const SizedBox(height: Jarak.md),
        Text(
          'Mau progresmu aman kalau ganti HP? Bikin akun kapan aja '
          'lewat tab Aku — nggak wajib.',
          textAlign: TextAlign.center,
          style: RukunText.footnote.copyWith(color: context.teksTersier),
        ),
        const SizedBox(height: Jarak.lg),
      ],
    );
  }
}
