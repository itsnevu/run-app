# RUKUN — Design System

> **Kabut & Cahaya**
> Kotamu tertutup kabut. Setiap langkah membuka cahaya.

Rukun adalah aplikasi lari & jalan kaki di mana wilayah dimiliki **kampung**, bukan individu.
Dokumen ini adalah sumber kebenaran tunggal untuk seluruh bahasa visual aplikasi.

**Platform:** Flutter (iOS + Android) · **Target:** iOS 14+ / Android 8+

---

## 1. Filosofi Desain

### 1.1 Metafora inti

Seluruh sistem visual lahir dari satu mekanik produk: **peta yang tertutup kabut, dan terbuka oleh gerakan.**

Ini bukan dekorasi. Metafora ini menentukan setiap keputusan:

| Elemen produk | Terjemahan visual |
|---|---|
| Kabut yang belum terbuka | Frosted glass, blur, desaturasi, abu kebiruan |
| Wilayah yang terbuka | Warna jenuh, cahaya, kejernihan |
| Progres pribadi (permanen) | Hangat, keemasan, tidak pernah pudar |
| Wilayah tim (bisa berpindah) | Warna tim, hidup, sedikit berdenyut |
| Misi (penemuan) | Ungu, berkilau, mengundang |

Kebetulan yang menguntungkan: **material frosted glass khas Apple secara harfiah adalah kabut.** Jadi estetika "Apple simple & clean" yang diminta bukan sekadar gaya yang ditempel — ia adalah ekspresi paling jujur dari mekanik produknya.

### 1.2 Lima prinsip

1. **Peta adalah produknya.** Semua UI adalah lapisan tipis di atas peta. Antarmuka mengambang, tidak pernah menutup. Jangan pernah ada layar penuh yang menyembunyikan peta kecuali benar-benar perlu.
2. **Angka pribadi itu rahasia.** Kecepatan dan pace tidak pernah muncul di permukaan publik mana pun. Ini aturan desain, bukan sekadar pengaturan privasi.
3. **Rayakan kehadiran, bukan performa.** Momen perayaan terbesar dipicu oleh *muncul*, bukan oleh *cepat*.
4. **Satu sumber cahaya.** Setiap gradient mengalir 135° (kiri-atas → kanan-bawah). Satu matahari untuk seluruh aplikasi. Ini yang membuat banyak warna tetap terasa satu sistem.
5. **Tenang secara default, meriah saat berhasil.** Antarmuka diam dan lapang 95% waktu, supaya 5% momen perayaan terasa besar.

### 1.3 Yang secara sadar TIDAK kita lakukan

- ❌ Papan peringkat kecepatan melawan orang asing
- ❌ Lencana yang tidak berarti apa-apa
- ❌ Bayangan tebal, bevel, skeuomorfisme
- ❌ Notifikasi rasa bersalah (*"Kamu belum lari 3 hari!"*)
- ❌ Gradient norak berkontras tinggi (lihat §2.2 — Aturan Delta Kecil)

---

## 2. Warna

### 2.1 Aturan utama: **semua warna adalah gradient**

Di Rukun, **tidak ada warna datar untuk elemen bermakna.** Setiap token warna didefinisikan sebagai gradient 2-stop. Warna datar hanya boleh dipakai untuk teks, garis pemisah 1px, dan ikon berukuran kecil.

Ini yang memberi kesan permukaan yang disentuh cahaya — inti dari kesan "Apple, simple, clean".

### 2.2 ⭐ Aturan Delta Kecil (paling penting di dokumen ini)

> **Gradient yang bagus tidak terlihat sebagai gradient.**
> Ia terlihat seperti satu warna yang sedang terkena cahaya.

Ini yang membedakan "clean" dari "norak". Batas keras:

| Parameter | Gradient fungsional (UI) | Gradient brand (hero) |
|---|---|---|
| Pergeseran hue | **≤ 20°** | **≤ 40°** |
| Delta lightness | **10–18%** | 12–22% |
| Delta saturation | ≤ 15% | ≤ 20% |
| Sudut | **135°, selalu** | 135°, selalu |
| Jumlah stop | **2** | 2 (3 hanya untuk latar layar penuh) |

Kalau sebuah gradient butuh lebih dari 2 stop untuk terlihat bagus, warnanya yang salah — bukan gradient-nya.

### 2.3 Gradient brand

