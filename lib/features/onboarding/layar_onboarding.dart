import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/rukun_motion.dart';
import '../../core/theme/rukun_spacing.dart';
import '../../core/theme/rukun_theme.dart';
import '../../core/theme/rukun_typography.dart';
import '../../data/repo/repo_lokal.dart';
import '../../domain/model/kelurahan.dart';
import '../../domain/model/koordinat.dart';
import '../../shared/widgets/frosted_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../state/kendali_sesi.dart';
import '../../state/penyedia.dart';
import '../peta/peta_rukun.dart';

/// Tahapan onboarding.
enum _Tahap { sambutan, izin, tim, ajakan, merekam, berhasil }

/// **Onboarding 6 menit.** DESIGN.md §7.1
///
/// Layar paling penting di aplikasi. Data industri: 70–80% pengguna tidak
/// pernah kembali setelah sesi pertama, dan meraih satu pencapaian di hari
/// pertama menaikkan retensi 64%.
///
/// Aturan mutlak yang ditegakkan di sini:
/// - ❌ Tanpa tinggi/berat badan. Selamanya.
/// - ❌ Tanpa "pilih level kebugaran" — itu yang membuat pemula merasa
///      tersisih di detik pertama.
/// - ❌ Tanpa pendaftaran akun sebelum petak pertama. Nilai dulu, gesekan
///      belakangan.
/// - ✅ Kata "lari" tidak muncul sampai setelah petak pertama terbuka.
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
  bool _izinDitolak = false;
  final _namaKendali = TextEditingController();

  /// Titik acuan sebelum izin diberikan — peta tetap tampil (berkabut penuh)
  /// supaya layar pertama tidak kosong.
  static const _acuan = Koordinat(-6.2264, 106.8556);

  @override
  void dispose() {
    _namaKendali.dispose();
    super.dispose();
  }

  void _ke(_Tahap t) => setState(() => _tahap = t);

  Future<void> _mintaIzin() async {
    final lokasi = ref.read(lokasiProvider);
    final boleh = await lokasi.mintaIzin();
    if (!mounted) return;

    if (!boleh) {
      setState(() => _izinDitolak = true);
      return;
    }

    final posisi = await lokasi.posisiSekarang();
    if (!mounted) return;

    setState(() {
      _posisi = posisi ?? _acuan;
      _kelurahan = RepoLokal.kelurahanDari(_posisi!);
      _izinDitolak = false;
    });
    _ke(_Tahap.tim);
  }

  Future<void> _mulaiJalan() async {
    // Profil dibuat sekarang supaya lintasan bisa dicatat — tapi tanpa satu
    // pun formulir. Nama ditanyakan nanti, setelah petak pertama terbuka.
    final repo = ref.read(repoProvider);
    await repo.simpanProfil(Profil(
      id: 'saya',
      nama: 'Kamu',
      kelurahanId: _kelurahan!.id,
    ));

    final berhasil = await ref.read(kendaliSesiProvider.notifier).mulai();
    if (!mounted) return;
    if (berhasil) _ke(_Tahap.merekam);
  }

  Future<void> _selesaikanJalan() async {
    await ref.read(kendaliSesiProvider.notifier).selesai();
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    _ke(_Tahap.berhasil);
  }

  Future<void> _simpanNama() async {
    final nama = _namaKendali.text.trim();
    final repo = ref.read(repoProvider);
    await repo.simpanProfil(Profil(
      id: 'saya',
      nama: nama.isEmpty ? 'Kamu' : nama,
      kelurahanId: _kelurahan!.id,
    ));
    ref.invalidate(profilProvider);
    if (!mounted) return;
    widget.onSelesai?.call();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(kendaliSesiProvider);
    final pusat = _posisi ?? _acuan;

    return Scaffold(
      body: Stack(
        children: [
          // Peta selalu ada di belakang — kota kamu, tertutup kabut.
          Positioned.fill(
            child: PetaRukun(
              pusat: pusat,
              zoom: 16,
              kabutPenuh: _tahap == _Tahap.sambutan || _tahap == _Tahap.izin,
              jejak: status.petakSesi,
              tampilkanTitikPengguna: _tahap != _Tahap.sambutan,
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Jarak.tepiLayar),
                child: AnimatedSwitcher(
                  duration: Gerak.halus,
                  switchInCurve: Gerak.halusKurva,
                  child: _isi(status),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _isi(StatusSesi status) => switch (_tahap) {
        _Tahap.sambutan => _Sambutan(
            key: const ValueKey('sambutan'),
            onLanjut: () => _ke(_Tahap.izin),
          ),
        _Tahap.izin => _Izin(
            key: const ValueKey('izin'),
            ditolak: _izinDitolak,
            onIzinkan: _mintaIzin,
          ),
        _Tahap.tim => _Tim(
            key: const ValueKey('tim'),
            kelurahan: _kelurahan!,
            onLanjut: () => _ke(_Tahap.ajakan),
          ),
        _Tahap.ajakan => _Ajakan(
            key: const ValueKey('ajakan'),
            onMulai: _mulaiJalan,
          ),
        _Tahap.merekam => _Merekam(
            key: const ValueKey('merekam'),
            status: status,
            kelurahan: _kelurahan!,
            onSelesai: _selesaikanJalan,
          ),
        _Tahap.berhasil => _Berhasil(
            key: const ValueKey('berhasil'),
            jumlahPetak: status.petakSesi.length,
            kelurahan: _kelurahan!,
            kendali: _namaKendali,
            onSelesai: _simpanNama,
          ),
      };
}

// ── 0:00 Sambutan ─────────────────────────────────────────────────
class _Sambutan extends StatelessWidget {
  const _Sambutan({super.key, required this.onLanjut});

  final VoidCallback onLanjut;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
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
        const SizedBox(height: Jarak.lg),
      ],
    );
  }
}

// ── 0:15 Izin lokasi ──────────────────────────────────────────────
class _Izin extends StatelessWidget {
  const _Izin({super.key, required this.ditolak, required this.onIzinkan});

  final bool ditolak;
  final VoidCallback onIzinkan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
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
              if (ditolak) ...[
                const SizedBox(height: Jarak.lg),
                Text(
                  'Tanpa izin lokasi, Rukun nggak bisa jalan. '
                  'Kamu bisa mengaktifkannya di Pengaturan.',
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
          label: ditolak ? 'Coba lagi' : 'Izinkan lokasi',
          onTap: onIzinkan,
        ),
        const SizedBox(height: Jarak.lg),
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
      children: [
        const Spacer(),
        KartuBuram(
          buram: Buram.tebal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Jarak.lg, vertical: Jarak.sm),
                decoration: ShapeDecoration(
                  gradient: kelurahan.warna.gradient,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Kelurahan ${kelurahan.nama}',
                  style: RukunText.caption.copyWith(color: Colors.white),
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
  const _Ajakan({super.key, required this.onMulai});

  final VoidCallback onMulai;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
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
        const SizedBox(height: Jarak.lg),
      ],
    );
  }
}

// ── Merekam ───────────────────────────────────────────────────────
class _Merekam extends StatelessWidget {
  const _Merekam({
    super.key,
    required this.status,
    required this.kelurahan,
    required this.onSelesai,
  });

  final StatusSesi status;
  final Kelurahan kelurahan;
  final VoidCallback onSelesai;

  @override
  Widget build(BuildContext context) {
    final jumlah = status.petakSesi.length;
    final menit = status.durasi.inMinutes;
    final detik = status.durasi.inSeconds % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                      style: RukunText.angkaSedang
                          .copyWith(color: context.warna.onSurface),
                    ),
                    Text(
                      'waktu jalan',
                      style: RukunText.caption
                          .copyWith(color: context.teksSekunder),
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
                    jumlah == 1 ? 'petak terbuka' : 'petak terbuka',
                    style:
                        RukunText.caption.copyWith(color: context.teksSekunder),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        if (jumlah > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: Jarak.lg),
            child: KartuBuram(
              buram: Buram.tipis,
              padding: const EdgeInsets.symmetric(
                  horizontal: Jarak.xl, vertical: Jarak.lg),
              child: Text(
                'Kabut kebuka. Petak ini punya kamu selamanya.',
                style:
                    RukunText.subhead.copyWith(color: context.warna.onSurface),
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
    required this.kelurahan,
    required this.kendali,
    required this.onSelesai,
  });

  final int jumlahPetak;
  final Kelurahan kelurahan;
  final TextEditingController kendali;
  final VoidCallback onSelesai;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
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
                'Petak ini milik kamu selamanya — nggak bisa direbut siapa pun.',
                style: RukunText.subhead.copyWith(color: context.teksSekunder),
              ),
              const SizedBox(height: Jarak.xl),
              const Divider(),
              const SizedBox(height: Jarak.xl),
              // Nama diminta SETELAH nilai diberikan, bukan sebelumnya.
              Text('Tetanggamu bakal lihat kamu sebagai siapa?',
                  style: RukunText.headline),
              const SizedBox(height: Jarak.md),
              TextField(
                controller: kendali,
                textCapitalization: TextCapitalization.words,
                style: RukunText.body,
                decoration: InputDecoration(
                  hintText: 'Nama panggilan',
                  hintStyle:
                      RukunText.body.copyWith(color: context.teksTersier),
                  filled: true,
                  fillColor: context.modeGelap
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Sudut.sm),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: Jarak.lg, vertical: Jarak.md),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Jarak.xl),
        TombolRukun(label: 'Masuk ke peta', onTap: onSelesai),
        const SizedBox(height: Jarak.lg),
      ],
    );
  }
}
