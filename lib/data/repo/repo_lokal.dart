import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/rukun_colors.dart';
import '../../domain/aturan/zona_privat.dart';
import '../../domain/grid/grid_petak.dart';
import '../../domain/model/kelurahan.dart';
import '../../domain/model/koordinat.dart';
import '../../domain/model/pelintas.dart';
import '../../domain/model/sesi.dart';
import 'repo_rukun.dart';

/// Implementasi lokal — menyimpan di perangkat, tetangga disimulasikan.
///
/// Cukup untuk menjalankan dan menguji seluruh mekanik Fase 1 tanpa server.
/// Tetangga tersimulasi bersifat **deterministik** (diturunkan dari kode
/// petak), bukan acak — supaya petak yang sama selalu menunjukkan orang yang
/// sama, dan supaya bisa diuji.
class RepoLokal implements RepoRukun {
  RepoLokal(this._pref, {DateTime Function()? jam})
      : _jam = jam ?? DateTime.now;

  final SharedPreferences _pref;
  final DateTime Function() _jam;

  static const _kProfil = 'profil';
  static const _kJejak = 'jejak';
  static const _kLintasan = 'lintasan';
  static const _kSesi = 'sesi';
  static const _kZona = 'zona_privat';

  /// Kelurahan contoh untuk MVP. Produksi mengambil dari batas wilayah asli.
  static const kelurahanContoh = <Kelurahan>[
    Kelurahan(
        id: 'tebet',
        nama: 'Tebet',
        warna: TimWarna.biru,
        jumlahAnggota: 12,
        persenWilayah: 34,
        persenMingguLalu: 28),
    Kelurahan(
        id: 'menteng',
        nama: 'Menteng',
        warna: TimWarna.merah,
        jumlahAnggota: 18,
        persenWilayah: 41,
        persenMingguLalu: 39),
    Kelurahan(
        id: 'kuningan',
        nama: 'Kuningan',
        warna: TimWarna.hijau,
        jumlahAnggota: 9,
        persenWilayah: 22,
        persenMingguLalu: 25),
    Kelurahan(
        id: 'senayan',
        nama: 'Senayan',
        warna: TimWarna.ungu,
        jumlahAnggota: 15,
        persenWilayah: 30,
        persenMingguLalu: 30),
  ];

  /// Nama tetangga untuk simulasi.
  static const _namaTetangga = [
    'Sari', 'Budi', 'Rina', 'Andi', 'Dewi', 'Eko',
    'Fitri', 'Guntur', 'Hesti', 'Iwan', 'Joko', 'Kartika',
  ];

  // ── Profil ──────────────────────────────────────────────────────
  @override
  Future<Profil?> muatProfil() async {
    final mentah = _pref.getString(_kProfil);
    if (mentah == null) return null;
    final j = jsonDecode(mentah) as Map<String, dynamic>;
    return Profil(
      id: j['id'] as String,
      nama: j['nama'] as String,
      kelurahanId: j['kelurahanId'] as String,
    );
  }

  @override
  Future<void> simpanProfil(Profil profil) async {
    await _pref.setString(
      _kProfil,
      jsonEncode({
        'id': profil.id,
        'nama': profil.nama,
        'kelurahanId': profil.kelurahanId,
      }),
    );
  }

  // ── Kelurahan ───────────────────────────────────────────────────
  @override
  Future<Kelurahan> muatKelurahan(String id) async =>
      kelurahanContoh.firstWhere((k) => k.id == id,
          orElse: () => kelurahanContoh.first);

  @override
  Future<List<Kelurahan>> muatSemuaKelurahan() async => kelurahanContoh;

  /// Kelurahan terdekat dari sebuah koordinat.
  ///
  /// MVP memakai pembagian deterministik dari koordinat. Produksi akan
  /// memakai batas administratif asli.
  static Kelurahan kelurahanDari(Koordinat k) {
    final indeks =
        ((k.lat.abs() * 1000 + k.lng.abs() * 1000).floor()) %
            kelurahanContoh.length;
    return kelurahanContoh[indeks];
  }

  // ── Jejak ───────────────────────────────────────────────────────
  @override
  Future<Set<IdPetak>> muatJejak() async {
    final daftar = _pref.getStringList(_kJejak) ?? const [];
    return daftar.map(IdPetak.dariKode).toSet();
  }

  @override
  Future<void> tambahJejak(Set<IdPetak> petak) async {
    final sekarang = await muatJejak();
    sekarang.addAll(petak);
    await _pref.setStringList(
      _kJejak,
      sekarang.map((p) => p.kode).toList(),
    );
  }

  // ── Lintasan ────────────────────────────────────────────────────
  Map<String, List<Map<String, dynamic>>> _bacaLintasan() {
    final mentah = _pref.getString(_kLintasan);
    if (mentah == null) return {};
    final j = jsonDecode(mentah) as Map<String, dynamic>;
    return j.map((k, v) => MapEntry(
          k,
          (v as List).cast<Map<String, dynamic>>(),
        ));
  }

  @override
  Future<List<Lintasan>> lintasanPetak(IdPetak petak) async {
    final hasil = await lintasanBanyakPetak({petak});
    return hasil[petak] ?? const [];
  }

