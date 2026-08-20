import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../domain/model/koordinat.dart';

/// Hasil permintaan izin lokasi.
///
/// Sengaja bukan `bool`: tiga kegagalan di bawah butuh tiga jalan keluar yang
/// berbeda di UI. Menyatukannya jadi `false` membuat tombol Rekam diam saja —
/// pengguna menekan, tidak terjadi apa-apa, dan tidak ada yang menjelaskan.
enum StatusIzin {
  /// Boleh melacak selama aplikasi dipakai.
  saatDipakai,

  /// Boleh melacak juga saat aplikasi di latar belakang.
  selalu,

  /// Layanan lokasi perangkat mati — arahkan ke pengaturan sistem.
  layananMati,

  /// Ditolak kali ini. Boleh diminta lagi.
  ditolak,

  /// Ditolak permanen — `requestPermission()` tidak akan memunculkan dialog
  /// lagi. Satu-satunya jalan adalah pengaturan aplikasi.
  ditolakPermanen;

  bool get bolehMelacak => this == saatDipakai || this == selalu;
}

/// Satu sampel GPS beserta metadata kualitasnya.
///
/// [Koordinat] saja tidak cukup: tanpa akurasi, sampel 60 m di lorong gedung
/// diperlakukan sama dengan sampel 4 m dan menginterpolasi petak yang tidak
/// pernah diinjak. Tanpa [dipalsukan], aplikasi Fake GPS membuka wilayah dari
/// atas sofa. Tanpa [waktu] dari perangkat, batch update yang datang sekaligus
/// terbaca sebagai kecepatan tak hingga lalu dibuang sebagai "kendaraan".
class SampelLokasi {
  const SampelLokasi({
    required this.koordinat,
    required this.waktu,
    this.akurasiMeter,
    this.kecepatanMeterPerDetik,
    this.dipalsukan = false,
  });

  final Koordinat koordinat;

  /// Waktu *fix*, bukan waktu terima.
  final DateTime waktu;

  /// Radius ketidakpastian horizontal. Null bila tidak diketahui.
  final double? akurasiMeter;

  /// Kecepatan dari Doppler — jauh lebih akurat daripada Δjarak/Δwaktu.
  final double? kecepatanMeterPerDetik;

  /// Perangkat melaporkan lokasi ini berasal dari mock provider.
  final bool dipalsukan;

  /// Ambang akurasi yang masih boleh dipakai membuka petak.
  ///
  /// Petak selebar ~132 m; sampel dengan ketidakpastian di atas 30 m sudah
  /// cukup untuk menunjuk petak tetangga yang salah.
  static const akurasiMaksimumMeter = 30.0;

  bool get layakPakai =>
      !dipalsukan &&
      (akurasiMeter == null || akurasiMeter! <= akurasiMaksimumMeter);
}

/// Akses lokasi perangkat.
///
/// Diabstraksi supaya seluruh alur bisa diuji dan disimulasikan tanpa GPS
/// asli — pengujian sesi tidak boleh bergantung pada perangkat keras.
abstract interface class LayananLokasi {
  /// Meminta izin lokasi.
  Future<StatusIzin> mintaIzin();

  Future<Koordinat?> posisiSekarang();

  /// Aliran posisi selama sesi berjalan.
  Stream<SampelLokasi> aliranPosisi();

  /// Membuka pengaturan aplikasi (untuk izin yang ditolak permanen).
  Future<void> bukaPengaturanAplikasi();

  /// Membuka pengaturan lokasi perangkat.
  Future<void> bukaPengaturanLokasi();
}

class LokasiPerangkat implements LayananLokasi {
  const LokasiPerangkat();

