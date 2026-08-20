/// Cara seseorang bergerak, ditentukan dari kecepatan.
///
/// Dipakai untuk dua hal:
/// 1. **Keadilan** — hanya jalan & lari yang dihitung sebagai menit bergerak.
/// 2. **Anti-curang** — melintas naik kendaraan tidak menghasilkan klaim.
enum ModaGerak {
  diam,
  jalan,
  lari,
  kendaraan;

  /// Ambang dalam meter per detik.
  static const ambangJalan = 0.5; // 1,8 km/jam
  static const ambangLari = 2.2; // 7,9 km/jam
  static const ambangKendaraan = 7.0; // 25,2 km/jam

  static ModaGerak dariKecepatan(double meterPerDetik) {
    if (meterPerDetik < ambangJalan) return diam;
    if (meterPerDetik < ambangLari) return jalan;
    if (meterPerDetik < ambangKendaraan) return lari;
    return kendaraan;
  }

  /// Kecepatan mulai dari sini bertumpuk dengan bersepeda santai.
  static const ambangAmbigu = 3.0; // ~11 km/jam

  /// Klasifikasi yang juga mempertimbangkan irama langkah.
  ///
  /// Kecepatan saja tidak bisa membedakan lari dari bersepeda — rentangnya
  /// bertumpuk. Di zona ambigu (3–7 m/detik), keputusan diserahkan pada ada
  /// tidaknya pola langkah kaki.
  ///
  /// [adaLangkah] bernilai null bila sensor tidak tersedia; dalam hal itu
  /// hasilnya kembali ke [dariKecepatan] — lebih baik memberi keuntungan
  /// pada pengguna daripada menuduh salah orang yang benar-benar berlari.
  static ModaGerak dari(double meterPerDetik, {bool? adaLangkah}) {
    final dasar = dariKecepatan(meterPerDetik);

    if (adaLangkah == null) return dasar;
    if (meterPerDetik < ambangAmbigu) return dasar;

    // Cepat tapi tanpa pola langkah → roda, bukan kaki.
    if (!adaLangkah) return kendaraan;

    // Ada pola langkah, secepat apa pun → manusia yang berlari.
    return meterPerDetik < ambangJalan ? diam : lari;
  }

  /// Apakah moda ini menghasilkan kontribusi.
  ///
  /// Diam tidak dihitung (mencegah "menanam" HP di satu titik), dan kendaraan
  /// tidak dihitung (mencegah klaim sambil naik motor).
  bool get dihitung => this == jalan || this == lari;

  String get label => switch (this) {
        diam => 'Diam',
        jalan => 'Jalan',
        lari => 'Lari',
        kendaraan => 'Kendaraan',
      };
}
