import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../domain/model/koordinat.dart';

/// Akses lokasi perangkat.
///
/// Diabstraksi supaya seluruh alur bisa diuji dan disimulasikan tanpa GPS
/// asli — pengujian sesi tidak boleh bergantung pada perangkat keras.
abstract interface class LayananLokasi {
  /// Meminta izin. Mengembalikan false bila ditolak.
  Future<bool> mintaIzin();

  Future<Koordinat?> posisiSekarang();

  /// Aliran posisi selama sesi berjalan.
  Stream<Koordinat> aliranPosisi();
}

class LokasiPerangkat implements LayananLokasi {
  const LokasiPerangkat();

  @override
  Future<bool> mintaIzin() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var izin = await Geolocator.checkPermission();
    if (izin == LocationPermission.denied) {
      izin = await Geolocator.requestPermission();
    }
    return izin == LocationPermission.always ||
        izin == LocationPermission.whileInUse;
  }

  @override
  Future<Koordinat?> posisiSekarang() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return Koordinat(p.latitude, p.longitude);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<Koordinat> aliranPosisi() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          // Sampel tiap 10 m — cukup rapat untuk petak 132 m, cukup jarang
          // untuk menjaga anggaran baterai <4%/jam (DESIGN.md §10.4).
          distanceFilter: 10,
        ),
      ).map((p) => Koordinat(p.latitude, p.longitude));
}

/// Lokasi tersimulasi — untuk pengujian dan pengembangan tanpa GPS.
class LokasiPalsu implements LayananLokasi {
  LokasiPalsu({
    this.awal = const Koordinat(-6.2264, 106.8556), // Tebet
    this.kecepatanMeterPerDetik = 1.4, // jalan santai
    this.jedaSampel = const Duration(seconds: 1),
    this.izinDiberikan = true,
    this.langkahMeter,
  });

  final Koordinat awal;
  final double kecepatanMeterPerDetik;
  final Duration jedaSampel;
  final bool izinDiberikan;

  /// Jarak per sampel, meter.
  ///
  /// Biasanya diturunkan dari kecepatan × jeda. Pengujian bisa
  /// mengaturnya langsung untuk **memampatkan waktu**: melintasi 150 m
  /// radius privasi dengan kecepatan jalan asli butuh dua menit waktu
  /// nyata, terlalu lama untuk sebuah uji. Pasangkan dengan jam sintetis
  /// pada `KendaliSesi.mulai(jam: ...)` supaya kecepatan yang terhitung
  /// tetap masuk akal.
  final double? langkahMeter;

  Koordinat? _terakhir;

  @override
  Future<bool> mintaIzin() async => izinDiberikan;

  @override
  Future<Koordinat?> posisiSekarang() async => _terakhir ?? awal;

  @override
  Stream<Koordinat> aliranPosisi() async* {
    var posisi = _terakhir ?? awal;
    final meterPerDerajat = 111320 * math.cos(posisi.lat * math.pi / 180);
    final langkah = langkahMeter ??
        kecepatanMeterPerDetik * jedaSampel.inMilliseconds / 1000;

    while (true) {
      yield posisi;
      _terakhir = posisi;
      await Future<void>.delayed(jedaSampel);
      posisi = Koordinat(posisi.lat, posisi.lng + langkah / meterPerDerajat);
    }
  }
}
