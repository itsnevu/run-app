import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/lokasi.dart';
import '../data/repo/repo_lokal.dart';
import '../data/repo/repo_rukun.dart';
import '../data/repo/repo_supabase.dart';
import '../domain/model/kelurahan.dart';
import 'penyedia.dart';

/// Aksi-aksi kecil seputar profil yang dipakai banyak layar.
///
/// Dikumpulkan di satu tempat supaya aturan pentingnya hanya ditulis sekali:
/// **profil boleh belum lengkap.** Pengguna bisa masuk tanpa akun, tanpa
/// lokasi, dan tanpa nama — semuanya menyusul kalau ia mau.
class AksiProfil {
  const AksiProfil(this._ref);

  final Ref _ref;

  RepoRukun get _repo => _ref.read(repoProvider);

  /// Penyimpanan perangkat — selalu tersedia, bahkan tanpa akun.
  RepoLokal get _lokal => RepoLokal(_ref.read(prefProvider));

  /// Profil yang belum punya kelurahan tidak punya tempat di server
  /// (kolomnya wajib berelasi ke kelurahan asli), jadi ia tinggal di
  /// perangkat sampai lokasinya diberikan.
  Future<void> _simpan(Profil profil) async {
    final repo = profil.punyaKelurahan ? _repo : _lokal;
    await repo.simpanProfil(profil);
    _segarkan();
  }

  void _segarkan() {
    _ref.invalidate(profilProvider);
    _ref.invalidate(kelurahanSayaProvider);
  }

  /// Masuk tanpa akun dan tanpa lokasi — "lihat-lihat dulu".
  ///
  /// Membuat profil seadanya supaya sesi tetap bisa direkam, lalu menandai
  /// pembuka selesai. Tidak ada satu pun formulir di jalur ini.
  Future<void> masukSebagaiTamu() async {
    final ada = await _lokal.muatProfil();
    if (ada == null) {
      await _lokal.simpanProfil(const Profil(id: 'saya', nama: 'Kamu'));
    }
    await _ref.read(pembukaSelesaiProvider.notifier).tandai();
    _segarkan();
  }

  /// Meminta izin lokasi lalu menentukan kelurahan.
  ///
  /// Dipanggil dari mana pun pengguna siap — pembuka, layar peta, atau tab
  /// Aku. Status izin dikembalikan apa adanya supaya pemanggil bisa memilih
  /// jalan keluar yang tepat: minta ulang, buka pengaturan aplikasi, atau
  /// nyalakan layanan lokasi perangkat.
  Future<StatusIzin> nyalakanLokasi() async {
    final lokasi = _ref.read(lokasiProvider);
    final izin = await lokasi.mintaIzin();
    if (!izin.bolehMelacak) return izin;

    final posisi = await lokasi.posisiSekarang();
    if (posisi == null) return StatusIzin.ditolak;

    final kelurahan = RepoLokal.kelurahanDari(posisi);
    final ada = await _repo.muatProfil() ?? await _lokal.muatProfil();

    await _simpan(
      (ada ?? const Profil(id: 'saya', nama: 'Kamu'))
          .salin(kelurahanId: kelurahan.id),
    );
    _ref.invalidate(posisiProvider);
    return izin;
  }

  Future<void> gantiNama(String nama) async {
    final bersih = nama.trim();
    if (bersih.isEmpty) return;

    final ada = await _repo.muatProfil() ?? await _lokal.muatProfil();
    await _simpan(
      (ada ?? const Profil(id: 'saya', nama: 'Kamu')).salin(nama: bersih),
    );
  }

  /// Memindahkan progres tamu ke akun yang baru saja dimasuki.
  ///
  /// Inilah yang membuat janji "progresmu ikut" benar, bukan basa-basi:
  /// nama, kelurahan, dan seluruh Jejak pribadi dinaikkan ke server sekali,
  /// tepat setelah masuk. Jejak bersifat gabungan, jadi aman diulang.
  Future<void> selarasSetelahMasuk() async {
    final server = _repo;
    if (server is! RepoSupabase) return;

    final lokal = _lokal;
    final profilLokal = await lokal.muatProfil();
    if (profilLokal == null || !profilLokal.punyaKelurahan) return;

    if (await server.muatProfil() == null) {
      await server.simpanProfil(profilLokal);
    }

    final jejak = await lokal.muatJejak();
    if (jejak.isNotEmpty) await server.tambahJejak(jejak);

    _segarkan();
    _ref.invalidate(jejakProvider);
    _ref.invalidate(hariAktifProvider);
  }

  /// Menghapus seluruh data di perangkat ini.
  ///
  /// Dipakai setelah akun dihapus, dan tersedia sendiri untuk pengguna tamu
  /// yang ingin memulai bersih tanpa harus mencopot aplikasi.
  Future<void> hapusDataPerangkat() async {
    await _ref.read(prefProvider).clear();
    _ref.invalidate(pembukaSelesaiProvider);
    _segarkan();
    _ref.invalidate(jejakProvider);
    _ref.invalidate(hariAktifProvider);
    _ref.invalidate(zonaPrivatProvider);
  }
}

final aksiProfilProvider = Provider<AksiProfil>(AksiProfil.new);