  @override
  Future<StatusIzin> mintaIzin() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return StatusIzin.layananMati;
    }

    var izin = await Geolocator.checkPermission();
    if (izin == LocationPermission.denied) {
      izin = await Geolocator.requestPermission();
    }

    return switch (izin) {
      LocationPermission.always => StatusIzin.selalu,
      LocationPermission.whileInUse => StatusIzin.saatDipakai,
      LocationPermission.deniedForever => StatusIzin.ditolakPermanen,
      _ => StatusIzin.ditolak,
    };
  }

  @override
  Future<void> bukaPengaturanAplikasi() => Geolocator.openAppSettings();

  @override
  Future<void> bukaPengaturanLokasi() => Geolocator.openLocationSettings();

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

  /// Pengaturan per-platform.
  ///
  /// `LocationSettings` polos **tidak cukup**: ia hanya menyerialkan accuracy
  /// dan distanceFilter, sehingga di iOS `allowsBackgroundLocationUpdates`
  /// tetap NO dan CLLocationManager berhenti begitu aplikasi di-suspend —
  /// walaupun Info.plist sudah mendeklarasikan UIBackgroundModes. Di Android,
  /// tanpa `foregroundNotificationConfig` plugin tidak menyalakan foreground
  /// service, jadi Doze men-throttle pembaruan begitu layar mati.
  ///
  /// Artinya: dengan pengaturan polos, sesi 45 menit dengan HP di saku
  /// menghasilkan nyaris nol petak. Ini bukan optimasi — ini syarat berfungsi.
  static LocationSettings _pengaturan() {
    // Sampel tiap 8 m — cukup rapat untuk petak 132 m.
    //
    // Catatan baterai: `distanceFilter` **tidak** menghemat radio; ia hanya
    // menyaring pengiriman ke Dart. Yang benar-benar menekan konsumsi adalah
    // `intervalDuration` di Android dan `activityType: fitness` di iOS —
    // keduanya di bawah ini (DESIGN.md §10.4: <4%/jam).
    const jarakSampel = 8;

    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: jarakSampel,
        intervalDuration: const Duration(seconds: 4),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Rukun sedang merekam',
          notificationText: 'Petak terbuka sambil kamu jalan.',
          notificationIcon:
              AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }

    if (Platform.isIOS || Platform.isMacOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: jarakSampel,
        activityType: ActivityType.fitness,
        // iOS suka menjeda pembaruan saat mengira pengguna berhenti bergerak.
        // Untuk permainan wilayah, jeda itu berarti petak yang hilang.
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: jarakSampel,
    );
  }

  @override
  Stream<SampelLokasi> aliranPosisi() =>
      Geolocator.getPositionStream(locationSettings: _pengaturan())
          .map(_dariPosisi);

  static SampelLokasi _dariPosisi(Position p) => SampelLokasi(
        koordinat: Koordinat(p.latitude, p.longitude),
        // Waktu fix, bukan `DateTime.now()`. FusedLocationProvider mem-batch
        // pembaruan saat aplikasi di latar; memakai waktu terima membuat
        // seluruh batch tiba dengan Δt ≈ 0 → kecepatan tak hingga → segmen
        // dibuang sebagai kendaraan. Jalan yang nyata terhapus diam-diam.
        waktu: p.timestamp,
        akurasiMeter: p.accuracy,
        kecepatanMeterPerDetik: p.speed,
        dipalsukan: p.isMocked,
      );
}

/// Lokasi tersimulasi — untuk pengujian dan pengembangan tanpa GPS.
class LokasiPalsu implements LayananLokasi {
  LokasiPalsu({
    this.awal = const Koordinat(-6.2264, 106.8556), // Tebet
    this.kecepatanMeterPerDetik = 1.4, // jalan santai
    this.jedaSampel = const Duration(seconds: 1),
    this.izin = StatusIzin.selalu,
    this.langkahMeter,
    this.akurasiMeter = 8.0,
  });

  final Koordinat awal;
  final double kecepatanMeterPerDetik;
  final Duration jedaSampel;
  final StatusIzin izin;

  /// Jarak per sampel, meter.
  ///
  /// Biasanya diturunkan dari kecepatan × jeda. Pengujian bisa
  /// mengaturnya langsung untuk **memampatkan waktu**: melintasi 150 m
  /// radius privasi dengan kecepatan jalan asli butuh dua menit waktu
  /// nyata, terlalu lama untuk sebuah uji. Pasangkan dengan jam sintetis
  /// pada `KendaliSesi.mulai(jam: ...)` supaya kecepatan yang terhitung
  /// tetap masuk akal.
  final double? langkahMeter;

  final double akurasiMeter;

  Koordinat? _terakhir;

  @override
  Future<StatusIzin> mintaIzin() async => izin;

  @override
  Future<void> bukaPengaturanAplikasi() async {}

  @override
  Future<void> bukaPengaturanLokasi() async {}

  @override
  Future<Koordinat?> posisiSekarang() async => _terakhir ?? awal;

  @override
  Stream<SampelLokasi> aliranPosisi() async* {
    var posisi = _terakhir ?? awal;
    final meterPerDerajat = 111320 * math.cos(posisi.lat * math.pi / 180);
    final langkah = langkahMeter ??
        kecepatanMeterPerDetik * jedaSampel.inMilliseconds / 1000;

    while (true) {
      yield SampelLokasi(
        koordinat: posisi,
        waktu: DateTime.now(),
        akurasiMeter: akurasiMeter,
        kecepatanMeterPerDetik: kecepatanMeterPerDetik,
      );
      _terakhir = posisi;
      await Future<void>.delayed(jedaSampel);
      posisi = Koordinat(posisi.lat, posisi.lng + langkah / meterPerDerajat);
    }
  }
}
