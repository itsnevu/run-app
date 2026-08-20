# Rukun

> **Kabut & Cahaya** — kotamu tertutup kabut, setiap langkah membuka cahaya.

Aplikasi lari & jalan kaki di mana wilayah dimiliki **kampung**, bukan individu.

**Flutter · iOS + Android**

---

## Kenapa ini ada

Data industri aplikasi kebugaran brutal:

- Hanya **3%** pengguna masih aktif 30 hari setelah instal
- **70–80%** tidak pernah kembali setelah sesi pertama
- **73%** dari 50 aplikasi yang dianalisis gagal melayani pemula

Semua permainan rebut-wilayah yang ada (Motera, Run An Empire, TerraRun, Capture,
Squadrats, …) punya cacat yang sama: **PvP individual**. Yang menang selalu yang
paling cepat dan paling jauh. Untuk pemula total, itu mesin penghancur motivasi.

Rukun membalik polaritasnya.

## Mekanik inti

> **Satu petak diklaim ketika ≥3 anggota BERBEDA dari tim yang sama melewatinya
> dalam 7 hari.**
>
> Bukan 1 orang yang lewat 3 kali. Bukan yang paling cepat.

Konsekuensinya:

| | |
|---|---|
| 🏃 Atlet super tidak bisa menang sendirian | Mau lari 30k sehari pun percuma — butuh dua orang lain |
| 👥 Strategi optimal = **ajak orang** | Bukan latihan lebih keras. Ini mesin viral bawaan. |
| 🚶 Pemula bernilai **100%** | Kehadiranmu satu suara penuh, sama dengan pelari elit |
| 🛡️ Anti-curang alami | Butuh 3 akun asli berbeda — jauh lebih mahal dipalsukan |

## Tiga lapis di satu peta

```
LAPIS 3 — MISI       ke mana hari ini?     pin misi, harian & musiman
LAPIS 2 — WILAYAH    apa taruhannya?       warna kelurahan, BISA berpindah
LAPIS 1 — JEJAK      apa milikku?          kabut terbuka, PERMANEN
```

- **Jejak** memberi rasa aman — progres pribadi tidak pernah bisa direbut
- **Wilayah** memberi ketegangan — tapi kolektif, jadi tidak pernah jadi rasa malu pribadi
- **Misi** memberi arah — menghapus kelumpuhan "mau ngapain hari ini"

## Jalan kaki vs lari — bagaimana adilnya?

Dua mata uang terpisah:

| | Dari | Siapa unggul |
|---|---|---|
| **Cakupan Jejak** (lapis 1) | jarak tempuh | Pelari — dan tidak apa-apa, ini pribadi |
| **Poin Klaim** (lapis 2) | **menit bergerak** | **Setara.** 30 menit jalan = 30 menit lari |

## Aturan produk yang tidak bisa ditawar

- ❌ **Pace & kecepatan tidak pernah muncul di permukaan publik mana pun**
- ❌ Tanpa papan peringkat melawan orang asing
- ❌ Tanpa tinggi/berat badan saat onboarding. Selamanya.
- ❌ Tanpa notifikasi rasa bersalah
- ✅ Satu-satunya angka publik: **kehadiran**
- ✅ Jejak pribadi tidak pernah reset, bahkan antar musim

---

## Apa yang sudah jalan

Aplikasi bisa dijalankan dari onboarding sampai merekam sesi dan membuka petak.

| Lapisan | Status |
|---|---|
| Design system (token, komponen, squircle, reduceMotion) | ✅ |
| Grid petak heksagon + geometri | ✅ |
| Aturan klaim 3-orang-berbeda | ✅ |
| Dua mata uang (menit bergerak vs jarak) | ✅ |
| Anti-curang kendaraan & diam | ✅ |
| Zona privat rumah 150 m | ✅ |
| Onboarding 6 menit | ✅ |
| Peta + tiga lapis (Jejak, Wilayah, Kabut) | ✅ |
| Perekaman sesi + GPS | ✅ |
| Layar Tim, Misi, Aku + bilah tab | ✅ |
| Animasi Penyingkapan Kabut | ✅ |
| Penyimpanan lokal | ✅ |
| **Backend multi-pemain** | ⚠️ belum — lihat di bawah |

### Soal backend

Aturan "3 orang berbeda" pada dasarnya multi-pemain, jadi produksi tetap butuh
server. MVP ini memakai `RepoLokal`: penyimpanan di perangkat dengan tetangga
**tersimulasi secara deterministik** dari kode petak — bukan acak, supaya petak
yang sama selalu menunjukkan orang yang sama dan bisa diuji.

Titik sambungannya sudah disiapkan: `RepoRukun` adalah antarmuka. Implementasi
Supabase/Firebase cukup memenuhi kontrak yang sama tanpa mengubah satu baris pun
di lapisan fitur.

Tetangga tersimulasi sengaja tidak pernah berjumlah 3 — petak yang sudah penuh
tanpa peran pengguna menghilangkan momen "kamu yang melengkapi", momen paling
berharga di seluruh produk.

## Struktur proyek

