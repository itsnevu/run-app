import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/konfigurasi.dart';
import 'penyedia.dart';

/// Mode akun pengguna.
///
/// **Tamu adalah warga kelas satu, bukan versi percobaan.** Seluruh mekanik
/// inti — membuka petak, Jejak pribadi, misi, peta — jalan penuh tanpa akun.
/// Akun hanya dibutuhkan untuk hal yang memang mustahil tanpa server:
/// menyimpan progres lintas perangkat dan berbagi klaim dengan tetangga.
///
/// Ini sekaligus syarat App Store Review Guideline **5.1.1(v)**: aplikasi
/// tidak boleh mewajibkan pendaftaran untuk fitur yang tidak butuh akun.
/// Layar login yang menghadang di detik pertama adalah alasan penolakan
/// yang paling sering terjadi.
enum ModeAkun { tamu, masuk }

/// Keadaan akun saat ini.
class StatusAkun {
  const StatusAkun({required this.mode, this.email});

  final ModeAkun mode;
  final String? email;

  bool get masuk => mode == ModeAkun.masuk;
  bool get tamu => mode == ModeAkun.tamu;

  /// Apakah backend tersedia di build ini. Tanpa ini, tombol masuk
  /// tidak pernah ditawarkan — lebih baik jujur daripada memberi
  /// harapan palsu.
  bool get bisaPunyaAkun => Konfigurasi.pakaiSupabase;

  @override
  bool operator ==(Object other) =>
      other is StatusAkun && other.mode == mode && other.email == email;

  @override
  int get hashCode => Object.hash(mode, email);
}

/// Kegagalan yang sudah diterjemahkan ke bahasa manusia.
class GagalAkun implements Exception {
  const GagalAkun(this.pesan);

  final String pesan;

  @override
  String toString() => pesan;
}

/// Mengendalikan sesi akun. Semua aksinya dipicu pengguna secara sadar —
/// tidak ada satu pun yang berjalan sendiri saat aplikasi dibuka.
class KendaliAkun extends Notifier<StatusAkun> {
  @override
  StatusAkun build() {
    final klien = ref.watch(supabaseProvider);
    if (klien == null) return const StatusAkun(mode: ModeAkun.tamu);

    final langganan = klien.auth.onAuthStateChange.listen((_) {
      state = _baca(klien);
    });
    ref.onDispose(langganan.cancel);

    return _baca(klien);
  }

  StatusAkun _baca(SupabaseClient klien) {
    final pengguna = klien.auth.currentUser;
    return pengguna == null
        ? const StatusAkun(mode: ModeAkun.tamu)
        : StatusAkun(mode: ModeAkun.masuk, email: pengguna.email);
  }

  SupabaseClient get _klien {
    final klien = ref.read(supabaseProvider);
    if (klien == null) {
      throw const GagalAkun(
        'Akun belum aktif di versi ini. Semua progresmu tetap '
        'tersimpan di HP kamu.',
      );
    }
    return klien;
  }

  Future<void> masuk({required String email, required String sandi}) async {
    try {
      await _klien.auth
          .signInWithPassword(email: email.trim(), password: sandi);
    } on AuthException catch (e) {
      throw GagalAkun(_terjemahkan(e));
    }
  }

  /// Mendaftar. Mengembalikan true bila email konfirmasi perlu dibuka dulu.
  Future<bool> daftar({required String email, required String sandi}) async {
    try {
      final hasil =
          await _klien.auth.signUp(email: email.trim(), password: sandi);
      return hasil.session == null;
    } on AuthException catch (e) {
      throw GagalAkun(_terjemahkan(e));
    }
  }

  Future<void> keluar() async {
    try {
      await _klien.auth.signOut();
    } on AuthException catch (e) {
      throw GagalAkun(_terjemahkan(e));
    }
  }

  /// Menghapus akun beserta seluruh datanya di server.
  ///
  /// Wajib ada di dalam aplikasi — App Store §5.1.1(v) mensyaratkan jalur
  /// hapus akun untuk setiap aplikasi yang menawarkan pembuatan akun.
  /// Lihat `supabase/migrations/0004_hapus_akun.sql`.
  Future<void> hapusAkun() async {
    final klien = _klien;
    try {
      await klien.rpc<void>('hapus_akun');
    } on PostgrestException catch (e) {
      throw GagalAkun('Gagal menghapus akun: ${e.message}');
    }
    await klien.auth.signOut();
  }

  /// Menerjemahkan pesan Supabase ke bahasa yang dipakai orang.
  String _terjemahkan(AuthException e) {
    final pesan = e.message.toLowerCase();
    if (pesan.contains('invalid login')) {
      return 'Email atau kata sandi belum cocok.';
    }
    if (pesan.contains('already registered') ||
        pesan.contains('already been registered')) {
      return 'Email ini sudah terdaftar. Coba masuk aja.';
    }
    if (pesan.contains('password') && pesan.contains('least')) {
      return 'Kata sandi minimal 8 karakter.';
    }
    if (pesan.contains('email') && pesan.contains('invalid')) {
      return 'Format emailnya kayaknya keliru.';
    }
    if (pesan.contains('network') || pesan.contains('failed host')) {
      return 'Nggak bisa nyambung ke internet. Coba lagi ya.';
    }
    return e.message;
  }
}

final akunProvider =
    NotifierProvider<KendaliAkun, StatusAkun>(KendaliAkun.new);
