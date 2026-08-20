import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/konfigurasi.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/lokasi.dart';
import '../data/notifikasi.dart';
import '../data/sensor_irama.dart';
import '../data/repo/repo_lokal.dart';
import '../data/repo/repo_rukun.dart';
import '../data/repo/repo_supabase.dart';
import '../domain/aturan/aturan_klaim.dart';
import '../domain/aturan/zona_privat.dart';
import '../domain/grid/grid_heks.dart';
import '../domain/grid/grid_petak.dart';
import '../domain/model/kelurahan.dart';
import '../domain/model/koordinat.dart';
import '../domain/model/misi.dart';
import 'akun.dart';

/// Grid petak yang dipakai seluruh aplikasi.
final gridProvider = Provider<GridPetak>((_) => const GridHeks());

/// Diisi di `main()` setelah SharedPreferences siap.
final prefProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('prefProvider harus di-override di main()'),
);

/// Klien Supabase. Hanya di-override di `main()` bila kredensial tersedia.
final supabaseProvider = Provider<SupabaseClient?>((_) => null);

/// Memilih penyimpanan: server bila pengguna **sudah masuk**, kalau tidak
/// penyimpanan di perangkat.
///
/// Keduanya memenuhi kontrak [RepoRukun] yang sama, jadi seluruh lapisan
/// fitur tidak tahu — dan tidak perlu tahu — mana yang sedang dipakai.
///
/// Inilah yang membuat mode tamu bukan sekadar layar kosong: tanpa akun,
/// aplikasi berjalan penuh di atas [RepoLokal]. Petak tetap terbuka, Jejak
/// tetap tercatat, misi tetap jalan. Akun hanya memindahkan rumah datanya.
final repoProvider = Provider<RepoRukun>((ref) {
  final klien = ref.watch(supabaseProvider);
  final akun = ref.watch(akunProvider);
  final lokal = RepoLokal(ref.watch(prefProvider));

  if (Konfigurasi.pakaiSupabase && klien != null && akun.masuk) {
    // Zona privat tetap tinggal di perangkat, bahkan setelah masuk —
    // radius rumah tidak pernah punya alasan untuk sampai ke server.
    return RepoSupabase(klien, zonaLokal: lokal);
  }
  return lokal;
});

/// Apakah pengguna sudah pernah melewati pembuka.
///
/// Disimpan terpisah dari profil supaya pembuka tidak pernah muncul dua kali
/// — termasuk saat pengguna masuk ke akun baru yang profil servernya masih
/// kosong. Pembuka adalah perkenalan, bukan formulir pendaftaran.
class PembukaSelesai extends Notifier<bool> {
  static const _kunci = 'pembuka_selesai';

  @override
  bool build() {
    final pref = ref.watch(prefProvider);
    // Pengguna dari versi sebelum penanda ini ada sudah punya profil
    // tersimpan. Mereka tidak boleh disuruh mengulang pembuka.
    return pref.getBool(_kunci) ?? (pref.getString('profil') != null);
  }

  Future<void> tandai() async {
    await ref.read(prefProvider).setBool(_kunci, true);
    state = true;
  }
}

final pembukaSelesaiProvider =
    NotifierProvider<PembukaSelesai, bool>(PembukaSelesai.new);

final lokasiProvider = Provider<LayananLokasi>((_) => const LokasiPerangkat());

/// Notifikasi harian.
final notifikasiProvider = Provider<LayananNotifikasi>(
  (_) => NotifikasiPerangkat(FlutterLocalNotificationsPlugin()),
);

/// Sensor irama langkah — memisahkan bersepeda dari lari.
final sensorIramaProvider =
    Provider<SensorIrama>((_) => SensorIramaPerangkat());

/// Profil pengguna. Null berarti belum ada sama sekali.
final profilProvider = FutureProvider<Profil?>(
  (ref) => ref.watch(repoProvider).muatProfil(),
);