| Token | Stop 1 | Stop 2 | Makna & pemakaian |
|---|---|---|---|
| `terang` | `#2F7BFF` | `#58C6FF` | **Primer.** Kabut tersingkap, kejernihan. CTA utama, elemen aktif, brand. |
| `fajar` | `#FF6B35` | `#FFA552` | **Aksen & perayaan.** Jejak pribadi, PR, momen berhasil. Kehangatan. |
| `misi` | `#7B61FF` | `#A78BFA` | **Penemuan.** Pin misi, quest, hal yang belum terjamah. |
| `kabut` | `#A8B3C5` | `#C9D2E0` | **Terkunci / belum terbuka.** Petak berkabut, state nonaktif. |

### 2.4 Gradient semantik

| Token | Stop 1 | Stop 2 | Pemakaian |
|---|---|---|---|
| `tumbuh` | `#1FB870` | `#4BDD95` | Petak diklaim, target tercapai, tren naik |
| `hangus` | `#FF9500` | `#FFC53D` | Petak akan kedaluwarsa, peringatan lembut |
| `bahaya` | `#FF3B30` | `#FF7A70` | Error, aksi destruktif. **Jarang dipakai** — jangan pernah untuk performa buruk. |
| `netral` | `#8B94A3` | `#A9B2BF` | Informasi, state kosong |

### 2.5 Gradient tim (8 kelurahan)

Dipilih agar tetap bisa dibedakan saat berdampingan di peta, termasuk oleh mata dengan defisiensi warna (diuji terhadap deuteranopia & protanopia).

| # | Nama | Stop 1 | Stop 2 |
|---|---|---|---|
| 1 | Biru | `#2F7BFF` | `#58C6FF` |
| 2 | Merah | `#FF3B5C` | `#FF7A8A` |
| 3 | Hijau | `#1FB870` | `#4BDD95` |
| 4 | Ungu | `#7B61FF` | `#A78BFA` |
| 5 | Oranye | `#FF6B35` | `#FFA552` |
| 6 | Toska | `#0FC7B7` | `#4FE0D4` |
| 7 | Pink | `#FF4FA3` | `#FF8CC4` |
| 8 | Kuning | `#FFB800` | `#FFD75E` |

**Aturan peta:** wilayah tim dirender pada opasitas **28%** (isian) + **90%** (garis tepi 2px). Peta harus tetap terbaca sebagai peta. Warna tim menginformasikan, bukan mendominasi.

**Aturan pembeda ganda:** warna tim tidak pernah menjadi satu-satunya pembeda. Selalu pasangkan dengan pola isian atau label — untuk aksesibilitas dan untuk keterbacaan saat 8 tim berdempetan.

### 2.6 Permukaan netral

Di sinilah kesan "clean" hidup atau mati. Gradient permukaan harus **nyaris tak terlihat** — delta 2–4% saja. Kamu tidak boleh sadar ia ada; kamu hanya merasa permukaannya "hidup".

**Terang (light)**
| Token | Stop 1 | Stop 2 |
|---|---|---|
| `latar` | `#F5F7FA` | `#EEF1F6` |
| `permukaan` | `#FFFFFF` | `#FAFBFD` |
| `permukaanTinggi` | `#FFFFFF` | `#FFFFFF` |

**Gelap (dark)**
| Token | Stop 1 | Stop 2 |
|---|---|---|
| `latar` | `#0A0C10` | `#0E1116` |
| `permukaan` | `#16191F` | `#1C2029` |
| `permukaanTinggi` | `#1C2029` | `#232833` |

### 2.7 Teks (warna datar — satu-satunya pengecualian)

| Peran | Terang | Gelap |
|---|---|---|
| Primer | `#0B0D12` | `#FFFFFF` |
| Sekunder | `#5B6472` | `#A3ACBA` |
| Tersier | `#8B94A3` | `#6E7784` |
| Kuarter | `#B4BCC8` | `#4A525E` |
| Di atas gradient | `#FFFFFF` | `#FFFFFF` |

**⚠️ Aturan kontras di atas gradient:** teks putih hanya boleh diletakkan di atas gradient bila **stop yang paling terang** tetap mencapai rasio kontras 4.5:1. Untuk `kuning`, `hangus`, dan `kabut`, ini **gagal** — gunakan teks gelap `#0B0D12`, atau tambahkan lapisan `scrim` gelap 20%.

### 2.8 Mode gelap

