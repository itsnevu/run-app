import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/aturan/aturan_klaim.dart';
import '../domain/aturan/moda_gerak.dart';
import '../domain/aturan/zona_privat.dart';
import '../domain/grid/grid_petak.dart';
import '../domain/model/pelintas.dart';
import '../domain/model/sesi.dart';
import '../data/checkpoint_sesi.dart';
import '../data/lokasi.dart';
import '../data/repo/repo_rukun.dart';
import 'penyedia.dart';

/// Petak yang baru saja diklaim berkat sesi ini.
class PetakTerklaim {
  const PetakTerklaim({required this.petak, required this.pelintas});

  final IdPetak petak;

  /// Tiga orang yang melengkapi klaim, termasuk pengguna.
  final List<Pelintas> pelintas;
}

/// Hasil sebuah sesi yang sudah selesai.
class HasilSesi {
  const HasilSesi({
    required this.sesi,
    this.petakDibuka = 0,
    this.baruTerklaim = const [],
    this.tersimpan = true,
  });

  final Sesi sesi;
  final int petakDibuka;

  /// Petak yang berubah jadi milik tim karena pengguna menjadi orang ketiga.
  final List<PetakTerklaim> baruTerklaim;

  /// Apakah sesi berhasil disimpan. False berarti jaringan atau penyimpanan
  /// gagal — jejaknya ada di layar, tapi belum sampai ke tim.
  final bool tersimpan;
}

/// Keadaan sesi yang sedang berjalan.
class StatusSesi {
  const StatusSesi({
    this.sesi,
    this.petakBaru = const {},
    this.petakSesi = const {},
    this.moda = ModaGerak.diam,
    this.izinDitolak = false,
    this.izin,
  });

  /// Sesi aktif, atau null bila tidak sedang merekam.
  final Sesi? sesi;

  /// Petak yang baru saja terbuka — untuk memicu animasi penyingkapan.
  final Set<IdPetak> petakBaru;

  /// Seluruh petak yang tersentuh selama sesi ini.
  final Set<IdPetak> petakSesi;

  final ModaGerak moda;
  final bool izinDitolak;

  /// Sebab pasti kegagalan izin — layanan mati, ditolak, atau ditolak
  /// permanen. UI butuh membedakannya: tiga sebab, tiga jalan keluar.
  final StatusIzin? izin;

  bool get merekam => sesi != null && sesi!.berjalan;

  Duration get durasi => sesi?.durasi ?? Duration.zero;
  int get menitBergerak => sesi?.menitBergerak ?? 0;

  StatusSesi salin({
    Sesi? sesi,
    Set<IdPetak>? petakBaru,
    Set<IdPetak>? petakSesi,
    ModaGerak? moda,
    bool? izinDitolak,
    StatusIzin? izin,
    bool kosongkanSesi = false,
  }) =>
      StatusSesi(
        sesi: kosongkanSesi ? null : (sesi ?? this.sesi),
        petakBaru: petakBaru ?? this.petakBaru,
        petakSesi: petakSesi ?? this.petakSesi,
        moda: moda ?? this.moda,
        izinDitolak: izinDitolak ?? this.izinDitolak,
        izin: izin ?? this.izin,
      );
}

/// Mengendalikan perekaman sesi: GPS masuk, petak keluar.
class KendaliSesi extends Notifier<StatusSesi> {
  StreamSubscription<SampelLokasi>? _langganan;
  Timer? _detak;

  /// Sampel sejak checkpoint terakhir. Menulis tiap sampel berarti menulis
  /// ke penyimpanan tiap beberapa detik sepanjang sesi; menulis tiap lima
  /// sampel (~30 detik berjalan kaki) menahan kehilangan maksimum di angka
  /// yang tidak terasa, dengan biaya yang jauh lebih murah.
  int _sejakCheckpoint = 0;
  static const _sampelPerCheckpoint = 5;

  CheckpointSesi get _checkpoint => CheckpointSesi(ref.read(prefProvider));

  /// Zona privat pengguna. Petak di dalamnya tidak pernah jadi klaim.
  ///
  /// Dimuat dari penyimpanan setiap sesi dimulai, dan dibuat otomatis setelah
  /// sesi pertama — lihat [_pastikanZonaRumah].
  List<ZonaPrivat> zonaPrivat = const [];

  @override
  StatusSesi build() {
    ref.onDispose(_bersihkan);
    return const StatusSesi();
  }

  void _bersihkan() {
    _langganan?.cancel();
    _detak?.cancel();
  }