/// Kelurahan pengguna, atau null bila belum ditentukan.
///
/// Null adalah keadaan yang sah, bukan kesalahan: pengguna yang menunda izin
/// lokasi tetap boleh masuk dan melihat-lihat. Setiap layar yang memakainya
/// wajib punya tampilan kosong yang ramah, bukan layar putih.
final kelurahanSayaProvider = FutureProvider<Kelurahan?>((ref) async {
  final profil = await ref.watch(profilProvider.future);
  if (profil == null || !profil.punyaKelurahan) return null;
  return ref.watch(repoProvider).muatKelurahan(profil.kelurahanId);
});

final semuaKelurahanProvider = FutureProvider<List<Kelurahan>>(
  (ref) => ref.watch(repoProvider).muatSemuaKelurahan(),
);

/// Petak yang sudah dibuka pengguna. Permanen.
final jejakProvider = FutureProvider<Set<IdPetak>>(
  (ref) => ref.watch(repoProvider).muatJejak(),
);

/// Jumlah hari aktif dalam 7 hari terakhir —
/// satu-satunya angka publik di Rukun.
final hariAktifProvider = FutureProvider<int>(
  (ref) => ref.watch(repoProvider).hariAktifMingguIni(),
);

/// Kontribusi anggota tim minggu ini, diurutkan menit bergerak.
final kontribusiTimProvider =
    FutureProvider<List<KontribusiAnggota>>((ref) async {
  final profil = await ref.watch(profilProvider.future);
  if (profil == null) return const [];
  return ref.watch(repoProvider).kontribusiTim(profil.kelurahanId);
});

/// Petak pengguna yang akan hangus dalam 24 jam.
final petakHangusProvider = FutureProvider<Set<IdPetak>>(
  (ref) => ref.watch(repoProvider).petakAkanHangus(),
);

/// Kemajuan misi, dihitung dari data nyata pengguna.
final misiProvider = FutureProvider<List<Misi>>((ref) async {
  final repo = ref.watch(repoProvider);
  final jejak = await ref.watch(jejakProvider.future);
  final sesi = await repo.muatSesi();

  final batas = DateTime.now().subtract(const Duration(days: 7));
  final mingguIni = sesi.where((s) => s.mulai.isAfter(batas)).toList();

  // Hari berbeda dengan sesi sebelum jam 9 pagi.
  final pagi = <String>{};
  for (final s in mingguIni) {
    if (s.mulai.hour < 9 && s.menitBergerak > 0) {
      pagi.add('${s.mulai.year}-${s.mulai.month}-${s.mulai.day}');
    }
  }

  final totalMenit =
      mingguIni.fold<int>(0, (j, s) => j + s.menitBergerak);

  return Misi.dariKemajuan(
    hariPagi: pagi.length,
    petakDibuka: jejak.length,
    menitMingguIni: totalMenit,
  );
});

/// Zona privat pengguna — tidak pernah dikirim ke server.
final zonaPrivatProvider = FutureProvider<List<ZonaPrivat>>(
  (ref) => ref.watch(repoProvider).muatZonaPrivat(),
);

/// Posisi terakhir yang diketahui.
final posisiProvider = FutureProvider<Koordinat?>(
  (ref) => ref.watch(lokasiProvider).posisiSekarang(),
);

/// Status klaim sebuah petak — siapa saja yang sudah lewat, dan sisa berapa.
final statusPetakProvider =
    FutureProvider.family<HasilKlaim, IdPetak>((ref, petak) async {
  final repo = ref.watch(repoProvider);
  final profil = await ref.watch(profilProvider.future);
  final lintasan = await repo.lintasanPetak(petak);

  return AturanKlaim.evaluasi(
    lintasan,
    sekarang: DateTime.now(),
    timSudutPandang: profil?.kelurahanId,
  );
});

/// Petak tempat pengguna berdiri sekarang.
final petakSekarangProvider = FutureProvider<IdPetak?>((ref) async {
  final posisi = await ref.watch(posisiProvider.future);
  if (posisi == null) return null;
  return ref.watch(gridProvider).petakDi(posisi);
});