Bukan renungan belakangan. Metafora kabut justru **lebih bagus** dalam gelap, dan sesi lari subuh/malam adalah kasus pakai nyata di Indonesia.

- Latar mendekati hitam murni (`#0A0C10`) untuk layar OLED
- Gradient dinaikkan lightness-nya **+6%** dalam mode gelap agar tidak lumpur
- Petak berkabut jadi **lebih gelap** dari latar, bukan lebih terang
- Peta memakai style gelap; wilayah yang terbuka benar-benar terasa bercahaya

---

## 3. Tipografi

### 3.1 Keluarga huruf

| Peran | Font | Alasan |
|---|---|---|
| Display & angka besar | **Plus Jakarta Sans** (ExtraBold, Bold) | Buatan Indonesia (Tokotype), geometris, modern, berkarakter |
| UI & body | **Inter** | Padanan bebas terdekat dari SF Pro — metrik hampir identik |
| Angka data | **Inter** dengan `tabular figures` | Angka tidak goyang saat berubah — wajib untuk timer |

Menggunakan Plus Jakarta Sans untuk judul memberi produk ini identitas Indonesia yang halus tanpa perlu ornamen batik atau klise visual apa pun.

### 3.2 Skala tipe

Mengikuti langkah Apple HIG. Body 17pt terasa lapang dan mudah dibaca sambil bergerak.

| Token | Ukuran/Tinggi | Berat | Tracking | Font |
|---|---|---|---|---|
| `display` | 40 / 44 | ExtraBold | -0.02em | Jakarta |
| `judul1` | 32 / 38 | Bold | -0.02em | Jakarta |
| `judul2` | 24 / 30 | Bold | -0.01em | Jakarta |
| `judul3` | 20 / 26 | SemiBold | -0.01em | Inter |
| `headline` | 17 / 22 | SemiBold | 0 | Inter |
| `body` | 17 / 24 | Regular | 0 | Inter |
| `callout` | 16 / 22 | Regular | 0 | Inter |
| `subhead` | 15 / 20 | Regular | 0 | Inter |
| `footnote` | 13 / 18 | Regular | 0 | Inter |
| `caption` | 12 / 16 | Medium | +0.01em | Inter |
| `angkaBesar` | 56 / 56 | Bold, tabular | -0.03em | Inter |

### 3.3 Aturan

- **Maksimal 2 tingkat hirarki per layar.** Kalau butuh tiga, layarnya kebanyakan isi.
- Panjang baris maksimal **68 karakter**.
- **Jangan pernah** menaruh teks langsung di atas peta tanpa kartu atau scrim di belakangnya.
- Angka besar selalu tabular. Timer yang bergoyang terasa murah.
- Dukung Dynamic Type sampai **200%**. Tata letak harus mengalir, jangan pernah terpotong.

---

## 4. Spasi & Bentuk

### 4.1 Grid 4pt

`4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48 · 64`

- Padding tepi layar: **20**
- Padding dalam kartu: **16** (padat) / **20** (nyaman)
- Jarak antar kartu: **12**
- Jarak antar bagian: **32**

### 4.2 Sudut membulat (squircle)

Apple memakai **kurva kontinu**, bukan busur lingkaran. Perbedaannya halus tapi sangat terasa — sudut lingkaran biasa terlihat "murah" bersebelahan dengan komponen iOS asli.

Gunakan paket `smooth_corner` atau `figma_squircle`. **Jangan pakai `BorderRadius` bawaan Flutter untuk permukaan besar.**

| Token | Radius | Pemakaian |
|---|---|---|
| `xs` | 8 | Tag, chip kecil |
| `sm` | 12 | Tombol kecil, input |
| `md` | 16 | Kartu, tombol standar |
| `lg` | 20 | Kartu besar |
| `xl` | 28 | Bottom sheet, modal |
| `2xl` | 36 | Kartu perayaan |
| `penuh` | 999 | Pil, avatar, FAB |

### 4.3 Elevasi

Apple menghindari bayangan berat. Kedalaman datang dari **material dan lapisan**, bukan dari drop shadow.

| Level | Spesifikasi |
|---|---|
| 0 | Tanpa bayangan — default |
| 1 | `0 1 2 rgba(11,13,18,.04)` — kartu diam |
| 2 | `0 4 12 rgba(11,13,18,.06)` — mengambang di atas peta |
| 3 | `0 12 32 rgba(11,13,18,.10)` — modal, sheet |
| `pendar` | `0 8 24 <warna-gradient> @ 30%` — hanya untuk tombol gradient primer |

