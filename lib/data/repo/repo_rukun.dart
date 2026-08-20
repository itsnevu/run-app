import '../../domain/grid/grid_petak.dart';
import '../../domain/model/kelurahan.dart';
import '../../domain/model/pelintas.dart';
import '../../domain/aturan/zona_privat.dart';
import '../../domain/model/sesi.dart';

/// Kontrak penyimpanan Rukun.
///
/// Sengaja dipisah dari implementasinya. MVP memakai [RepoLokal] yang menyimpan
/// di perangkat dengan tetangga tersimulasi, sehingga seluruh mekanik bisa
/// dijalankan dan diuji tanpa server.
///
/// **Catatan arsitektur.** Aturan "3 orang berbeda" pada dasarnya multi-pemain,
/// jadi produksi tetap membutuhkan server. Antarmuka ini adalah titik
/// sambungannya: `RepoSupabase`/`RepoFirebase` cukup mengimplementasikan
/// kontrak yang sama tanpa mengubah satu baris pun di lapisan fitur.
/// Kontribusi satu anggota tim dalam seminggu.
class KontribusiAnggota {
  const KontribusiAnggota({
    required this.nama,
    required this.menitBergerak,
    this.kamu = false,
  });

  final String nama;
  final int menitBergerak;
  final bool kamu;
}

abstract interface class RepoRukun {
  /// Profil pengguna, atau null bila belum onboarding.
  Future<Profil?> muatProfil();

  Future<void> simpanProfil(Profil profil);

  /// Kelurahan tempat pengguna terdaftar.
  Future<Kelurahan> muatKelurahan(String id);

  /// Semua kelurahan yang dikenal.
  Future<List<Kelurahan>> muatSemuaKelurahan();

  /// Petak yang sudah dibuka pengguna. Permanen, tidak pernah reset.
  Future<Set<IdPetak>> muatJejak();

  /// Menambahkan petak ke Jejak pribadi.
  Future<void> tambahJejak(Set<IdPetak> petak);

  /// Semua lintasan yang tercatat pada sebuah petak.
  Future<List<Lintasan>> lintasanPetak(IdPetak petak);

  /// Lintasan untuk sekumpulan petak sekaligus.
  Future<Map<IdPetak, List<Lintasan>>> lintasanBanyakPetak(Set<IdPetak> petak);

  /// Mencatat bahwa pengguna melewati petak-petak ini.
  Future<void> catatLintasan(Set<IdPetak> petak, DateTime waktu);

  /// Menyimpan sesi yang sudah selesai.
  Future<void> simpanSesi(Sesi sesi);

  Future<List<Sesi>> muatSesi();

  /// Kontribusi anggota tim minggu ini, diukur **menit bergerak**.
  ///
  /// Bukan jarak: itulah yang membuat pejalan kaki dan pelari bercampur
  /// secara alami di papan yang sama.
  Future<List<KontribusiAnggota>> kontribusiTim(String kelurahanId);

  /// Petak milik pengguna yang akan hangus dalam [ambang].
  Future<Set<IdPetak>> petakAkanHangus({
    Duration ambang = const Duration(hours: 24),
  });

  /// Zona privat pengguna — biasanya rumah.
  ///
  /// Petak di dalamnya tidak pernah jadi klaim dan tidak pernah meninggalkan
  /// perangkat.
  Future<List<ZonaPrivat>> muatZonaPrivat();

  Future<void> simpanZonaPrivat(List<ZonaPrivat> zona);

  /// Berapa hari dalam 7 hari terakhir pengguna bergerak.
  ///
  /// Satu-satunya angka publik di Rukun: kehadiran, bukan kecepatan.
  Future<int> hariAktifMingguIni();
}
