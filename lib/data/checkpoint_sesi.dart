import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/model/koordinat.dart';
import '../domain/model/sesi.dart';

/// Menyimpan sesi yang sedang berjalan ke perangkat.
///
/// Tanpa ini `Sesi.titik` hanya hidup di RAM, dan satu-satunya penulisan
/// terjadi saat sesi selesai. Artinya: Android membunuh proses di menit ke-40
/// karena tekanan memori, atau pengguna tidak sengaja menggeser aplikasi dari
/// daftar tugas — 45 menit berjalan kaki hilang tanpa jejak, dan yang hilang
/// bukan cuma angka, tapi petak yang sudah dibuka untuk kelurahannya.
///
/// Sengaja memakai [SharedPreferences] dan bukan basis data: sesi berjalan
/// adalah satu objek yang ditimpa berulang kali, bukan kumpulan baris yang
/// perlu dikueri. Begitu sesi selesai dan tersimpan, checkpoint-nya dibuang.
class CheckpointSesi {
  const CheckpointSesi(this._pref);

  final SharedPreferences _pref;

  static const _kunci = 'sesi_berjalan';

  Future<void> simpan(Sesi sesi) async {
    await _pref.setString(
      _kunci,
      jsonEncode({
        'id': sesi.id,
        'mulai': sesi.mulai.toIso8601String(),
        'titik': [
          for (final t in sesi.titik)
            {
              'lat': t.koordinat.lat,
              'lng': t.koordinat.lng,
              'w': t.waktu.toIso8601String(),
            },
        ],
      }),
    );
  }

  /// Sesi yang belum sempat diselesaikan, bila ada.
  Sesi? muat() {
    final mentah = _pref.getString(_kunci);
    if (mentah == null) return null;

    try {
      final j = jsonDecode(mentah) as Map<String, dynamic>;
      final titik = [
        for (final t in (j['titik'] as List<dynamic>))
          TitikJejak(
            Koordinat(
              ((t as Map<String, dynamic>)['lat'] as num).toDouble(),
              (t['lng'] as num).toDouble(),
            ),
            DateTime.parse(t['w'] as String),
          ),
      ];

      // Sesi tanpa titik tidak punya apa pun untuk dipulihkan.
      if (titik.isEmpty) return null;

      return Sesi(
        id: j['id'] as String,
        mulai: DateTime.parse(j['mulai'] as String),
        titik: titik,
      );
    } catch (_) {
      // Checkpoint rusak tidak boleh membuat aplikasi gagal start.
      return null;
    }
  }

  Future<void> hapus() => _pref.remove(_kunci);
}
