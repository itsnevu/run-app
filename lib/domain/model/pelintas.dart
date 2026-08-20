/// Seseorang yang melewati sebuah petak.
///
/// [id] adalah inti dari aturan klaim: yang dihitung adalah orang **berbeda**,
/// bukan berapa kali seseorang lewat. Tanpa identitas yang stabil, aturan ini
/// runtuh — satu orang bisa bolak-balik dan mengklaim petak sendirian.
class Pelintas {
  const Pelintas({
    required this.id,
    required this.nama,
    this.kamu = false,
  });

  final String id;
  final String nama;

  /// Apakah ini pengguna perangkat ini.
  final bool kamu;

  /// Huruf untuk avatar.
  String get huruf =>
      nama.isNotEmpty ? nama.trim()[0].toUpperCase() : '?';

  /// Nama yang ditampilkan — "Kamu" untuk diri sendiri.
  String get sebutan => kamu ? 'Kamu' : nama;

  @override
  bool operator ==(Object other) => other is Pelintas && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Pelintas($id, $nama)';
}

/// Satu kejadian: seseorang melewati sebuah petak pada suatu waktu.
class Lintasan {
  const Lintasan({
    required this.pelintas,
    required this.timId,
    required this.waktu,
  });

  final Pelintas pelintas;

  /// Kelurahan/tim yang diwakili pelintas saat itu.
  final String timId;

  final DateTime waktu;

  @override
  String toString() => 'Lintasan(${pelintas.nama}, $timId, $waktu)';
}
