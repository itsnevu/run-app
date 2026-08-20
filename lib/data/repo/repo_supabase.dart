import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/rukun_colors.dart';
import '../../domain/aturan/zona_privat.dart';
import '../../domain/grid/grid_petak.dart';
import '../../domain/model/kelurahan.dart';
import '../../domain/model/koordinat.dart';
import '../../domain/model/pelintas.dart';
import '../../domain/model/sesi.dart';
import 'repo_rukun.dart';

/// Implementasi [RepoRukun] di atas Supabase.
///
/// Aturan "3 orang berbeda" pada dasarnya multi-pemain, jadi produksi
/// membutuhkan server. Kelas ini memenuhi kontrak yang sama dengan
/// `RepoLokal`, sehingga lapisan fitur tidak berubah sama sekali.
///
/// **Kontrak privasi yang dipegang kelas ini** (lihat `supabase/migrations`):
/// - Koordinat mentah tidak pernah dikirim. Server hanya menerima kode petak.
/// - Kecepatan dan pace tidak pernah dikirim — tidak ada kolomnya di server.
/// - Petak di dalam zona privat sudah disaring di perangkat sebelum sampai
///   ke sini (lihat `KendaliSesi.selesai`).
class RepoSupabase implements RepoRukun {
  RepoSupabase(this._klien, {DateTime Function()? jam, this.zonaLokal})
      : _jam = jam ?? DateTime.now;

  final SupabaseClient _klien;
  final DateTime Function() _jam;

  /// Penyimpanan perangkat untuk zona privat — tidak pernah ke server.
  final RepoRukun? zonaLokal;

  String? get _uid => _klien.auth.currentUser?.id;

  // ── Profil ──────────────────────────────────────────────────────
  @override
  Future<Profil?> muatProfil() async {
    final uid = _uid;
    if (uid == null) return null;

    final baris = await _klien
        .from('profil')
        .select('id, nama, kelurahan_id')
        .eq('id', uid)
        .maybeSingle();

    if (baris == null) return null;
    return Profil(
      id: baris['id'] as String,
      nama: baris['nama'] as String,
      kelurahanId: baris['kelurahan_id'] as String,
    );
  }

  @override
  Future<void> simpanProfil(Profil profil) async {
    final uid = _uid;
    if (uid == null) throw StateError('Belum masuk');

    await _klien.from('profil').upsert({
      'id': uid,
      'nama': profil.nama,
      'kelurahan_id': profil.kelurahanId,
    });
  }

  // ── Kelurahan ───────────────────────────────────────────────────
  @override
  Future<Kelurahan> muatKelurahan(String id) async {
    final semua = await muatSemuaKelurahan();
    return semua.firstWhere((k) => k.id == id, orElse: () => semua.first);
  }

  @override
  Future<List<Kelurahan>> muatSemuaKelurahan() async {
    final baris = await _klien
        .from('kelurahan_ringkas')
        .select('id, nama, warna, jumlah_anggota, petak_dikuasai');

    return [
      for (final b in baris)
        Kelurahan(
          id: b['id'] as String,
          nama: b['nama'] as String,
          warna: _warna(b['warna'] as String),
          jumlahAnggota: (b['jumlah_anggota'] as num?)?.toInt() ?? 0,
          // Persentase dihitung dari petak dikuasai terhadap luas kelurahan.
          // Luas per kelurahan belum ada di skema — sementara dipakai
          // jumlah petak mentah supaya angkanya tetap jujur, bukan dikarang.
          persenWilayah: (b['petak_dikuasai'] as num?)?.toDouble() ?? 0,
        ),
    ];
  }

  static TimWarna _warna(String nama) => TimWarna.values.firstWhere(
        (w) => w.name == nama,
        orElse: () => TimWarna.biru,
      );

  // ── Jejak ───────────────────────────────────────────────────────
  @override
  Future<Set<IdPetak>> muatJejak() async {
    final uid = _uid;
    if (uid == null) return {};

    final baris =
        await _klien.from('jejak').select('petak_kode').eq('profil_id', uid);

    return {
      for (final b in baris) IdPetak.dariKode(b['petak_kode'] as String),
    };
  }

  @override
  Future<void> tambahJejak(Set<IdPetak> petak) async {
    final uid = _uid;
    if (uid == null || petak.isEmpty) return;

    await _klien.from('jejak').upsert(
      [
        for (final p in petak) {'profil_id': uid, 'petak_kode': p.kode},
      ],
      ignoreDuplicates: true,
    );
  }

  // ── Lintasan ────────────────────────────────────────────────────
  @override
  Future<List<Lintasan>> lintasanPetak(IdPetak petak) async {
    final hasil = await lintasanBanyakPetak({petak});
    return hasil[petak] ?? const [];
  }

