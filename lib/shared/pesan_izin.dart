import 'package:flutter/material.dart';

import '../data/lokasi.dart';

/// Satu tempat untuk semua pesan izin lokasi.
///
/// Sebelumnya kalimat dan jalan keluarnya ditulis ulang di layar Peta, Tim,
/// Aku, dan pembuka — empat salinan yang pelan-pelan berbeda bunyinya. Lebih
/// buruk lagi, tombol Rekam tidak punya salinan sama sekali: izin ditolak,
/// tombol diam, pengguna tidak pernah tahu kenapa.
///
/// Aturannya: **tiga sebab, tiga jalan keluar.** Layanan mati diarahkan ke
/// pengaturan perangkat, penolakan permanen ke pengaturan aplikasi, dan
/// penolakan biasa cukup diberi tahu — ia masih boleh diminta lagi nanti.
Future<void> tampilkanPesanIzin(
  BuildContext context,
  LayananLokasi lokasi,
  StatusIzin izin,
) async {
  if (izin.bolehMelacak) return;

  final (pesan, labelAksi, aksi) = switch (izin) {
    StatusIzin.layananMati => (
        'Layanan lokasi di HP kamu lagi mati.',
        'Pengaturan',
        lokasi.bukaPengaturanLokasi,
      ),
    StatusIzin.ditolakPermanen => (
        'Izin lokasinya perlu dinyalakan lewat Pengaturan.',
        'Pengaturan',
        lokasi.bukaPengaturanAplikasi,
      ),
    // Ditolak sekali bukan penolakan selamanya — jangan diseret ke
    // pengaturan, cukup diberi tahu.
    _ => (
        'Belum diizinkan. Kamu tetap bisa pakai Rukun tanpa ini.',
        null,
        null,
      ),
  };

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(pesan),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
      action: labelAksi == null || aksi == null
          ? null
          : SnackBarAction(label: labelAksi, onPressed: aksi),
    ),
  );
}
