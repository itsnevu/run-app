import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/lokasi.dart';
import '../data/repo/repo_lokal.dart';
import '../data/repo/repo_rukun.dart';
import '../data/repo/repo_supabase.dart';
import '../domain/model/kelurahan.dart';
import 'akun.dart';
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

  /// Menyimpan profil ke perangkat **dan**, bila memungkinkan, ke server.
  ///
  /// Perangkat selalu ditulis — ia sumber untuk penyelarasan berikutnya dan
  /// satu-satunya rumah bagi pengguna tanpa akun. Server hanya ikut ditulis
  /// kalau profilnya sudah punya kelurahan, karena kolom itu wajib berelasi
  /// ke kelurahan asli di skema.
  ///
  /// Menulis ke salah satu saja pernah membuat data terbelah: pengguna yang
  /// sudah masuk tapi belum memberi lokasi menyimpan nama barunya ke
  /// perangkat, sementara seluruh layar membaca server — namanya seolah
  /// tidak pernah berubah.
  Future<void> _simpan(Profil profil) async {
    await _lokal.simpanProfil(profil);

    final server = _repo;
    if (server is RepoSupabase && profil.punyaKelurahan) {
      await server.simpanProfil(profil);
    }
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

    // Kelurahan baru saja lahir. Kalau pengguna sudah masuk, inilah saat
    // progres yang tertahan di perangkat akhirnya bisa naik — sebelum ini
    // server menolaknya karena profil butuh kelurahan.
    if (_ref.read(akunProvider).masuk) {
      try {
        await selarasSetelahMasuk();
      } catch (_) {
        // Gagal menyelaraskan bukan alasan menggagalkan izin lokasi.
        // Data lokal tetap utuh dan akan dicoba lagi lain kali.
      }
    }
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
    if (profilLokal == null) return;

    // Baris `jejak` berelasi ke `profil`, jadi urutannya tidak bisa dibalik:
    // tanpa profil server, satu pun petak tidak akan diterima.
    //
    // Dan profil server wajib punya kelurahan. Kalau belum ada, penyelarasan
    // ditunda — BUKAN dibatalkan: data tetap di perangkat, dan
    // [nyalakanLokasi] memanggil ulang fungsi ini begitu kelurahan didapat.
    // Sementara itu [profilProvider] jatuh kembali ke salinan perangkat,
    // supaya tidak ada yang terlihat hilang.
    if (!profilLokal.punyaKelurahan) return;

    if (await server.muatProfil() == null) {
      await server.simpanProfil(profilLokal);
    }

    final jejak = await lokal.muatJejak();
    if (jejak.isNotEmpty) await server.tambahJejak(jejak);

    _segarkan();
    _ref.invalidate(jejakProvider);
    _ref.invalidate(hariAktifProvider);
  }

  /// Menghapus data Rukun di perangkat ini.
  ///
  /// Dipakai setelah akun dihapus, dan tersedia sendiri untuk pengguna tamu
  /// yang ingin memulai bersih tanpa harus mencopot aplikasi.
  ///
  /// **Bukan `pref.clear()`.** SharedPreferences di sini dipakai bersama
  /// paket lain — `supabase_flutter` menyimpan token sesinya di store yang
  /// sama. Menyapu semuanya membuat pengguna terlempar keluar dari akunnya
  /// tanpa pernah diberi tahu, dan baru ketahuan saat aplikasi dibuka lagi.
  /// Jadi yang dihapus hanya kunci yang benar-benar milik Rukun.
  Future<void> hapusDataPerangkat() async {
    final pref = _ref.read(prefProvider);
    for (final kunci in [
      ...RepoLokal.kunciMilikRukun,
      PembukaSelesai.kunci,
    ]) {
      await pref.remove(kunci);
    }
    _ref.invalidate(pembukaSelesaiProvider);
    _segarkan();
    _ref.invalidate(jejakProvider);
    _ref.invalidate(hariAktifProvider);
    _ref.invalidate(zonaPrivatProvider);
  }
}

final aksiProfilProvider = Provider<AksiProfil>(AksiProfil.new);