  @override
  Future<Map<IdPetak, List<Lintasan>>> lintasanBanyakPetak(
      Set<IdPetak> petak) async {
    final uid = _uid;
    final hasil = <IdPetak, List<Lintasan>>{
      for (final p in petak) p: <Lintasan>[],
    };
    if (petak.isEmpty) return hasil;

    // Detail per petak lewat fungsi berlingkup — tabel lintasan sengaja
    // tidak bisa dibaca langsung, bahkan oleh sesama warga sekelurahan.
    for (final p in petak) {
      final baris = await _klien.rpc<List<dynamic>>(
        'petak_detail',
        params: {'p_petak_kode': p.kode},
      );

      hasil[p] = [
        for (final b in baris)
          Lintasan(
            pelintas: Pelintas(
              id: b['profil_id'] as String,
              nama: b['nama'] as String,
              kamu: b['profil_id'] == uid,
            ),
            timId: b['kelurahan_id'] as String,
            waktu: DateTime.parse(b['waktu_pertama'] as String),
          ),
      ];
    }
    return hasil;
  }

  @override
  Future<void> catatLintasan(Set<IdPetak> petak, DateTime waktu) async {
    if (petak.isEmpty) return;

    // Upsert di sisi server: melintas berulang kali hanya memperbarui
    // waktu, tidak pernah menambah hitungan orang.
    await _klien.rpc<void>(
      'catat_lintasan',
      params: {'p_petak_kode': [for (final p in petak) p.kode]},
    );
  }

  /// Pemilik banyak petak sekaligus — untuk mewarnai peta.
  /// Hanya agregat, tanpa nama.
  Future<Map<IdPetak, String>> pemilikPetak(Set<IdPetak> petak) async {
    if (petak.isEmpty) return {};

    final baris = await _klien.rpc<List<dynamic>>(
      'pemilik_petak',
      params: {'p_petak_kode': [for (final p in petak) p.kode]},
    );

    return {
      for (final b in baris)
        IdPetak.dariKode(b['petak_kode'] as String):
            b['kelurahan_id'] as String,
    };
  }

  // ── Sesi ────────────────────────────────────────────────────────
  @override
  Future<void> simpanSesi(Sesi sesi) async {
    final uid = _uid;
    if (uid == null) return;

    // Hanya ringkasan yang dikirim. Jejak koordinat tetap di perangkat.
    await _klien.from('sesi').insert({
      'profil_id': uid,
      'mulai': sesi.mulai.toIso8601String(),
      'selesai': (sesi.selesai ?? _jam()).toIso8601String(),
      'menit_bergerak': sesi.menitBergerak,
      'jarak_meter': sesi.jarakMeter,
    });
  }

  @override
  Future<List<Sesi>> muatSesi() async {
    final uid = _uid;
    if (uid == null) return const [];

    final baris = await _klien
        .from('sesi')
        .select('id, mulai, selesai')
        .eq('profil_id', uid)
        .order('mulai', ascending: false);

    // Titik jejak tidak disimpan di server, jadi sesi dari server tidak
    // punya koordinat. Ini disengaja.
    return [
      for (final b in baris)
        Sesi(
          id: b['id'] as String,
          mulai: DateTime.parse(b['mulai'] as String),
          selesai: DateTime.parse(b['selesai'] as String),
        ),
    ];
  }

  // ── Zona privat ─────────────────────────────────────────────────
  //
  // Sengaja TIDAK disimpan di server. Mengunggah daftar zona privat berarti
  // memberi tahu server persis di mana rumah seseorang — justru kebalikan
  // dari tujuan fitur ini. Zona privat hidup dan mati di perangkat.
  @override
  Future<List<ZonaPrivat>> muatZonaPrivat() async =>
      zonaLokal?.muatZonaPrivat() ?? Future.value(const []);

  @override
  Future<void> simpanZonaPrivat(List<ZonaPrivat> zona) async =>
      zonaLokal?.simpanZonaPrivat(zona);

  @override
  Future<int> hariAktifMingguIni() async {
    final uid = _uid;
    if (uid == null) return 0;

    final batas = _jam().subtract(const Duration(days: 7));
    final baris = await _klien
        .from('sesi')
        .select('mulai')
        .eq('profil_id', uid)
        .gt('mulai', batas.toIso8601String())
        .gt('menit_bergerak', 0);

    final hari = <String>{};
    for (final b in baris) {
      final t = DateTime.parse(b['mulai'] as String);
      hari.add('${t.year}-${t.month}-${t.day}');
    }
    return hari.length;
  }

  /// Kelurahan terdekat dari koordinat.
  ///
  /// Belum ada batas administratif di skema, jadi sementara memakai
  /// pembagian deterministik yang sama dengan RepoLokal.
  static String kelurahanDari(Koordinat k, List<Kelurahan> daftar) {
    if (daftar.isEmpty) return 'tebet';
    final indeks =
        ((k.lat.abs() * 1000 + k.lng.abs() * 1000).floor()) % daftar.length;
    return daftar[indeks].id;
  }
}