**Pendar berwarna** adalah satu-satunya bayangan mencolok yang diizinkan, dan hanya untuk CTA utama. Ini membuat tombol terasa seperti memancarkan cahaya — sesuai dengan tema.

Dalam mode gelap: turunkan semua opasitas bayangan 50%, ganti dengan garis tepi `rgba(255,255,255,.08)`.

### 4.4 Material buram (frosted glass)

Sinyal "Apple" paling kuat, sekaligus perwujudan literal dari kabut.

| Token | Blur | Latar (terang) | Latar (gelap) | Pemakaian |
|---|---|---|---|---|
| `tipis` | 20 | putih 60% | `#16191F` 60% | Chip mengambang di atas peta |
| `sedang` | 30 | putih 72% | `#16191F` 72% | Tab bar, kartu di atas peta |
| `tebal` | 40 | putih 85% | `#16191F` 85% | Bottom sheet, header |

Setiap material membawa garis tepi rambut `0.5px` `rgba(255,255,255,.5)` di atas (terang) atau `rgba(255,255,255,.1)` (gelap). Detail kecil ini yang membuatnya terbaca sebagai kaca, bukan sekadar putih transparan.

⚠️ **Catatan performa:** `BackdropFilter` di Flutter mahal, terutama di Android kelas menengah — yang merupakan mayoritas pasar Indonesia. Batasi **maksimal 2 lapisan buram terlihat sekaligus**. Sediakan fallback opaque via flag `hematPerforma`.

---

## 5. Gerak

### 5.1 Kurva

Semua gerakan memakai **spring**, tidak pernah linear.

| Token | Spesifikasi | Pemakaian |
|---|---|---|
| `halus` | spring, 350ms, damping .82 | Standar |
| `sigap` | spring, 220ms, damping .88 | Tombol, toggle, chip |
| `singkap` | 600ms, easeOutCubic | **Kabut terbuka** — tanda tangan aplikasi |
| `rayakan` | spring, 700ms, damping .55 | Perayaan (satu-satunya yang boleh memantul) |

### 5.2 Animasi tanda tangan: **Penyingkapan Kabut**

Ini momen yang orang akan rekam layarnya dan kirim ke grup WhatsApp. Ia harus sempurna.

```
0ms     Petak berkabut, abu kebiruan, blur 8
80ms    Denyut halus di bawah posisi pengguna (scale 1.0 → 1.06)
150ms   Kabut mulai larut dari tengah keluar (radial mask menyebar)
        Blur 8 → 0 · saturasi 0.2 → 1.0
400ms   Garis tepi petak menyala gradient `fajar`, ketebalan 2 → 3 → 2
500ms   Angka +1 melayang naik, memudar
600ms   Selesai. Haptic: impactLight.
```

Butuh 600ms. Terasa seperti 200ms karena mengalir keluar dari titik posisi pengguna. **Jangan pernah** pakai fade sederhana — inilah jiwa produknya.

### 5.3 Perayaan

Ketika petak diklaim penuh (orang ke-3 lewat):

- Bottom sheet naik dengan `rayakan`
- Radial gradient tim mengembang dari titik itu, memenuhi layar 12%
- **Bukan konfeti.** Konfeti murahan. Gunakan cahaya lembut yang mengembang.
- Haptic: `notificationSuccess`
- Salinan teks menyebut **orangnya**: *"Bu Sari lewat sini 20 menit lalu. Kamu yang ketiga. Petak ini milik Tebet sekarang."*

Menyebut nama tetangga nyata adalah muatan emosional terbesar yang kita punya. Gunakan setiap kali bisa.

### 5.4 Haptik

| Kejadian | Haptic |
|---|---|
| Petak terbuka | `impactLight` |
| Petak diklaim tim | `notificationSuccess` |
| Sesi mulai / selesai | `impactMedium` |
| Tombol tekan | `selectionClick` |
| Musim dimenangkan | `impactHeavy` + `notificationSuccess` |

Haptik menyala secara default. Ini aplikasi yang dipakai dengan layar di saku — sentuhan sering jadi satu-satunya saluran umpan balik.

---

## 6. Komponen

### 6.1 Tombol

