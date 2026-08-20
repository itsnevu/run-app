import 'dart:math' as math;

/// Titik geografis.
class Koordinat {
  const Koordinat(this.lat, this.lng);

  final double lat;
  final double lng;

  /// Jari-jari bumi (WGS84 semi-major axis), meter.
  static const jariBumiMeter = 6378137.0;

  /// Jarak permukaan bumi ke [lain] dalam meter (haversine).
  ///
  /// Sengaja memakai haversine, bukan jarak pada proyeksi Mercator —
  /// Mercator meregang seiring lintang dan akan melebih-lebihkan jarak.
  double jarakKe(Koordinat lain) {
    const rad = math.pi / 180;
    final dLat = (lain.lat - lat) * rad;
    final dLng = (lain.lng - lng) * rad;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat * rad) *
            math.cos(lain.lat * rad) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * jariBumiMeter * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  @override
  bool operator ==(Object other) =>
      other is Koordinat && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() =>
      'Koordinat(${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)})';
}
