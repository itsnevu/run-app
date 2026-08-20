-- ════════════════════════════════════════════════════════════════════
-- Rukun — penguatan: menutup jalan pintas di sekitar RLS
--
-- Migrasi 0001 dan 0002 menulis model ancaman yang benar, lalu meninggalkan
-- tiga pintu yang membatalkannya:
--
--   1. Tiga view dibuat tanpa `security_invoker`. Sejak Postgres 15 default
--      sebuah view adalah *definer semantics*: ia berjalan dengan hak
--      pemiliknya. Pemilik view di sini juga pemilik tabel, dan pemilik tabel
--      melewati RLS selama `force row level security` tidak dinyalakan.
--      Ditambah default privilege Supabase yang memberi SELECT kepada `anon`,
--      siapa pun yang memegang kunci publik bisa `select * from petak_hitung`
--      dan memanen peta pergerakan seluruh pengguna — persis yang dilarang
--      kalimat pembuka 0001_skema.sql.
--
--   2. Kebijakan insert pada `lintasan` hanya memeriksa PEMILIK baris, tidak
--      pernah ISI baris. Kode petak deterministik dan bisa dihitung offline,
--      jadi klien mana pun bisa mengarang petak yang tidak pernah dilewati,
--      mengaku dari kelurahan mana pun, dan menyetel `waktu_terakhir` ke masa
--      depan sehingga jendela 7 hari tidak pernah berlaku lagi. Baris palsu
--      itu sekaligus memuaskan gerbang "kamu harus benar-benar pernah lewat"
--      milik `petak_detail`, membuka panen nama borongan.
--
--   3. `petak_detail` tidak punya batas waktu pada gerbangnya. Sekali berjalan
--      kaki melewati satu petak, akses ke detail petak itu berlaku selamanya —
--      dan karena hasilnya disaring 7 hari bergulir, memanggilnya tiap hari
--      memberi sinyal "orang ini sedang di rumah / sedang pergi". Itu ancaman
--      nomor dua yang didaftarkan sendiri di 0002_rls.sql.
-- ════════════════════════════════════════════════════════════════════

-- ── 1. View tidak lagi melewati RLS ─────────────────────────────────
alter view petak_hitung  set (security_invoker = true);
alter view petak_pemilik set (security_invoker = true);

-- Dan tidak boleh dibaca langsung sama sekali. Satu-satunya jalan keluar
-- adalah fungsi berlingkup di bawah, yang tidak pernah mengembalikan nama.
revoke all on petak_hitung  from anon, authenticated;
revoke all on petak_pemilik from anon, authenticated;
revoke all on kelurahan_ringkas from anon, authenticated;

-- `pemilik_petak()` tetap berfungsi: ia `security definer`, jadi di dalamnya
-- view berjalan sebagai pemilik fungsi dan tetap melihat seluruh baris.

-- ── 2. Ringkasan kelurahan lewat fungsi, bukan view telanjang ───────
--
-- Angka yang keluar hanya agregat setingkat kelurahan. Tidak ada petak,
-- tidak ada waktu, tidak ada nama — tidak ada yang bisa dirangkai jadi
-- pergerakan seseorang.
create or replace function ringkas_kelurahan()
returns table (
  id              text,
  nama            text,
  warna           text,
  jumlah_anggota  int,
  petak_dikuasai  int
)
language sql
security definer
set search_path = public
stable
as $$
  select k.id, k.nama, k.warna,
         (select count(*)::int from profil p where p.kelurahan_id = k.id),
         (select count(*)::int from petak_pemilik pp where pp.kelurahan_id = k.id)
  from kelurahan k;
$$;

revoke all on function ringkas_kelurahan() from public, anon;
grant execute on function ringkas_kelurahan() to authenticated;

-- ── 3. `lintasan` tidak bisa lagi ditulis langsung ──────────────────
--
-- Satu-satunya jalur tulis adalah `catat_lintasan()`, yang memvalidasi isinya.
-- Menghapus tetap boleh: pengguna berhak menghapus riwayat pergerakannya
-- sendiri (UU PDP No. 27/2022 hak penghapusan).
drop policy if exists "lintasan hanya ditulis pemiliknya"     on lintasan;
drop policy if exists "lintasan hanya diperbarui pemiliknya"  on lintasan;