| Varian | Isi | Teks | Radius | Pemakaian |
|---|---|---|---|---|
| **Primer** | gradient `terang` + pendar | putih 17 SemiBold | `penuh` | Satu per layar. Tidak pernah dua. |
| **Sekunder** | material `sedang` | teks primer | `penuh` | Aksi pendamping |
| **Hantu** | transparan | gradient `terang` sebagai teks | — | Aksi tersier |
| **Destruktif** | garis tepi `bahaya` | gradient `bahaya` sbg teks | `penuh` | Jarang |

Tinggi: **52** (utama) / **44** (padat) / **36** (chip). Target sentuh minimum **44×44** selalu.
Ditekan: scale `0.96`, kurva `sigap`, haptic `selectionClick`.

### 6.2 Kartu

Latar `permukaan`, radius `lg` (20), padding 20, elevasi 1.
Di atas peta: naik ke material `sedang` + elevasi 2.

### 6.3 Bilah Petak (Petak Bar)

Komponen paling penting. Menunjukkan progres "3 orang berbeda" — mekanik inti produk.

```
┌──────────────────────────────────────┐
│  Petak Tebet Barat                   │
│                                      │
│   ●━━━━━●━━━━━○                      │
│   Sari  Kamu  ?                      │
│                                      │
│  Tinggal 1 orang lagi buat klaim     │
│  [ Ajak tetangga ]                   │
└──────────────────────────────────────┘
```

- Titik terisi: gradient tim, dengan avatar
- Titik kosong: `kabut`, garis putus-putus
- Garis penghubung: gradient dari terisi → kabut
- Saat titik ketiga terisi → animasi `rayakan`

Ini mengubah aturan abstrak menjadi sesuatu yang bisa dilihat dan dikejar.

### 6.4 Bilah tab

Material `tebal`, mengambang 12 dari bawah, radius `penuh`, margin sisi 16.

```
   Peta      Tim     ( ● )     Misi      Aku
                    REKAM
```

Tombol rekam di tengah: lingkaran 60px, gradient `fajar`, mengambang 8px di atas bilah, dengan pendar. Selama sesi aktif, ia berdenyut lembut (scale 1.0 ↔ 1.04, 2s) — bukan berkedip.

Ikon nonaktif: teks tersier, garis 1.5. Ikon aktif: gradient `terang` + label.

### 6.5 Peta

Fondasi seluruh aplikasi.

- **Style:** minimal & desaturasi. Peta adalah kanvas, bukan bintang. Jalan `#E8EBF0` (terang) / `#1C2029` (gelap). POI disembunyikan kecuali yang relevan misi.
- **Petak berkabut:** isian `kabut` 55% + tekstur noise halus + blur 8
- **Petak terbuka (Jejak pribadi):** peta jernih penuh + tepian `fajar` tipis
- **Wilayah tim:** isian gradient tim 28% + tepi 2px 90%
- **Posisi pengguna:** titik `terang` dengan denyut, tepi putih 3px, bayangan
- **Pin misi:** gradient `misi`, mengambang dengan bayangan lembut, denyut pelan
- **Petak hangus:** tepi gradient `hangus` berdenyut 1.5s

Kelas peta: `MapLibre` / `flutter_map` dengan style vektor kustom. Petak dirender sebagai lapisan poligon **H3**, bukan penanda.

### 6.6 Kartu wilayah tim

Header gradient tim (tinggi 120) + persentase besar (`angkaBesar`) + tren.
Menyebut angka absolut anggota, bukan peringkat: *"47 warga bergerak minggu ini"*.

---

## 7. Arsitektur Layar

```
Onboarding  →  Peta (rumah)  ⇄  Tim  ⇄  Misi  ⇄  Aku
                    ↓
             Sesi Rekam (layar penuh)
                    ↓
             Ringkasan Sesi
```

### 7.1 Onboarding — enam menit menuju momen pertama

Layar paling penting di aplikasi. Data industri: pencapaian di hari pertama menaikkan retensi **+64%**; 70–80% pengguna tidak pernah kembali setelah sesi pertama.

| Waktu | Layar | Isi |
|---|---|---|
| 0:00 | Sambutan | Peta kotamu, tertutup kabut total. Satu titik cahaya: kamu. Tanpa formulir. |
| 0:15 | Izin lokasi | Dijelaskan dengan kalimat manusia, bukan bahasa sistem |
| 0:30 | Tim-mu | *"Kamu di Kelurahan Tebet. Ada 12 orang di sini. Kamu yang ke-13."* |
| 0:45 | Ajakan pertama | **"Jalan 5 menit buat buka petak pertamamu."** Bukan 5K. Bukan 30 menit. |
| 5:45 | Penyingkapan | Animasi kabut terbuka + `+1 petak` + progres tim |

