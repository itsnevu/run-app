/// Konfigurasi runtime, diisi lewat `--dart-define`.
///
/// Kredensial tidak pernah ditulis di dalam kode. Tanpa nilai ini,
/// aplikasi berjalan sepenuhnya lokal — berguna untuk pengembangan,
/// pengujian, dan demo tanpa jaringan.
///
/// ```bash
/// flutter run \
///   --dart-define=RUKUN_SUPABASE_URL=https://xxx.supabase.co \
///   --dart-define=RUKUN_SUPABASE_KUNCI_PUBLIK=sb_publishable_...
/// ```
abstract final class Konfigurasi {
  static const supabaseUrl =
      String.fromEnvironment('RUKUN_SUPABASE_URL');

  /// Kunci publik (dulu disebut "anon key").
  static const supabaseKunciPublik =
      String.fromEnvironment('RUKUN_SUPABASE_KUNCI_PUBLIK');

  /// Apakah backend tersedia.
  ///
  /// Kunci ini memang dirancang untuk dipublikasikan — yang menjaga data
  /// adalah Row Level Security, bukan kerahasiaan kuncinya.
  /// Lihat `supabase/migrations/0002_rls.sql`.
  static bool get pakaiSupabase =>
      supabaseUrl.isNotEmpty && supabaseKunciPublik.isNotEmpty;
}