  /// Memulai sesi baru. Mengembalikan false bila izin lokasi ditolak.
  Future<bool> mulai({DateTime Function()? jam}) async {
    final waktu = jam ?? DateTime.now;
    final lokasi = ref.read(lokasiProvider);

    final izin = await lokasi.mintaIzin();
    if (!izin.bolehMelacak) {
      state = state.salin(izinDitolak: true, izin: izin);
      return false;
    }

    zonaPrivat = await ref.read(repoProvider).muatZonaPrivat();

    final mulai = waktu();
    _sejakCheckpoint = 0;
    await _checkpoint.hapus();
    state = StatusSesi(
      sesi: Sesi(id: 's-${mulai.microsecondsSinceEpoch}', mulai: mulai),
    );

    // Detak per detik supaya durasi di layar tetap hidup meski GPS diam.
    _detak = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.merekam) state = state.salin();
    });

    // Waktu diambil dari sampel GPS, bukan dari saat sampel diterima:
    // FusedLocationProvider mem-batch pembaruan saat aplikasi di latar, dan
    // memakai waktu terima membuat seluruh batch tiba dengan selisih ~0 →
    // kecepatan tak hingga → segmen dibuang sebagai kendaraan. Jalan yang
    // nyata terhapus diam-diam. Pengujian tetap boleh menyuntik jam sendiri.
    _langganan = lokasi.aliranPosisi().listen(
      (s) => _terimaPosisi(s, jam != null ? waktu() : s.waktu),
      onError: (_) => state = state.salin(izinDitolak: true),
    );
    return true;
  }

  void _terimaPosisi(SampelLokasi sampel, DateTime waktu) {
    final sesi = state.sesi;
    if (sesi == null || !sesi.berjalan) return;

    // Sampel buruk dibuang sebelum menyentuh apa pun. Fix dengan akurasi 60 m
    // menginterpolasi petak yang tidak pernah diinjak, dan lokasi palsu
    // membuka wilayah dari atas sofa — dua-duanya melubangi aturan inti.
    if (!sampel.layakPakai) return;

    sesi.titik.add(TitikJejak(sampel.koordinat, waktu));

    final grid = ref.read(gridProvider);
    final segmen = sesi.segmen;
    final moda = segmen.isEmpty ? ModaGerak.diam : segmen.last.moda;

    // Hanya ruas yang dihitung yang menghasilkan petak — naik kendaraan
    // dan diam di tempat tidak pernah membuka apa pun.
    final petakSekarang = sesi.petakDilewati(grid);
    final baru = petakSekarang.difference(state.petakSesi);

    state = state.salin(
      sesi: sesi,
      moda: moda,
      petakSesi: petakSekarang,
      petakBaru: baru,
    );

    if (++_sejakCheckpoint >= _sampelPerCheckpoint) {
      _sejakCheckpoint = 0;
      unawaited(_checkpoint.simpan(sesi));
    }
  }

  /// Sesi yang belum sempat diselesaikan — proses dibunuh OS di tengah lari,
  /// atau aplikasi digeser dari daftar tugas.
  Sesi? sesiTertunda() => _checkpoint.muat();

  /// Menyelesaikan sesi tertunda memakai jalur simpan yang sama.
  ///
  /// Waktu selesai diambil dari sampel GPS terakhir, bukan dari sekarang:
  /// sesi yang terputus jam 6 pagi lalu dipulihkan jam 9 malam bukan sesi
  /// 15 jam.
  Future<HasilSesi?> selesaikanTertunda() async {
    final tertunda = _checkpoint.muat();
    if (tertunda == null) return null;

    final akhir = tertunda.salin(selesai: tertunda.titik.last.waktu);
    zonaPrivat = await ref.read(repoProvider).muatZonaPrivat();
    return _simpanHasil(akhir, akhir.titik.last.waktu);
  }

  /// Membuang sesi tertunda tanpa menyimpannya.
  Future<void> buangTertunda() => _checkpoint.hapus();

  /// Menandai animasi penyingkapan sudah tampil.
  void bersihkanPetakBaru() {
    if (state.petakBaru.isEmpty) return;
    state = state.salin(petakBaru: const {});
  }

  /// Mengakhiri sesi dan menyimpan hasilnya.
  Future<HasilSesi?> selesai({DateTime Function()? jam}) async {
    final sesi = state.sesi;
    if (sesi == null) return null;

    _bersihkan();
    final waktu = (jam ?? DateTime.now)();
    final akhir = sesi.salin(selesai: waktu);

    return _simpanHasil(akhir, waktu);
  }

  /// Jalur simpan tunggal — dipakai `selesai()` maupun pemulihan sesi
  /// tertunda, supaya keduanya tidak pernah berbeda perilaku.
  Future<HasilSesi> _simpanHasil(Sesi akhir, DateTime waktu) async {
    final repo = ref.read(repoProvider);
    final grid = ref.read(gridProvider);

    // Jejak pribadi menyimpan SEMUA petak — ini milik pengguna sepenuhnya.
    final petak = akhir.petakDilewati(grid);

    // Seluruh penyimpanan dibungkus: jaringan mati di tengah jalan tidak
    // boleh meninggalkan UI yang masih menyangka sedang merekam padahal GPS
    // sudah dilepas. Sesi yang gagal terkirim tetap dikembalikan ke pemanggil
    // supaya pengguna melihat hasil larinya, bukan layar kosong.
    var tersimpan = true;
    var terklaim = const <PetakTerklaim>[];
    try {
      // Perlindungan rumah dibuat sebelum apa pun dikirim — privasi harus
      // menyala sejak sesi pertama, bukan menunggu pengguna menemukannya
      // di pengaturan.
      await _pastikanZonaRumah(repo, akhir);

      await repo.tambahJejak(petak);

      // Klaim tim hanya menerima petak di luar zona privat. Petak yang
      // disaring di sini tidak pernah meninggalkan perangkat.
      final publik = Privasi.saring(petak, zonaPrivat, grid);
      await repo.catatLintasan(publik, waktu);

      await repo.simpanSesi(akhir);

      terklaim = await _petakBaruTerklaim(repo, publik, waktu);
    } catch (_) {
      // Kegagalan penyimpanan bukan kegagalan sesi. Sampai ada antrean kirim
      // yang tahan mati jaringan, sesi ini hilang dari server — dan itu harus
      // terlihat jujur di UI, bukan disembunyikan.
      tersimpan = false;
    } finally {
      ref.invalidate(jejakProvider);
      ref.invalidate(hariAktifProvider);
      state = const StatusSesi();
    }

    // Checkpoint hanya dibuang kalau datanya benar-benar sudah mendarat.
    // Kalau gagal, sesi tetap tersimpan di perangkat dan bisa dicoba lagi
    // nanti — lebih baik menawarkan pemulihan daripada menghapus diam-diam.
    if (tersimpan) await _checkpoint.hapus();

    return HasilSesi(
      sesi: akhir,
      petakDibuka: petak.length,
      baruTerklaim: terklaim,
      tersimpan: tersimpan,
    );
  }

  /// Membuat zona privat rumah otomatis bila belum ada.
  ///
  /// Titik awal sesi pertama hampir selalu rumah. DESIGN.md §9 menyebut
  /// radius buta ini **wajib ada di hari pertama, bukan nanti** — jadi ia
  /// menyala sendiri, bukan menunggu pengguna menemukannya di pengaturan.
  /// Privasi semacam ini harus opt-out, bukan opt-in.
  ///
  /// Pengguna bisa melihat, memindahkan, atau menghapusnya di layar Aku.
  Future<void> _pastikanZonaRumah(RepoRukun repo, Sesi sesi) async {
    if (zonaPrivat.isNotEmpty) return;
    if (sesi.titik.isEmpty) return;

    zonaPrivat = [
      ZonaPrivat(pusat: sesi.titik.first.koordinat, label: 'Rumah'),
    ];
    await repo.simpanZonaPrivat(zonaPrivat);
  }

  /// Petak yang baru saja lengkap karena pengguna menjadi orang ketiga.
  ///
  /// Ini momen paling berharga di seluruh produk — bukan "petak diklaim",
  /// tapi "kamu yang melengkapi". Karena itu hanya petak dengan jumlah
  /// pelintas tepat [AturanKlaim.orangDibutuhkan] yang dihitung: kalau sudah
  /// lebih, pengguna bukan penentu dan perayaan jadi hampa.
  Future<List<PetakTerklaim>> _petakBaruTerklaim(
    RepoRukun repo,
    Set<IdPetak> petak,
    DateTime sekarang,
  ) async {
    final profil = await repo.muatProfil();
    if (profil == null || petak.isEmpty) return const [];

    final semua = await repo.lintasanBanyakPetak(petak);
    final hasil = <PetakTerklaim>[];

    for (final entri in semua.entries) {
      final klaim = AturanKlaim.evaluasi(
        entri.value,
        sekarang: sekarang,
        timSudutPandang: profil.kelurahanId,
      );
      if (klaim.timPemilik != profil.kelurahanId) continue;

      final pelintas = klaim.pelintasTim(profil.kelurahanId);
      if (pelintas.length != AturanKlaim.orangDibutuhkan) continue;
      if (!pelintas.any((p) => p.kamu)) continue;

      hasil.add(PetakTerklaim(petak: entri.key, pelintas: pelintas));
    }
    return hasil;
  }

  /// Membatalkan sesi tanpa menyimpan.
  void batal() {
    _bersihkan();
    unawaited(_checkpoint.hapus());
    state = const StatusSesi();
  }
}

final kendaliSesiProvider =
    NotifierProvider<KendaliSesi, StatusSesi>(KendaliSesi.new);