**Aturan mutlak:**
- ❌ Tanpa tinggi/berat badan. Selamanya.
- ❌ Tanpa "pilih level kebugaran" — ini yang membuat pemula merasa tersisih di detik pertama
- ❌ Tanpa pendaftaran akun sebelum petak pertama. Nilai dulu, gesekan belakangan.
- ✅ Kata "lari" tidak muncul sampai setelah petak pertama terbuka

### 7.2 Peta (layar rumah)

Peta layar penuh. Melayang di atasnya:

- **Atas:** chip material tipis — *"Tebet 34% · naik 6%"*
- **Kanan-atas:** tombol lokasi + lapisan
- **Bawah:** sheet ringkas yang bisa ditarik
  - Ringkas: *"3 petak dekat rumahmu hangus jam 18:00"*
  - Sedang: petak terdekat + Bilah Petak
  - Penuh: aktivitas kelurahan hari ini

### 7.3 Sesi Rekam

Minimal secara ekstrem. Dipakai sambil bergerak, sering di bawah sinar matahari.

- Angka besar: **durasi** (`angkaBesar`, tabular) — bukan pace, bukan kecepatan
- Di bawahnya, kecil: petak dibuka hari ini
- Peta menyusut jadi kartu tinggi 40%, kabut terbuka secara langsung
- Satu tombol: **Selesai** (tekan lama, 800ms — mencegah tersentuh tak sengaja)
- Kunci layar otomatis setelah 10 detik, tampilkan tampilan super-minimal
- **Pace tidak pernah ditampilkan.** Ini keputusan produk, bukan kelalaian.

### 7.4 Ringkasan Sesi

- Kartu perayaan penuh gradient
- Peta rute dengan petak yang baru terbuka menyala
- *"Kamu buka 4 petak. 2 di antaranya butuh 1 orang lagi."*
- CTA berbagi → **hanya membagikan gambar peta**, tanpa satu pun angka performa
- Statistik pribadi tersembunyi di balik ketukan "Lihat detail" — ada untuk yang mau, tak terlihat untuk yang tidak

### 7.5 Tim

Header gradient tim, persentase besar, peta mini wilayah.
Daftar kontribusi **di dalam tim** (ini suportif — mereka tetangga). Diurutkan berdasarkan **menit bergerak**, bukan jarak. Pejalan kaki dan pelari bercampur secara alami.

### 7.6 Aku

Peta Jejak pribadi — dibuka permanen, tidak pernah reset. Progres per kecamatan.
Statistik pribadi lengkap ada di sini, **privat secara default**.

---

## 8. Suara & Bahasa

**Bahasa Indonesia sehari-hari yang hangat.** Bukan bahasa korporat, bukan gaul berlebihan.

| Prinsip | ❌ Jangan | ✅ Lakukan |
|---|---|---|
| Sebut orangnya | "Petak diklaim" | "Bu Sari lewat sini tadi pagi" |
| Ajak, jangan suruh | "Kamu belum lari 3 hari!" | "Kelurahan sebelah lagi naik. Jalan sore, yuk?" |
| Rayakan kehadiran | "Pace kamu turun 12%" | "5 hari berturut-turut. Konsisten banget." |
| Tanpa jargon | "Zona 2 latihan aerobik" | "Jalan santai, masih bisa ngobrol" |
| Kolektif | "Kamu peringkat 4" | "47 warga bergerak minggu ini. Termasuk kamu." |

**Terlarang:** *pace, split, VO2max, tempo, zona, kalori terbakar, defisit.*
Riset menunjukkan hanya 13 dari 50 aplikasi menghindari jargon tanpa penjelasan — itu sebabnya 73% gagal melayani pemula.

**Notifikasi** — maksimal 1/hari. Selalu tentang kesempatan, tidak pernah tentang kegagalan.

---

## 9. Aksesibilitas

- Kontras teks **4.5:1** minimum; teks di atas gradient diuji terhadap stop paling terang
- Target sentuh **44×44** minimum
- Dynamic Type sampai **200%** — tata letak mengalir, tidak pernah terpotong
- Warna tim selalu dipasangkan pembeda kedua (pola/label)
- Hormati `reduceMotion`: `singkap` jadi fade sederhana 200ms, denyut dimatikan
- Label VoiceOver/TalkBack untuk seluruh elemen peta
- Semua gradient diuji terhadap deuteranopia, protanopia, tritanopia
- Kontras luar ruang: sediakan mode kecerahan tinggi untuk sesi siang

