import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/rukun_colors.dart';
import '../../core/theme/rukun_motion.dart';
import '../../core/theme/rukun_theme.dart';
import '../../domain/grid/grid_heks.dart';
import '../../domain/grid/grid_petak.dart';
import '../../domain/model/koordinat.dart';

extension _KeLatLng on Koordinat {
  LatLng get latLng => LatLng(lat, lng);
}

/// Peta Rukun — fondasi seluruh aplikasi. DESIGN.md §6.5
///
/// Tiga lapis di atas satu peta:
/// 1. **Jejak** (pribadi, permanen) — kabut terbuka, tidak pernah bisa direbut
/// 2. **Wilayah** (tim, dinamis) — warna kelurahan, bisa berpindah
/// 3. **Misi** — pin tujuan harian
///
/// Peta adalah kanvas, bukan bintang: ubin didesaturasi supaya lapisan
/// permainan yang menonjol.
class PetaRukun extends StatefulWidget {
  const PetaRukun({
    super.key,
    required this.pusat,
    this.zoom = 16,
    this.jejak = const {},
    this.wilayah = const {},
    this.grid = const GridHeks(),
    this.radiusPetak = 10,
    this.tampilkanUbin = true,
    this.penyediaUbin,
    this.kabutPenuh = false,
    this.kendali,
    this.tampilkanTitikPengguna = true,
    this.petakHangus = const {},
    this.ikuti = true,
  });

  /// Titik tengah peta — biasanya posisi pengguna.
  final Koordinat pusat;
  final double zoom;

  /// Petak yang sudah terbuka milik pengguna. Permanen.
  final Set<IdPetak> jejak;

  /// Petak yang dimiliki tim, beserta warnanya.
  final Map<IdPetak, TimWarna> wilayah;

  final GridPetak grid;

  /// Radius petak berkabut yang digambar di sekitar pusat.
  ///
  /// Radius 10 menghasilkan ~331 poligon — di bawah anggaran 500 poligon
  /// pada 60fps yang ditetapkan DESIGN.md §10.4.
  final int radiusPetak;

  final bool tampilkanUbin;
  final TileProvider? penyediaUbin;

  /// Menutup seluruh peta dengan kabut — dipakai saat onboarding.
  final bool kabutPenuh;

  final MapController? kendali;
  final bool tampilkanTitikPengguna;

  /// Petak yang akan kedaluwarsa dalam 24 jam. Tepinya berdenyut.
  ///
  /// Denyut sengaja dibatasi ke lapisan ini saja dan hanya
  /// [maksHangusBerdenyut] petak: menganimasikan poligon berarti membangun
  /// ulang lapisannya tiap frame, dan anggaran 60fps di Android kelas
  /// menengah tidak menyisakan banyak ruang. Sisanya tetap ditandai,
  /// hanya tidak berdenyut.
  final Set<IdPetak> petakHangus;

  /// Peta bergeser mengikuti [pusat] selama pengguna belum menggeser sendiri.
  ///
  /// Tanpa ini `initialCenter` hanya berlaku sekali: selama sesi 45 menit peta
  /// terkunci di titik start, titik biru diam di tengah layar sementara dunia
  /// nyata bergerak, dan kabut tertinggal di belakang.
  final bool ikuti;

  static const maksHangusBerdenyut = 24;

  /// Batas cincin kabut saat peta diperkecil.
  ///
  /// 12 cincin = 469 poligon, masih di bawah anggaran 500 poligon pada 60fps
  /// (DESIGN.md §10.4).
  static const maksRadiusPetak = 12;

  @override
  State<PetaRukun> createState() => _PetaRukunState();
}

class _PetaRukunState extends State<PetaRukun> {
  MapController? _milikSendiri;
  MapController get _kendali =>
      widget.kendali ?? (_milikSendiri ??= MapController());

  /// Petak tempat kamera berada. Kabut dihitung dari sini, bukan dari posisi
  /// pengguna — kalau tidak, menggeser peta sedikit saja memperlihatkan peta
  /// telanjang tanpa kabut di luar cincin.
  IdPetak? _petakKamera;
  double? _zoomKamera;