```
lib/
├── main.dart              titik masuk
├── app.dart               cangkang + gerbang onboarding
├── core/
│   ├── theme/             token: warna, gradient, tipografi, jarak, gerak
│   └── util/bentuk.dart   squircle (kurva kontinu iOS)
├── domain/                ⬅ mesin produk, murni Dart, teruji penuh
│   ├── model/             koordinat, pelintas, sesi, kelurahan, misi
│   ├── grid/              GridPetak (antarmuka) + GridHeks (implementasi)
│   └── aturan/            klaim, moda gerak, zona privat
├── data/
│   ├── repo/              RepoRukun (kontrak) + RepoLokal
│   └── lokasi.dart        LayananLokasi + LokasiPalsu untuk uji
├── state/                 penyedia Riverpod + kendali sesi
├── features/
│   ├── onboarding/        alur 6 menit menuju petak pertama
│   ├── peta/              layar rumah + widget peta
│   ├── sesi/              perekaman aktif
│   ├── tim/  misi/  aku/
└── shared/widgets/        tombol, kartu buram, bilah petak, bilah tab,
                           kabut_singkap (animasi tanda tangan)
```

## Design system

Baca **[DESIGN.md](DESIGN.md)** sebelum menulis UI apa pun.

Aturan singkat:

1. **Setiap warna bermakna adalah gradient**, bukan warna datar
2. Semua gradient **135°, 2 stop**, dalam batas **Aturan Delta Kecil** — hue ≤20°,
   lightness 10–18%. Gradient yang bagus tidak terlihat sebagai gradient.
3. Akses token lewat `context.gradients.terang` — **jangan pernah** tulis hex di widget
4. Sudut memakai kurva kontinu (squircle), bukan busur lingkaran
5. Maksimal **2 lapisan buram** terlihat sekaligus (performa Android kelas menengah)

## Jalankan

```bash
flutter pub get
flutter run                 # iOS / Android (butuh Xcode / Android SDK)
flutter run -d chrome       # preview cepat design system, tanpa toolchain mobile
```

Layar showcase menampilkan seluruh token secara visual. Ketuk kartu **Bilah Petak**
untuk mensimulasikan orang berikutnya melewati petak.

### Status toolchain

| | Status |
|---|---|
| Flutter 3.47.1 · Dart 3.13.1 | ✅ terpasang di `~/development/flutter` |
| Web (preview) | ✅ build & jalan |
| Android | ⚠️ butuh Android Studio / SDK |
| iOS | ⚠️ butuh Xcode penuh (Command Line Tools saja tidak cukup) |

```bash
brew install --cask android-studio   # lalu buka & pasang SDK
# iOS: pasang Xcode dari App Store, lalu:
#   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
#   sudo xcodebuild -runFirstLaunch
```

## Uji

```bash
flutter analyze
flutter test
```

**66 test.** Aturan produk dan design system ditegakkan oleh test, bukan cuma
ditulis di dokumen:

*Aturan inti*
- ⭐ satu orang lewat 3 kali **tidak** mengklaim petak
- 3 orang berbeda dari tim yang sama mengklaim
- tim dengan orang terbanyak menang, bukan yang tercepat
- lintasan di luar jendela 7 hari tidak dihitung

*Keadilan & anti-curang*
- ⭐ 30 menit jalan = 30 menit lari dalam Poin Klaim
- naik motor 30 menit membuka **nol** petak
- HP diam di meja tidak menghasilkan apa pun
- petak dekat rumah tidak pernah jadi klaim

*Onboarding*
- tidak pernah meminta tinggi, berat, atau level kebugaran
- kata "lari" tidak muncul di layar pertama
- ajakan pertama adalah 5 menit, bukan 5K
- pace/kecepatan tidak pernah terlihat di permukaan publik

*Geometri & tampilan*
- jalan 5 menit melintasi ~3 petak
- ukuran petak stabil dari Banda Aceh sampai Jayapura
- setiap gradient patuh Aturan Delta Kecil (hue, lightness, saturation)
- tata letak bebas overflow di 320 / 360 / 430 px

> Test ini sudah dua kali membuktikan gunanya: warna Toska melanggar batas
> lightness (23,3% > 22%) dan tiga `Row` meluber di lebar HP — keduanya
> tertangkap sebelum masuk produksi.

## Keputusan teknis

| Hal | Pilihan | Alasan |
|---|---|---|
| Grid petak | **H3 resolusi 10** (~130 m) | Jalan 5 menit ≈ 3 petak — pencapaian cepat & berulang |
| Agregasi | H3 resolusi 8 (~920 m) | Tampilan distrik saat zoom out |
| Peta | `flutter_map` + MapLibre | Style vektor kustom, tanpa kunci pihak ketiga |
| State | Riverpod + Freezed | |
| Font | Plus Jakarta Sans + Inter | Jakarta buatan Indonesia; Inter ≈ SF Pro |

**Anggaran performa** (mayoritas pasar Indonesia = Android kelas menengah):
60fps saat pan dengan 500 poligon · maks 2 `BackdropFilter` · baterai <4%/jam ·
peta harus berfungsi offline.

## Go-to-market

**Per-kelurahan, bukan per-kota.** Kuasai satu kelurahan sampai 50 orang aktif,
*baru* buka kelurahan sebelahnya. Rivalitas butuh lawan — membuka satu kota
sekaligus berarti semua wilayah kosong dan produknya mati rasa.

## Roadmap

- **Fase 1 (MVP)** — Lapis 1 + 2. Tim = kelurahan otomatis dari GPS. Lari & jalan.
- **Fase 2** — Lapis 3 penuh: misi dikurasi + bersponsor. Titik nyala monetisasi.
- **Fase 3** — Run Club OS: klub/kampus/kantor sebagai tipe tim kedua, jadwal sesi,
  pace group, dan **"garansi nggak ditinggal"**.
