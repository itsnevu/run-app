import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Notifikasi harian Rukun.
///
/// **Aturan yang mengikat seluruh berkas ini** (DESIGN.md §8):
///
/// - **Maksimal satu per hari.** Bukan batas teknis — batas etis. Aplikasi
///   kebugaran yang mengirim lebih dari itu sedang mengejar metriknya
///   sendiri, bukan kebiasaan penggunanya.
/// - **Selalu tentang kesempatan, tidak pernah tentang kegagalan.**
///   "Kelurahan sebelah lagi naik, jalan sore yuk?" — bukan "Kamu belum
///   jalan 3 hari!". Rasa bersalah menaikkan angka minggu ini dan
///   menghilangkan pengguna bulan depan.
/// - **Tanpa angka performa.** Tidak ada pace, tidak ada jarak, tidak ada
///   perbandingan dengan orang lain.
abstract interface class LayananNotifikasi {
  Future<bool> mintaIzin();

  /// Menjadwalkan pengingat harian pada [jam]:[menit] waktu setempat.
  Future<void> jadwalkanHarian({
    required int jam,
    required int menit,
    required String judul,
    required String isi,
  });

  Future<void> batalkanSemua();
}

class NotifikasiPerangkat implements LayananNotifikasi {
  NotifikasiPerangkat(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _siap = false;

  /// Satu id tetap: menjadwalkan ulang selalu menimpa, tidak pernah
  /// menumpuk. Ini yang menjamin "maksimal satu per hari" secara teknis.
  static const _idHarian = 1;

  static const _saluran = AndroidNotificationDetails(
    'rukun_harian',
    'Pengingat harian',
    channelDescription: 'Satu pengingat lembut per hari.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  Future<void> _siapkan() async {
    if (_siap) return;
    tzdata.initializeTimeZones();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        iOS: DarwinInitializationSettings(
          // Izin diminta terpisah lewat mintaIzin(), supaya permintaannya
          // muncul saat pengguna paham konteksnya — bukan saat aplikasi
          // pertama dibuka.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _siap = true;
  }

  @override
  Future<bool> mintaIzin() async {
    await _siapkan();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  @override
  Future<void> jadwalkanHarian({
    required int jam,
    required int menit,
    required String judul,
    required String isi,
  }) async {
    await _siapkan();
    await _plugin.zonedSchedule(
      id: _idHarian,
      title: judul,
      body: isi,
      scheduledDate: _berikutnya(jam, menit),
      notificationDetails: const NotificationDetails(
        android: _saluran,
        iOS: DarwinNotificationDetails(),
      ),
      // inexact: pengingat lembut tidak layak membangunkan perangkat dari
      // mode hemat daya. Meleset beberapa menit sama sekali tidak masalah.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Kemunculan berikutnya dari jam tersebut.
  static tz.TZDateTime _berikutnya(int jam, int menit) {
    final sekarang = tz.TZDateTime.now(tz.local);
    var target = tz.TZDateTime(
        tz.local, sekarang.year, sekarang.month, sekarang.day, jam, menit);
    if (!target.isAfter(sekarang)) {
      target = target.add(const Duration(days: 1));
    }
    return target;
  }

  @override
  Future<void> batalkanSemua() async {
    await _siapkan();
    await _plugin.cancelAll();
  }
}

/// Menyusun kalimat pengingat.
///
/// Dipisah dari pengiriman supaya bisa diuji — nada bicara adalah bagian
/// produk yang paling mudah melenceng, dan paling mahal kalau melenceng.
abstract final class PesanHarian {
  /// Menyusun pengingat dari keadaan hari ini.
  ///
  /// [petakHangus] jumlah petak pengguna yang akan kedaluwarsa hari ini.
  /// [selisihTetangga] selisih persentase kelurahan tetangga yang sedang naik.
  static ({String judul, String isi}) susun({
    required int petakHangus,
    required String namaKelurahan,
    String? kelurahanNaik,
    double selisihNaik = 0,
  }) {
    if (petakHangus > 0) {
      return (
        judul: 'Ada $petakHangus petak nunggu kamu',
        isi: 'Belum ada yang lewat sini minggu ini. '
            'Jalan sebentar sore ini?',
      );
    }

    if (kelurahanNaik != null && selisihNaik > 0) {
      return (
        judul: '$kelurahanNaik lagi naik',
        isi: 'Warga $namaKelurahan lagi santai. Jalan sore, yuk?',
      );
    }

    return (
      judul: 'Kotamu masih banyak yang berkabut',
      isi: 'Jalan 5 menit aja udah buka petak baru.',
    );
  }
}
