-- ════════════════════════════════════════════════════════════════════
-- Rukun — skema dasar
--
-- Prinsip yang mengikat seluruh berkas ini:
--
--   1. Kecepatan dan pace TIDAK PERNAH disimpan di server. Bukan
--      disembunyikan lewat pengaturan — memang tidak ada kolomnya.
--   2. Koordinat mentah TIDAK PERNAH meninggalkan perangkat. Server hanya
--      menerima kode petak, yaitu sel heksagon selebar ~132 m.
--   3. Tabel lintasan tidak bisa dibaca langsung oleh siapa pun. Detail
--      petak hanya keluar lewat fungsi yang membatasi ruang lingkupnya,
--      supaya pergerakan harian orang tidak bisa dipanen borongan.
-- ════════════════════════════════════════════════════════════════════

create extension if not exists "uuid-ossp";

-- ── Kelurahan ───────────────────────────────────────────────────────
create table if not exists kelurahan (
  id          text primary key,
  nama        text not null,
  warna       text not null,
  dibuat_pada timestamptz not null default now()
);

-- ── Profil ──────────────────────────────────────────────────────────
-- Sengaja minimal. Tidak ada tinggi badan, berat badan, umur, atau level
-- kebugaran — bukan cuma tidak ditanya di UI, tapi memang tidak ada
-- tempatnya di basis data.
create table if not exists profil (
  id           uuid primary key references auth.users on delete cascade,
  nama         text not null check (char_length(nama) between 1 and 40),
  kelurahan_id text not null references kelurahan(id),
  dibuat_pada  timestamptz not null default now()
);

-- ── Lintasan ────────────────────────────────────────────────────────
-- Satu baris per (petak, orang) — bukan per kejadian melintas.
--
-- Bentuk ini bukan sekadar hemat: aturan Rukun menghitung orang BERBEDA,
-- jadi menyimpan setiap kali seseorang lewat justru menyimpan data yang
-- tidak pernah dipakai, sekaligus memperinci jejak pergerakan seseorang
-- lebih dari yang diperlukan.
--
-- Perhatikan yang TIDAK ada di sini: lintang, bujur, kecepatan, pace,
-- durasi, jarak.
create table if not exists lintasan (
  petak_kode     text not null,
  profil_id      uuid not null references profil(id) on delete cascade,
  kelurahan_id   text not null references kelurahan(id),
  waktu_pertama  timestamptz not null default now(),
  waktu_terakhir timestamptz not null default now(),
  primary key (petak_kode, profil_id)
);

create index if not exists lintasan_petak_waktu_idx
  on lintasan (petak_kode, waktu_terakhir desc);
create index if not exists lintasan_kelurahan_idx
  on lintasan (kelurahan_id, waktu_terakhir desc);

-- ── Jejak pribadi ───────────────────────────────────────────────────
-- Petak yang pernah dibuka seseorang. Permanen, tidak pernah reset,
-- dan hanya bisa dilihat pemiliknya.
create table if not exists jejak (
  profil_id  uuid not null references profil(id) on delete cascade,
  petak_kode text not null,
  dibuka_pada timestamptz not null default now(),
  primary key (profil_id, petak_kode)
);

-- ── Sesi ────────────────────────────────────────────────────────────
-- Ringkasan sesi, tanpa jejak koordinat.
--
-- menit_bergerak disimpan karena itulah mata uang kontribusi tim.
-- jarak_meter disimpan hanya untuk pemiliknya (lihat kebijakan RLS)
-- dan tidak pernah dipakai untuk peringkat apa pun.
create table if not exists sesi (
  id             uuid primary key default uuid_generate_v4(),
  profil_id      uuid not null references profil(id) on delete cascade,
  mulai          timestamptz not null,
  selesai        timestamptz not null,
  menit_bergerak int not null check (menit_bergerak >= 0),
  jarak_meter    numeric not null check (jarak_meter >= 0)
);

create index if not exists sesi_profil_mulai_idx
  on sesi (profil_id, mulai desc);

-- ════════════════════════════════════════════════════════════════════
-- Aturan klaim, dinyatakan sebagai view
--
-- Cerminan persis dari AturanKlaim di Dart. Dua tempat, satu aturan —
-- pengujian Dart menjaga sisi klien, view ini menjaga sisi server.
-- ════════════════════════════════════════════════════════════════════

-- Jumlah orang BERBEDA per tim pada setiap petak, di dalam jendela 7 hari.
create or replace view petak_hitung as
  select
    petak_kode,
    kelurahan_id,
    count(*)::int          as jumlah_pelintas,
    max(waktu_terakhir)    as aktivitas_terakhir
  from lintasan
  where waktu_terakhir > now() - interval '7 days'
  group by petak_kode, kelurahan_id;

-- Pemilik petak.
--
-- Urutannya penting dan disengaja: jumlah pelintas TERBANYAK menang,
-- bukan yang tercepat atau yang duluan. Ini menghargai jumlah orang yang
-- digerakkan — nilai inti produk. Seri dipecahkan oleh aktivitas terbaru
-- supaya wilayah terasa hidup.
create or replace view petak_pemilik as
  select distinct on (petak_kode)
    petak_kode,
    kelurahan_id,
    jumlah_pelintas,
    aktivitas_terakhir
  from petak_hitung
  where jumlah_pelintas >= 3
  order by petak_kode, jumlah_pelintas desc, aktivitas_terakhir desc;

-- Persentase wilayah per kelurahan.
create or replace view kelurahan_ringkas as
  select
    k.id,
    k.nama,
    k.warna,
    (select count(*)::int from profil p where p.kelurahan_id = k.id)
      as jumlah_anggota,
    (select count(*)::int from petak_pemilik pp where pp.kelurahan_id = k.id)
      as petak_dikuasai
  from kelurahan k;
