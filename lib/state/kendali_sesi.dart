import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/aturan/aturan_klaim.dart';
import '../domain/aturan/moda_gerak.dart';
import '../domain/aturan/zona_privat.dart';
import '../domain/grid/grid_petak.dart';
import '../domain/model/koordinat.dart';
import '../domain/model/pelintas.dart';
import '../domain/model/sesi.dart';
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
  });

  final Sesi sesi;
  final int petakDibuka;

  /// Petak yang berubah jadi milik tim karena pengguna menjadi orang ketiga.
  final List<PetakTerklaim> baruTerklaim;
}

/// Keadaan sesi yang sedang berjalan.
class StatusSesi {
  const StatusSesi({
    this.sesi,
    this.petakBaru = const {},
    this.petakSesi = const {},
    this.moda = ModaGerak.diam,
    this.izinDitolak = false,
  });

  /// Sesi aktif, atau null bila tidak sedang merekam.
  final Sesi? sesi;

  /// Petak yang baru saja terbuka — untuk memicu animasi penyingkapan.
  final Set<IdPetak> petakBaru;

  /// Seluruh petak yang tersentuh selama sesi ini.
  final Set<IdPetak> petakSesi;

  final ModaGerak moda;
  final bool izinDitolak;

  bool get merekam => sesi != null && sesi!.berjalan;

  Duration get durasi => sesi?.durasi ?? Duration.zero;
  int get menitBergerak => sesi?.menitBergerak ?? 0;

  StatusSesi salin({
    Sesi? sesi,
    Set<IdPetak>? petakBaru,
    Set<IdPetak>? petakSesi,
    ModaGerak? moda,
    bool? izinDitolak,
    bool kosongkanSesi = false,
  }) =>
      StatusSesi(
        sesi: kosongkanSesi ? null : (sesi ?? this.sesi),
        petakBaru: petakBaru ?? this.petakBaru,
        petakSesi: petakSesi ?? this.petakSesi,
        moda: moda ?? this.moda,
        izinDitolak: izinDitolak ?? this.izinDitolak,
      );
}

/// Mengendalikan perekaman sesi: GPS masuk, petak keluar.
class KendaliSesi extends Notifier<StatusSesi> {
  StreamSubscription<Koordinat>? _langganan;
  Timer? _detak;

  /// Zona privat pengguna. Petak di dalamnya tidak pernah jadi klaim.
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

    if (!await lokasi.mintaIzin()) {
      state = state.salin(izinDitolak: true);
      return false;
    }

    final mulai = waktu();
    state = StatusSesi(
      sesi: Sesi(id: 's-${mulai.microsecondsSinceEpoch}', mulai: mulai),
    );

    // Detak per detik supaya durasi di layar tetap hidup meski GPS diam.
    _detak = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.merekam) state = state.salin();
    });

    _langganan = lokasi.aliranPosisi().listen((k) => _terimaPosisi(k, waktu()));
    return true;
  }

  void _terimaPosisi(Koordinat k, DateTime waktu) {
    final sesi = state.sesi;
    if (sesi == null || !sesi.berjalan) return;

    sesi.titik.add(TitikJejak(k, waktu));

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
  }

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

    final repo = ref.read(repoProvider);
    final grid = ref.read(gridProvider);

    // Jejak pribadi menyimpan SEMUA petak — ini milik pengguna sepenuhnya.
    final petak = akhir.petakDilewati(grid);
    await repo.tambahJejak(petak);

    // Klaim tim hanya menerima petak di luar zona privat. Petak yang
    // disaring di sini tidak pernah meninggalkan perangkat.
    final publik = Privasi.saring(petak, zonaPrivat, grid);
    await repo.catatLintasan(publik, waktu);

    await repo.simpanSesi(akhir);

    final terklaim = await _petakBaruTerklaim(repo, publik, waktu);

    ref.invalidate(jejakProvider);
    ref.invalidate(hariAktifProvider);

    state = const StatusSesi();
    return HasilSesi(
      sesi: akhir,
      petakDibuka: petak.length,
      baruTerklaim: terklaim,
    );
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
    state = const StatusSesi();
  }
}

final kendaliSesiProvider =
    NotifierProvider<KendaliSesi, StatusSesi>(KendaliSesi.new);
