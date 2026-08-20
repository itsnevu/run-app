import '../../core/theme/rukun_colors.dart';

/// Tim — satuan sosial yang memiliki wilayah.
///
/// Untuk MVP, tim = kelurahan, ditentukan otomatis dari lokasi. RT/RW dan
/// kelurahan adalah satuan sosial yang **nyata dan emosional** di Indonesia,
/// berbeda dengan kebanyakan negara lain. Rivalitas antar kampung sudah jadi
/// budaya — kompetitor global tidak bisa meniru ini.
///
/// Fase 3 menambahkan tipe tim lain: klub lari, kampus, kantor.
class Kelurahan {
  const Kelurahan({
    required this.id,
    required this.nama,
    required this.warna,
    this.jumlahAnggota = 0,
    this.persenWilayah = 0,
    this.persenMingguLalu = 0,
  });

  final String id;
  final String nama;
  final TimWarna warna;

  /// Berapa orang yang tergabung.
  final int jumlahAnggota;

  /// Persentase wilayah kelurahan yang dikuasai, 0..100.
  final double persenWilayah;

  final double persenMingguLalu;

  double get selisihPersen => persenWilayah - persenMingguLalu;

  Kelurahan salin({
    int? jumlahAnggota,
    double? persenWilayah,
    double? persenMingguLalu,
  }) =>
      Kelurahan(
        id: id,
        nama: nama,
        warna: warna,
        jumlahAnggota: jumlahAnggota ?? this.jumlahAnggota,
        persenWilayah: persenWilayah ?? this.persenWilayah,
        persenMingguLalu: persenMingguLalu ?? this.persenMingguLalu,
      );
}

/// Profil pengguna.
///
/// Sengaja minimal. DESIGN.md §7.1: tanpa tinggi badan, tanpa berat badan,
/// tanpa "pilih level kebugaran" — selamanya. Itu yang membuat pemula merasa
/// tersisih di detik pertama.
class Profil {
  const Profil({
    required this.id,
    required this.nama,
    this.kelurahanId = '',
  });

  final String id;
  final String nama;

  /// Kelurahan pengguna, atau kosong bila izin lokasi masih ditunda.
  ///
  /// Kosong bukan keadaan rusak: pengguna boleh masuk dan melihat-lihat
  /// dulu sebelum memberi lokasi. Kelurahan menyusul saat ia siap.
  final String kelurahanId;

  bool get punyaKelurahan => kelurahanId.isNotEmpty;

  String get huruf => nama.isNotEmpty ? nama.trim()[0].toUpperCase() : '?';

  Profil salin({String? id, String? nama, String? kelurahanId}) => Profil(
        id: id ?? this.id,
        nama: nama ?? this.nama,
        kelurahanId: kelurahanId ?? this.kelurahanId,
      );
}