  @override
  Future<Map<IdPetak, List<Lintasan>>> lintasanBanyakPetak(
      Set<IdPetak> petak) async {
    final tersimpan = _bacaLintasan();
    final profil = await muatProfil();
    final hasil = <IdPetak, List<Lintasan>>{};

    for (final p in petak) {
      final daftar = <Lintasan>[];

      // Tetangga tersimulasi — deterministik dari kode petak.
      daftar.addAll(_tetanggaSimulasi(p));

      // Lintasan pengguna sendiri.
      for (final l in tersimpan[p.kode] ?? const []) {
        daftar.add(Lintasan(
          pelintas: Pelintas(
            id: profil?.id ?? 'saya',
            nama: profil?.nama ?? 'Kamu',
            kamu: true,
          ),
          timId: l['tim'] as String,
          waktu: DateTime.parse(l['waktu'] as String),
        ));
      }
      hasil[p] = daftar;
    }
    return hasil;
  }

  /// Menghasilkan 0–2 tetangga untuk sebuah petak, deterministik.
  ///
  /// Sengaja tidak pernah 3: petak yang sudah penuh tanpa peran pengguna
  /// menghilangkan momen "kamu yang melengkapi" — momen paling berharga
  /// di seluruh produk.
  List<Lintasan> _tetanggaSimulasi(IdPetak p) {
    final benih = (p.q * 73856093) ^ (p.r * 19349663);
    final acak = math.Random(benih);
    final jumlah = acak.nextInt(3); // 0, 1, atau 2
    if (jumlah == 0) return const [];

    final kelurahan = kelurahanContoh[acak.nextInt(kelurahanContoh.length)];
    final sekarang = _jam();

    return [
      for (var i = 0; i < jumlah; i++)
        Lintasan(
          pelintas: Pelintas(
            id: 'sim-${benih.abs()}-$i',
            nama: _namaTetangga[(benih.abs() + i) % _namaTetangga.length],
          ),
          timId: kelurahan.id,
          waktu: sekarang.subtract(Duration(hours: 6 + acak.nextInt(120))),
        ),
    ];
  }

  @override
  Future<void> catatLintasan(Set<IdPetak> petak, DateTime waktu) async {
    final profil = await muatProfil();
    if (profil == null) return;

    final tersimpan = _bacaLintasan();
    for (final p in petak) {
      final daftar = tersimpan.putIfAbsent(p.kode, () => []);
      daftar.add({'tim': profil.kelurahanId, 'waktu': waktu.toIso8601String()});
    }
    await _pref.setString(_kLintasan, jsonEncode(tersimpan));
  }

  // ── Sesi ────────────────────────────────────────────────────────
  @override
  Future<void> simpanSesi(Sesi sesi) async {
    final daftar = _pref.getStringList(_kSesi) ?? <String>[];
    daftar.add(jsonEncode({
      'id': sesi.id,
      'mulai': sesi.mulai.toIso8601String(),
      'selesai': sesi.selesai?.toIso8601String(),
      'menitBergerak': sesi.menitBergerak,
      'jarakMeter': sesi.jarakMeter,
      'titik': [
        for (final t in sesi.titik)
          {
            'lat': t.koordinat.lat,
            'lng': t.koordinat.lng,
            'w': t.waktu.toIso8601String(),
          },
      ],
    }));
    await _pref.setStringList(_kSesi, daftar);
  }

  @override
  Future<List<Sesi>> muatSesi() async {
    final daftar = _pref.getStringList(_kSesi) ?? const [];
    return [
      for (final mentah in daftar)
        () {
          final j = jsonDecode(mentah) as Map<String, dynamic>;
          return Sesi(
            id: j['id'] as String,
            mulai: DateTime.parse(j['mulai'] as String),
            selesai: j['selesai'] == null
                ? null
                : DateTime.parse(j['selesai'] as String),
            titik: [
              for (final t in (j['titik'] as List))
                TitikJejak(
                  Koordinat(
                      (t['lat'] as num).toDouble(), (t['lng'] as num).toDouble()),
                  DateTime.parse(t['w'] as String),
                ),
            ],
          );
        }(),
    ];
  }

  // ── Zona privat ─────────────────────────────────────────────────
  @override
  Future<List<ZonaPrivat>> muatZonaPrivat() async {
    final daftar = _pref.getStringList(_kZona) ?? const [];
    return [
      for (final mentah in daftar)
        () {
          final j = jsonDecode(mentah) as Map<String, dynamic>;
          return ZonaPrivat(
            pusat: Koordinat(
              (j['lat'] as num).toDouble(),
              (j['lng'] as num).toDouble(),
            ),
            radiusMeter: (j['radius'] as num).toDouble(),
            label: j['label'] as String?,
          );
        }(),
    ];
  }

  @override
  Future<void> simpanZonaPrivat(List<ZonaPrivat> zona) async {
    await _pref.setStringList(_kZona, [
      for (final z in zona)
        jsonEncode({
          'lat': z.pusat.lat,
          'lng': z.pusat.lng,
          'radius': z.radiusMeter,
          'label': z.label,
        }),
    ]);
  }

  @override
  Future<int> hariAktifMingguIni() async {
    final sesi = await muatSesi();
    final batas = _jam().subtract(const Duration(days: 7));
    final hari = <String>{};
    for (final s in sesi) {
      if (s.mulai.isAfter(batas) && s.menitBergerak > 0) {
        hari.add('${s.mulai.year}-${s.mulai.month}-${s.mulai.day}');
      }
    }
    return hari.length;
  }
}