revoke insert, update, delete on lintasan from anon, authenticated;
grant  delete                 on lintasan to   authenticated;

create policy "lintasan dihapus pemiliknya"
  on lintasan for delete
  to authenticated
  using (profil_id = (select auth.uid()));

-- Pertahanan berlapis: walaupun jalur tulis sudah dikunci, waktu dan
-- kelurahan tetap ditentukan server. `catat_lintasan` sendiri `security
-- definer`, jadi tanpa trigger ini nilai dari klien akan lolos apa adanya.
create or replace function lintasan_waktu_tepercaya()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  -- Tidak boleh masa depan (mengunci petak selamanya), tidak boleh lebih
  -- tua dari jendela klaim (mengarang kehadiran lama). Rentang di antaranya
  -- dibiarkan supaya sesi yang tertahan offline tetap bisa disusulkan.
  new.waktu_terakhir := least(
    greatest(new.waktu_terakhir, now() - interval '7 days'),
    now()
  );

  -- Kelurahan selalu diambil dari profil, tidak pernah dari klien.
  select p.kelurahan_id into new.kelurahan_id
  from profil p where p.id = new.profil_id;

  if tg_op = 'INSERT' then
    new.waktu_pertama := new.waktu_terakhir;
  else
    -- Kunci identitas baris dan tanggal perkenalan.
    new.waktu_pertama := old.waktu_pertama;
    new.profil_id     := old.profil_id;
    new.petak_kode    := old.petak_kode;
  end if;

  return new;
end;
$$;

drop trigger if exists lintasan_waktu_tepercaya_trg on lintasan;
create trigger lintasan_waktu_tepercaya_trg
  before insert or update on lintasan
  for each row execute function lintasan_waktu_tepercaya();

-- ── 4. `catat_lintasan` memeriksa isi, bukan cuma pemanggil ─────────
drop function if exists catat_lintasan(text[]);

