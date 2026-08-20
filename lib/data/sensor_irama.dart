import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import '../domain/aturan/irama_langkah.dart';

/// Membaca akselerometer dan menyimpulkan apakah pengguna sedang melangkah.
///
/// Dipakai untuk memisahkan bersepeda dari lari — GPS saja tidak bisa,
/// karena rentang kecepatannya bertumpuk.
abstract interface class SensorIrama {
  /// Mulai membaca.
  Future<void> mulai();

  /// Berhenti dan lepaskan sumber daya.
  Future<void> berhenti();

  /// Apakah pola langkah kaki terdeteksi dalam jendela terakhir.
  ///
  /// Null bila sensor tidak tersedia atau datanya belum cukup — pemanggil
  /// harus memperlakukan itu sebagai "tidak tahu", bukan "tidak melangkah".
  bool? get adaLangkah;

  /// Irama terakhir dalam langkah per menit, atau null bila belum diketahui.
  double? get langkahPerMenit;
}

class SensorIramaPerangkat implements SensorIrama {
  SensorIramaPerangkat({this.jendela = const Duration(seconds: 6)});

  /// Panjang jendela yang dianalisis. Cukup panjang untuk memuat beberapa
  /// langkah, cukup pendek untuk bereaksi saat pengguna berganti moda.
  final Duration jendela;

  final _sampel = <SampelGerak>[];
  StreamSubscription<AccelerometerEvent>? _langganan;
  bool _tersedia = false;

  @override
  Future<void> mulai() async {
    if (_langganan != null) return;
    _sampel.clear();

    try {
      _langganan = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 20), // 50 Hz
      ).listen(
        (e) {
          _tersedia = true;
          _sampel.add(SampelGerak(e.x, e.y, e.z, DateTime.now()));
          _pangkas();
        },
        onError: (_) => _tersedia = false,
        cancelOnError: false,
      );
    } catch (_) {
      // Perangkat tanpa akselerometer — biarkan adaLangkah tetap null.
      _tersedia = false;
    }
  }

  void _pangkas() {
    final batas = DateTime.now().subtract(jendela);
    _sampel.removeWhere((s) => s.waktu.isBefore(batas));
  }

  @override
  Future<void> berhenti() async {
    await _langganan?.cancel();
    _langganan = null;
    _sampel.clear();
  }

  @override
  bool? get adaLangkah {
    if (!_tersedia || _sampel.length < 50) return null;
    return IramaLangkah.adaLangkah(List.unmodifiable(_sampel));
  }

  @override
  double? get langkahPerMenit {
    if (!_tersedia || _sampel.length < 50) return null;
    return IramaLangkah.langkahPerMenit(List.unmodifiable(_sampel));
  }
}

/// Sensor tersimulasi untuk pengujian.
class SensorIramaPalsu implements SensorIrama {
  SensorIramaPalsu({this.melangkah, this.irama});

  bool? melangkah;
  double? irama;

  @override
  Future<void> mulai() async {}

  @override
  Future<void> berhenti() async {}

  @override
  bool? get adaLangkah => melangkah;

  @override
  double? get langkahPerMenit => irama;
}
