import '../model/pelintas.dart';

/// Hasil evaluasi klaim sebuah petak.
class HasilKlaim {
  const HasilKlaim({
    required this.timPemilik,
    required this.pelintasPerTim,
    required this.sisaUntukKlaim,
  });

  /// Tim yang memiliki petak ini, atau null bila belum ada yang mengklaim.
  final String? timPemilik;

  /// Pelintas **unik** per tim di dalam jendela waktu, terurut dari yang
  /// paling awal lewat.
  final Map<String, List<Pelintas>> pelintasPerTim;

  /// Berapa orang lagi yang dibutuhkan tim sudut pandang untuk mengklaim.
  /// Bernilai 0 bila tim itu sudah memenuhi syarat.
  final int sisaUntukKlaim;

  bool get terklaim => timPemilik != null;

  List<Pelintas> pelintasTim(String timId) => pelintasPerTim[timId] ?? const [];
}

/// **Aturan inti Rukun.**
///
/// > Satu petak diklaim ketika **≥3 anggota BERBEDA** dari tim yang sama
/// > melewatinya dalam 7 hari.
///
/// Bukan 1 orang yang lewat 3 kali. Bukan yang paling cepat.
///
/// Konsekuensi yang disengaja:
/// - Atlet super tidak bisa menang sendirian — mau lari 30 km sehari pun
///   percuma tanpa dua orang lain.
/// - Strategi optimal berubah dari "latihan lebih keras" menjadi
///   "ajak tetangga". Ini mesin viral yang tertanam di aturan, bukan di
///   tombol berbagi.
/// - Kontribusi pemula bernilai 100%. Kehadiran satu orang adalah satu suara
///   penuh, sama nilainya dengan pelari elit.
/// - Anti-curang alami: memalsukan klaim butuh 3 identitas asli yang berbeda.
abstract final class AturanKlaim {
  /// Jumlah orang berbeda yang dibutuhkan.
  static const orangDibutuhkan = 3;

  /// Jendela waktu berlakunya lintasan.
  static const jendela = Duration(days: 7);

  /// Mengevaluasi kepemilikan sebuah petak.
  ///
  /// [timSudutPandang] menentukan nilai [HasilKlaim.sisaUntukKlaim] —
  /// biasanya diisi tim pengguna yang sedang melihat.
  static HasilKlaim evaluasi(
    List<Lintasan> lintasan, {
    required DateTime sekarang,
    String? timSudutPandang,
  }) {
    final batas = sekarang.subtract(jendela);

    // Hanya lintasan di dalam jendela yang berlaku.
    final berlaku = lintasan.where((l) => l.waktu.isAfter(batas)).toList()
      ..sort((a, b) => a.waktu.compareTo(b.waktu));

    // Kelompokkan per tim, ambil pelintas UNIK — kemunculan pertama menang.
    final perTim = <String, List<Pelintas>>{};
    final waktuTerakhir = <String, DateTime>{};
    for (final l in berlaku) {
      final daftar = perTim.putIfAbsent(l.timId, () => <Pelintas>[]);
      if (!daftar.any((p) => p.id == l.pelintas.id)) {
        daftar.add(l.pelintas);
      }
      waktuTerakhir[l.timId] = l.waktu;
    }

    // Pemilik = tim dengan pelintas unik TERBANYAK yang memenuhi ambang.
    //
    // Sengaja "terbanyak", bukan "yang pertama mencapai 3": ini menghargai
    // jumlah orang yang digerakkan, persis nilai yang dianut produk ini.
    // Seri dipecahkan oleh aktivitas terbaru, supaya wilayah terasa hidup.
    String? pemilik;
    var terbanyak = 0;
    DateTime? terbaru;

    for (final entri in perTim.entries) {
      final jumlah = entri.value.length;
      if (jumlah < orangDibutuhkan) continue;

      final waktu = waktuTerakhir[entri.key]!;
      final menang = jumlah > terbanyak ||
          (jumlah == terbanyak && (terbaru == null || waktu.isAfter(terbaru)));

      if (menang) {
        pemilik = entri.key;
        terbanyak = jumlah;
        terbaru = waktu;
      }
    }

    var sisa = orangDibutuhkan;
    if (timSudutPandang != null) {
      final punya = perTim[timSudutPandang]?.length ?? 0;
      sisa = (orangDibutuhkan - punya).clamp(0, orangDibutuhkan);
    }

    return HasilKlaim(
      timPemilik: pemilik,
      pelintasPerTim: perTim,
      sisaUntukKlaim: sisa,
    );
  }

  /// Kapan sebuah petak berhenti dihitung bila tidak ada yang lewat lagi.
  static DateTime kedaluwarsa(DateTime lintasanTerakhir) =>
      lintasanTerakhir.add(jendela);

  /// Apakah petak akan hangus dalam [ambang] ke depan.
  static bool akanHangus(
    DateTime lintasanTerakhir,
    DateTime sekarang, {
    Duration ambang = const Duration(hours: 24),
  }) {
    final habis = kedaluwarsa(lintasanTerakhir);
    return habis.isAfter(sekarang) && habis.difference(sekarang) <= ambang;
  }
}
