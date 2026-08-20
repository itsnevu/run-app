import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/rukun_colors.dart';
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
class PetaRukun extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final gelap = context.modeGelap;
    final petakTengah = grid.petakDi(pusat);
    final terlihat = grid.cincin(petakTengah, radiusPetak);

    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: kendali,
            options: MapOptions(
              initialCenter: pusat.latLng,
              initialZoom: zoom,
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
  Widget _lapisanUbin(bool gelap) {
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
    return PolygonLayer(
      polygons: [
        for (final entri in wilayah.entries)
          Polygon(
            points: [
              for (final k in grid.batas(entri.key)) k.latLng,
            ],
            color: entri.value.a.withValues(alpha: 0.28),
            borderColor: entri.value.tepiPeta,
            borderStrokeWidth: 2,
          ),
      ],
    );
  }

  /// Petak yang belum terbuka. Isian kabut 55%.
  Widget _lapisanKabut(List<IdPetak> terlihat) {
    final berkabut = terlihat
        .where((p) => !jejak.contains(p) && !wilayah.containsKey(p))
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
          point: pusat.latLng,
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
