import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/konfigurasi.dart';
import '../data/lokasi.dart';
import '../data/repo/repo_lokal.dart';
import '../data/repo/repo_supabase.dart';
import '../data/repo/repo_rukun.dart';
import '../domain/aturan/aturan_klaim.dart';
import '../domain/grid/grid_heks.dart';
import '../domain/grid/grid_petak.dart';
import '../domain/model/kelurahan.dart';
import '../domain/model/koordinat.dart';

/// Grid petak yang dipakai seluruh aplikasi.
final gridProvider = Provider<GridPetak>((_) => const GridHeks());

/// Diisi di `main()` setelah SharedPreferences siap.
final prefProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('prefProvider harus di-override di main()'),
);

/// Klien Supabase. Hanya di-override di `main()` bila kredensial tersedia.
final supabaseProvider = Provider<SupabaseClient?>((_) => null);

/// Memilih penyimpanan: Supabase bila dikonfigurasi, kalau tidak lokal.
///
/// Keduanya memenuhi kontrak [RepoRukun] yang sama, jadi seluruh lapisan
/// fitur tidak tahu — dan tidak perlu tahu — mana yang sedang dipakai.
final repoProvider = Provider<RepoRukun>((ref) {
  final klien = ref.watch(supabaseProvider);
  if (Konfigurasi.pakaiSupabase && klien != null) {
    return RepoSupabase(klien);
  }
  return RepoLokal(ref.watch(prefProvider));
});

final lokasiProvider = Provider<LayananLokasi>((_) => const LokasiPerangkat());

/// Profil pengguna. Null berarti belum onboarding.
final profilProvider = FutureProvider<Profil?>(
  (ref) => ref.watch(repoProvider).muatProfil(),
);

/// Kelurahan pengguna.
final kelurahanSayaProvider = FutureProvider<Kelurahan?>((ref) async {
  final profil = await ref.watch(profilProvider.future);
  if (profil == null) return null;
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