---

## 10. Catatan Implementasi Flutter

### 10.1 Token gradient lewat ThemeExtension

`ColorScheme` Flutter hanya menyimpan `Color` datar. Karena setiap warna bermakna di Rukun adalah gradient, kita butuh `ThemeExtension` khusus:

```dart
@immutable
class RukunGradients extends ThemeExtension<RukunGradients> {
  final LinearGradient terang, fajar, misi, kabut,
                      tumbuh, hangus, bahaya, netral,
                      latar, permukaan, permukaanTinggi;
  // lerp() + copyWith() diimplementasikan untuk animasi tema mulus
}
```

Diakses lewat `context.gradients.terang`. **Jangan pernah** menulis nilai hex langsung di widget.

### 10.2 Paket yang direkomendasikan

| Kebutuhan | Paket |
|---|---|
| Peta | `flutter_map` + MapLibre (style vektor kustom, tanpa kunci pihak ketiga) |
| Grid heksagon | `h3_flutter` — indeks H3 Uber |
| Lokasi | `geolocator` + `flutter_background_geolocation` |
| Sudut squircle | `smooth_corner` |
| State | `flutter_riverpod` + `freezed` |
| Rute | `go_router` |
| Font | `google_fonts` (Inter, Plus Jakarta Sans) |
| Haptik | `gaimon` (haptik iOS kaya) + `HapticFeedback` bawaan |

### 10.3 Sistem petak: H3 resolusi 10

**Keputusan teknis dengan konsekuensi desain langsung.**

| Resolusi | Lebar rerata | Peran |
|---|---|---|
| **10** | ~130 m | **Petak** — unit klaim |
| 8 | ~920 m | Distrik — untuk agregasi & zoom out |

Jalan kaki 5 menit ≈ 400 m ≈ melintasi 3 petak. Ini memberi pemula rasa pencapaian yang cepat dan berulang tanpa membuat klaim jadi murah.

Heksagon lebih baik dari kotak: semua tetangga berjarak sama, tidak ada kebingungan diagonal, dan bentuknya lebih organik di peta.

### 10.4 Anggaran performa

Mayoritas pasar Indonesia adalah Android kelas menengah. Ini batas keras:

- Peta harus tetap **60fps** saat pan dengan 500 poligon terlihat
- Maksimal **2 lapisan `BackdropFilter`** terlihat bersamaan
- Penyingkapan kabut memakai shader fragmen, bukan 60 widget teranimasi
- Pelacakan latar belakang harus di bawah **4%/jam** penggunaan baterai
- Cache petak yang terbuka secara lokal (`drift`); peta harus berfungsi offline

### 10.5 Struktur berkas

```
lib/
├── main.dart
├── core/
│   ├── theme/          tokens, gradients, typography, extension
│   ├── router/
│   └── util/
├── data/               model, repository, sumber lokal & remote
├── features/
│   ├── onboarding/
│   ├── peta/
│   ├── sesi/
│   ├── tim/
│   ├── misi/
│   └── aku/
└── shared/widgets/     tombol, kartu, bilah_petak, material buram
```

---

## 11. Daftar Periksa Desain

Sebelum layar apa pun dianggap selesai:

- [ ] Setiap warna bermakna adalah gradient, bukan warna datar
- [ ] Setiap gradient 135°, 2 stop, dalam batas Delta Kecil (§2.2)
- [ ] Maksimal satu tombol primer di layar
- [ ] Tidak ada pace/kecepatan yang terlihat di permukaan publik
- [ ] Teks di atas gradient lolos kontras 4.5:1 terhadap stop paling terang
- [ ] Semua target sentuh ≥ 44×44
- [ ] Sudut memakai kurva kontinu, bukan busur lingkaran
- [ ] Maksimal 2 lapisan buram terlihat
- [ ] Mode gelap diperiksa langsung di perangkat, bukan hasil pembalikan otomatis
- [ ] `reduceMotion` dihormati
- [ ] Salinan teks lolos larangan jargon (§8)
- [ ] Layar tetap masuk akal pada Dynamic Type 200%
- [ ] Diuji di bawah sinar matahari langsung
