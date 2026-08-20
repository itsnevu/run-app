/// Tingkat kesulitan misi.
///
/// Jalur pemula ada dan **setara martabatnya**, bukan versi "downgrade"
/// dari misi sungguhan.
enum TingkatMisi {
  santai('Santai'),
  sedang('Sedang'),
  menantang('Menantang');

  const TingkatMisi(this.label);
  final String label;
}

/// Misi berlokasi nyata. DESIGN.md — Lapis 3.
///
/// Petak di peta bersifat emergen tapi hampa — tidak ada yang bercerita ke
/// temannya "gue dapet heksagon 47". Misi memberi tujuan yang bisa diingat
/// dan diceritakan, sekaligus menjadi jalur monetisasi (misi bersponsor).
class Misi {
  const Misi({
    required this.id,
    required this.judul,
    required this.keterangan,
    required this.tingkat,
    this.disponsoriOleh,
    this.selesai = false,
    this.kemajuan = 0,
    this.target = 1,
  });

  final String id;
  final String judul;
  final String keterangan;
  final TingkatMisi tingkat;

  /// Nama sponsor bila misi ini dibayar. Wajib ditampilkan secara jujur.
  final String? disponsoriOleh;

  final bool selesai;
  final int kemajuan;
  final int target;

  bool get bersponsor => disponsoriOleh != null;
  double get rasio => target == 0 ? 0 : (kemajuan / target).clamp(0.0, 1.0);

  Misi salin({int? kemajuan}) => Misi(
        id: id,
        judul: judul,
        keterangan: keterangan,
        tingkat: tingkat,
        disponsoriOleh: disponsoriOleh,
        selesai: (kemajuan ?? this.kemajuan) >= target,
        kemajuan: kemajuan ?? this.kemajuan,
        target: target,
      );

  /// Misi dengan kemajuan dihitung dari aktivitas nyata pengguna.
  ///
  /// Angka-angka ini datang dari sesi dan jejak yang benar-benar tercatat —
  /// bukan hitungan terpisah yang bisa melenceng dari yang dilihat pengguna
  /// di layar lain.
  static List<Misi> dariKemajuan({
    required int hariPagi,
    required int petakDibuka,
    required int menitMingguIni,
  }) =>
      [
        contoh[0].salin(kemajuan: hariPagi),
        contoh[1].salin(kemajuan: (menitMingguIni ~/ 40).clamp(0, 3)),
        contoh[2],
        contoh[3].salin(kemajuan: petakDibuka),
      ];

  static const contoh = <Misi>[
    Misi(
      id: 'm1',
      judul: 'Jalan pagi 3 hari',
      keterangan: 'Keluar rumah sebelum jam 9 pagi, tiga hari minggu ini.',
      tingkat: TingkatMisi.santai,
      kemajuan: 2,
      target: 3,
    ),
    Misi(
      id: 'm2',
      judul: 'Tiga taman dalam seminggu',
      keterangan: 'Kunjungi tiga taman kota berbeda dengan jalan kaki.',
      tingkat: TingkatMisi.sedang,
      kemajuan: 1,
      target: 3,
    ),
    Misi(
      id: 'm3',
      judul: 'Lima kedai kopi lokal',
      keterangan: 'Jalan kaki ke lima kedai kopi independen di kotamu.',
      tingkat: TingkatMisi.sedang,
      disponsoriOleh: 'Kopi Kenangan Lokal',
      kemajuan: 0,
      target: 5,
    ),
    Misi(
      id: 'm4',
      judul: 'Buka 20 petak baru',
      keterangan: 'Jelajahi jalan yang belum pernah kamu lewati.',
      tingkat: TingkatMisi.menantang,
      kemajuan: 7,
      target: 20,
    ),
  ];
}