  /// Mati begitu pengguna menggeser peta sendiri. Merebut kembali kendali
  /// kamera dari tangan pengguna adalah cara tercepat membuat peta terasa
  /// melawan.
  bool _ikuti = true;

  @override
  void didUpdateWidget(PetaRukun lama) {
    super.didUpdateWidget(lama);
    if (!widget.ikuti) return;
    if (!_ikuti) return;
    if (widget.pusat == lama.pusat) return;

    // Pindah kamera setelah frame ini selesai — `move()` di tengah build
    // memicu rebuild bersarang.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _kendali.move(widget.pusat.latLng, _zoomKamera ?? widget.zoom);
    });
  }

  @override
  void dispose() {
    _milikSendiri?.dispose();
    super.dispose();
  }

  /// Radius cincin kabut, melebar saat peta diperkecil.
  int get _radiusEfektif {
    final zoom = _zoomKamera ?? widget.zoom;
    final selisih = (widget.zoom - zoom).round();
    if (selisih <= 0) return widget.radiusPetak;
    return (widget.radiusPetak + selisih * 3)
        .clamp(widget.radiusPetak, PetaRukun.maksRadiusPetak);
  }

  void _kameraBergerak(MapCamera kamera, bool adaGerakan) {
    if (adaGerakan && _ikuti) _ikuti = false;

    final petak = widget.grid.petakDi(
      Koordinat(kamera.center.latitude, kamera.center.longitude),
    );
    final zoomBerubah = (_zoomKamera ?? widget.zoom) - kamera.zoom;

    // Hanya hitung ulang saat kamera melewati batas petak (~132 m) atau zoom
    // berubah berarti. Tanpa ambang ini, kabut dibangun ulang tiap frame
    // sepanjang gerakan jari.
    if (petak == _petakKamera && zoomBerubah.abs() < 0.5) return;

    setState(() {
      _petakKamera = petak;
      _zoomKamera = kamera.zoom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gelap = context.modeGelap;
    final grid = widget.grid;
    final pusat = widget.pusat;
    final petakHangus = widget.petakHangus;
    final zoom = widget.zoom;
    final kabutPenuh = widget.kabutPenuh;
    final tampilkanUbin = widget.tampilkanUbin;
    final tampilkanTitikPengguna = widget.tampilkanTitikPengguna;

    // Kabut mengikuti kamera; titik pengguna tetap di posisi sebenarnya.
    final petakTengah = _petakKamera ?? grid.petakDi(pusat);
    final terlihat = grid.cincin(petakTengah, _radiusEfektif);

    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _kendali,
            options: MapOptions(
              initialCenter: pusat.latLng,
              initialZoom: zoom,
              onPositionChanged: _kameraBergerak,
              backgroundColor:
                  gelap ? RukunColors.latarGelapA : RukunColors.jalanTerang,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              if (tampilkanUbin) _lapisanUbin(gelap),
              _lapisanWilayah(),
              if (!kabutPenuh) _lapisanKabut(terlihat),
              if (petakHangus.isNotEmpty)
                _LapisanHangus(petak: petakHangus, grid: grid),
              if (tampilkanTitikPengguna) _lapisanPengguna(context),
            ],
          ),
        ),
        // Kabut menyeluruh untuk onboarding: kota belum terjamah sama sekali.
        if (kabutPenuh)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gelap
                        ? [
                            const Color(0xFF11141A).withValues(alpha: 0.94),
                            const Color(0xFF171B23).withValues(alpha: 0.94),
                          ]
                        : [
                            RukunColors.kabutA.withValues(alpha: 0.92),
                            RukunColors.kabutB.withValues(alpha: 0.92),
                          ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Ubin peta, didesaturasi. Peta adalah kanvas, bukan bintang.
  ///
  /// ⚠️ **Belum siap produksi.** Server ubin publik OpenStreetMap dijalankan
  /// dengan donasi dan Kebijakan Penggunaan Ubin mereka melarang aplikasi
  /// dengan lalu lintas besar. Sebelum rilis, ganti ke penyedia berbayar
  /// (MapTiler, Stadia, Protomaps) atau host ubin sendiri.
  /// Lihat: https://operations.osmfoundation.org/policies/tiles
  Widget _lapisanUbin(bool gelap) {
    final penyediaUbin = widget.penyediaUbin;
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(_matriksDesaturasi(gelap ? 0.15 : 0.35)),
      child: TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'id.rukun.rukun',
        tileProvider: penyediaUbin,
        maxNativeZoom: 19,
      ),
    );
  }

  /// Wilayah tim — isian 28%, tepi 90% tebal 2. DESIGN.md §2.5
  Widget _lapisanWilayah() {
    final grid = widget.grid;
    final wilayah = widget.wilayah;
    return PolygonLayer(
      polygons: [
        for (final entri in wilayah.entries)
          Polygon(
            points: [
              for (final k in grid.batas(entri.key)) k.latLng,
            ],
            color: entri.value.isianPeta,
            borderColor: entri.value.tepiPeta,
            borderStrokeWidth: 2,
          ),
      ],
    );
  }

  /// Petak yang belum terbuka. Isian kabut 55%.
  Widget _lapisanKabut(List<IdPetak> terlihat) {
    final grid = widget.grid;
    final jejak = widget.jejak;
    final wilayah = widget.wilayah;
    final petakHangus = widget.petakHangus;
    final berkabut = terlihat
        .where((p) =>
            !jejak.contains(p) &&
            !wilayah.containsKey(p) &&
            !petakHangus.contains(p))
        .toList();

    return PolygonLayer(
      polygons: [
        for (final p in berkabut)
          Polygon(
            points: [
              for (final k in grid.batas(p)) k.latLng,
            ],
            color: RukunColors.kabutA.withValues(alpha: 0.55),
            borderColor: RukunColors.kabutB.withValues(alpha: 0.30),
            borderStrokeWidth: 0.5,
          ),
      ],
    );
  }

  /// Titik pengguna — lingkaran gradient dengan tepi putih dan bayangan.
  Widget _lapisanPengguna(BuildContext context) {
    return MarkerLayer(
      markers: [
        Marker(
          point: widget.pusat.latLng,
          width: 28,
          height: 28,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: context.gradients.terang,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }

  static List<double> _matriksDesaturasi(double s) {
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final n = 1 - s;
    return [
      lr * n + s, lg * n, lb * n, 0, 0,
      lr * n, lg * n + s, lb * n, 0, 0,
      lr * n, lg * n, lb * n + s, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }
}


/// Tepi berdenyut untuk petak yang akan hangus. DESIGN.md §6.5
///
/// Ini mekanisme urgensi Rukun — dan sengaja tidak kompetitif: yang mendesak
/// adalah waktunya, bukan orang lain yang mengejar.
class _LapisanHangus extends StatefulWidget {
  const _LapisanHangus({required this.petak, required this.grid});

  final Set<IdPetak> petak;
  final GridPetak grid;

  @override
  State<_LapisanHangus> createState() => _LapisanHangusState();
}

class _LapisanHangusState extends State<_LapisanHangus>
    with SingleTickerProviderStateMixin {
  late final AnimationController _denyut = AnimationController(
    vsync: this,
    duration: Gerak.denyutHangus,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // reduceMotion: tanda tetap ada, denyutnya yang hilang.
    if (Gerak.kurangiGerak(context)) {
      _denyut.stop();
      _denyut.value = 0.5;
    } else if (!_denyut.isAnimating) {
      _denyut.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _denyut.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tampil = widget.petak.take(PetaRukun.maksHangusBerdenyut).toList();

    return AnimatedBuilder(
      animation: _denyut,
      builder: (context, _) {
        final t = _denyut.value;
        return PolygonLayer(
          polygons: [
            for (final p in tampil)
              Polygon(
                points: [
                  for (final k in widget.grid.batas(p)) k.latLng,
                ],
                color: RukunColors.hangusA.withValues(alpha: 0.10 + 0.10 * t),
                borderColor:
                    RukunColors.hangusA.withValues(alpha: 0.55 + 0.45 * t),
                borderStrokeWidth: 2 + t,
              ),
          ],
        );
      },
    );
  }
}