create or replace function catat_lintasan(
  p_petak_kode text[],
  p_waktu      timestamptz default now()
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_kelurahan text;
  v_jumlah    int;
begin
  select kelurahan_id into v_kelurahan from profil where id = auth.uid();
  if v_kelurahan is null then
    raise exception 'Profil belum ada';
  end if;

  v_jumlah := coalesce(array_length(p_petak_kode, 1), 0);
  if v_jumlah = 0 then
    return;
  end if;

  -- Sesi 45 menit berjalan kaki menyentuh puluhan petak, bukan ribuan.
  -- Batas ini yang membedakan "merekam sesi" dari "mengecat kota lewat skrip".
  if v_jumlah > 500 then
    raise exception 'Terlalu banyak petak dalam satu panggilan: %', v_jumlah;
  end if;

  -- Bentuk kode petak ditentukan GridPetak.kode di Dart: 'p.<q>.<r>'.
  -- Tanpa pemeriksaan ini, kolomnya menerima teks bebas apa pun.
  if exists (
    select 1 from unnest(p_petak_kode) k
    where k !~ '^p\.-?[0-9]{1,7}\.-?[0-9]{1,7}$'
  ) then
    raise exception 'Kode petak tidak sah';
  end if;

  insert into lintasan (petak_kode, profil_id, kelurahan_id, waktu_terakhir)
  select distinct unnest(p_petak_kode), auth.uid(), v_kelurahan, p_waktu
  on conflict (petak_kode, profil_id)
  do update set waktu_terakhir = excluded.waktu_terakhir;
end;
$$;

revoke all    on function catat_lintasan(text[], timestamptz) from public, anon;
grant  execute on function catat_lintasan(text[], timestamptz) to   authenticated;

-- ── 5. `petak_detail`: gerbang berbatas waktu, waktu kasar ──────────
--
-- Dua perubahan, dua ancaman:
--
--   • Gerbangnya kedaluwarsa 30 hari. Sebelumnya sekali lewat = akses
--     seumur hidup, jadi menguntit cukup berjalan kaki sekali lalu memanggil
--     fungsi ini dari jauh selamanya.
--   • Waktu orang lain dibulatkan ke jam. Presisi mikrodetik menjawab
--     "jam berapa tepatnya tetangga ini keluar rumah" — pertanyaan yang tidak
--     pernah perlu dijawab aplikasi ini. Waktu sendiri tetap utuh.
--
-- `waktu_terakhir` ikut dikembalikan karena itulah kolom yang dipakai
-- jendela 7 hari. Sebelumnya server menyaring dengan `waktu_terakhir` tapi
-- hanya mengembalikan `waktu_pertama`, dan klien menghitung ulang jendelanya
-- dari kolom yang salah — warga lama yang baru lewat kemarin ikut terbuang,
-- sehingga momen "kamu yang melengkapi" tidak pernah menyala untuk mereka.
drop function if exists petak_detail(text);

create or replace function petak_detail(p_petak_kode text)
returns table (
  profil_id     uuid,
  nama          text,
  kelurahan_id  text,
  waktu_pertama timestamptz,
  waktu_terakhir timestamptz
)
language sql
security definer
set search_path = public
stable
as $$
  select
    l.profil_id,
    p.nama,
    l.kelurahan_id,
    case when l.profil_id = auth.uid() then l.waktu_pertama
         else date_trunc('hour', l.waktu_pertama) end,
    case when l.profil_id = auth.uid() then l.waktu_terakhir
         else date_trunc('hour', l.waktu_terakhir) end
  from lintasan l
  join profil p on p.id = l.profil_id
  where l.petak_kode = p_petak_kode
    and l.waktu_terakhir > now() - interval '7 days'
    and exists (
      select 1 from lintasan milik
      where milik.petak_kode = p_petak_kode
        and milik.profil_id  = auth.uid()
        and milik.waktu_terakhir > now() - interval '30 days'
    )
  order by l.waktu_pertama;
$$;

revoke all    on function petak_detail(text) from public, anon;
grant  execute on function petak_detail(text) to   authenticated;

-- ── 6. Indeks yang hilang ───────────────────────────────────────────
--
-- `lintasan_petak_waktu_idx` dipimpin petak_kode, jadi tidak terpakai untuk
-- dua pola ini:
--   • predikat jendela 7 hari yang global (dipakai setiap view klaim)
--   • cascade saat sebuah profil dihapus — tanpa indeks ini, menghapus akun
--     memicu pemindaian penuh tabel lintasan.
create index if not exists lintasan_waktu_idx  on lintasan (waktu_terakhir);
create index if not exists lintasan_profil_idx on lintasan (profil_id);

-- ── 7. Sesi tidak boleh mustahil ────────────────────────────────────
alter table sesi drop constraint if exists sesi_urutan_waktu;
alter table sesi add  constraint sesi_urutan_waktu check (selesai >= mulai);

-- Menit bergerak tidak bisa melebihi durasi sesinya sendiri. Toleransi satu
-- menit untuk pembulatan.
alter table sesi drop constraint if exists sesi_menit_masuk_akal;
alter table sesi add  constraint sesi_menit_masuk_akal
  check (menit_bergerak <= extract(epoch from (selesai - mulai)) / 60 + 1);

-- ── 8. Retensi ──────────────────────────────────────────────────────
--
-- Jendela klaim hanya 7 hari dan gerbang petak_detail 30 hari, jadi baris
-- yang lebih tua tidak punya kegunaan apa pun — ia hanya memperbesar
-- permukaan kalau basis data bocor. Jejak pribadi TIDAK ikut terhapus:
-- itu milik pengguna dan memang permanen.
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule(
      'rukun-bersihkan-lintasan',
      '0 3 * * *',
      $cron$delete from lintasan where waktu_terakhir < now() - interval '30 days'$cron$
    );
  else
    raise notice 'pg_cron tidak terpasang — jadwalkan pembersihan lintasan secara manual.';
  end if;
end
$$;
