# Backend Rukun

Skema Postgres untuk Supabase. Bisa dipakai juga di Postgres biasa dengan
sedikit penyesuaian (`auth.uid()` perlu diganti).

## Menyalakan

```bash
# 1. Buat proyek di supabase.com, lalu:
supabase link --project-ref <ref-proyek>
supabase db push

# 2. Jalankan aplikasi dengan kredensialnya
flutter run \
  --dart-define=RUKUN_SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=RUKUN_SUPABASE_KUNCI_PUBLIK=sb_publishable_xxx
```

Tanpa kedua nilai itu, aplikasi berjalan sepenuhnya lokal dengan tetangga
tersimulasi — berguna untuk pengembangan dan demo tanpa jaringan.

Kunci publik memang dirancang untuk dipublikasikan. Yang menjaga data adalah
Row Level Security, bukan kerahasiaan kunci.

## Model privasi

Aplikasi yang memetakan pergerakan harian orang punya satu kewajiban yang
tidak bisa ditawar: **data itu tidak boleh bisa dipanen borongan.**

Ancaman yang dijaga:

- Merekonstruksi rute harian seseorang → rumah, kantor, sekolah anak
- Mengetahui kapan rumah seseorang kosong
- Menguntit lewat riwayat lokasi

### Yang tidak pernah sampai ke server

| | Alasan |
|---|---|
| Koordinat mentah | Server hanya menerima **kode petak** — sel heksagon ~132 m |
| Kecepatan & pace | **Tidak ada kolomnya.** Bukan disembunyikan lewat pengaturan |
| Petak di zona privat | Sudah disaring di perangkat sebelum dikirim |
| Jejak titik per titik | Sesi hanya mengirim ringkasan |

### Yang tidak bisa dibaca orang lain

`lintasan` adalah tabel paling sensitif — kumpulan lintasan seseorang adalah
peta hidupnya. RLS-nya: **hanya pemiliknya yang bisa membaca.** Termasuk
sesama warga sekelurahan.

Nama pelintas hanya keluar lewat `petak_detail()`, sebuah fungsi
`security definer` dengan satu batasan penting:

> Pemanggil hanya bisa melihat detail petak yang **dirinya sendiri sudah
> pernah lewati.**

Artinya untuk memetakan pergerakan seseorang, penyerang harus lebih dulu
benar-benar berjalan kaki melewati setiap petak yang ingin diintipnya. Itu
mengubah serangan basis data menjadi kerja fisik yang tidak sepadan.

Pewarnaan wilayah di peta memakai `pemilik_petak()` yang hanya mengembalikan
data agregat — kode petak dan kelurahan pemenangnya, tanpa nama.

### Yang masih perlu ditambahkan sebelum produksi

- **Pembatasan laju** di tingkat gateway. RLS mencegah panen borongan, bukan
  permintaan bertubi-tubi.
- **Kebijakan retensi.** Lintasan lebih dari 7 hari sudah tidak dipakai aturan
  apa pun, jadi seharusnya dihapus, bukan disimpan selamanya.
- **Audit log** untuk pemanggilan `petak_detail`.

## Aturan klaim ada di dua tempat

`AturanKlaim` di Dart dan view `petak_pemilik` di SQL menyatakan aturan yang
sama:

> Pemilik = tim dengan pelintas unik **terbanyak** (minimal 3) dalam 7 hari.
> Seri dipecahkan oleh aktivitas terbaru.

Duplikasi ini disengaja: klien butuh menghitung sendiri agar responsif tanpa
menunggu jaringan, server butuh menghitung sendiri agar tidak bisa dibohongi
klien. Pengujian Dart menjaga sisi klien; view menjaga sisi server.

Bentuk tabel `lintasan` — satu baris per (petak, orang), bukan per kejadian —
membuat aturan "orang **berbeda**" ditegakkan oleh skema itu sendiri, bukan
oleh logika yang bisa lupa dipanggil.

## Berkas

| Berkas | Isi |
|---|---|
| `0001_skema.sql` | Tabel dan view aturan klaim |
| `0002_rls.sql` | Row Level Security + fungsi berlingkup |
| `0003_benih.sql` | Kelurahan awal |
