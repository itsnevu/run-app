-- ════════════════════════════════════════════════════════════════════
-- Rukun — Row Level Security
--
-- Aplikasi yang memetakan pergerakan harian orang punya satu kewajiban
-- yang tidak bisa ditawar: data itu tidak boleh bisa dipanen borongan.
--
-- Ancaman yang dijaga di sini:
--   • Merekonstruksi rute harian seseorang → rumah, kantor, sekolah anak
--   • Mengetahui kapan rumah seseorang kosong
--   • Menguntit lewat riwayat lokasi
--
-- Cara menjaganya: tabel `lintasan` TIDAK BISA dibaca langsung oleh
-- siapa pun, termasuk sesama warga sekelurahan. Nama pelintas hanya
-- keluar lewat fungsi dengan ruang lingkup terbatas.
-- ════════════════════════════════════════════════════════════════════

alter table kelurahan enable row level security;
alter table profil    enable row level security;
alter table lintasan  enable row level security;
alter table jejak     enable row level security;
alter table sesi      enable row level security;

-- ── Kelurahan: publik, tidak sensitif ───────────────────────────────
create policy "kelurahan dibaca semua"
  on kelurahan for select
  to authenticated
  using (true);

-- ── Profil ──────────────────────────────────────────────────────────
-- Nama dan kelurahan boleh dilihat sesama pengguna: tanpa itu, papan
-- kontribusi tim tidak bisa menampilkan siapa pun. Profil sendiri tidak
-- mengandung apa pun yang berbahaya — tidak ada lokasi, tidak ada jadwal.
create policy "profil dibaca semua"
  on profil for select
  to authenticated
  using (true);

create policy "profil hanya diubah pemiliknya"
  on profil for all
  to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- ── Lintasan: TIDAK BISA dibaca orang lain ──────────────────────────
-- Ini kunci seluruh model privasi. Kumpulan lintasan seseorang adalah
-- peta hidupnya.
create policy "lintasan hanya dibaca pemiliknya"
  on lintasan for select
  to authenticated
  using (profil_id = (select auth.uid()));

create policy "lintasan hanya ditulis pemiliknya"
  on lintasan for insert
  to authenticated
  with check (profil_id = (select auth.uid()));

create policy "lintasan hanya diperbarui pemiliknya"
  on lintasan for update
  to authenticated
  using (profil_id = (select auth.uid()))
  with check (profil_id = (select auth.uid()));

-- ── Jejak: milik pribadi, mutlak ────────────────────────────────────
create policy "jejak mutlak milik pemiliknya"
  on jejak for all
  to authenticated
  using (profil_id = (select auth.uid()))
  with check (profil_id = (select auth.uid()));

-- ── Sesi: milik pribadi ─────────────────────────────────────────────
-- Termasuk jarak_meter. Jarak tidak pernah dipakai untuk peringkat
-- apa pun, dan tidak pernah keluar dari pemiliknya.
create policy "sesi mutlak milik pemiliknya"
  on sesi for all
  to authenticated
  using (profil_id = (select auth.uid()))
  with check (profil_id = (select auth.uid()));

-- ════════════════════════════════════════════════════════════════════
-- Jalur baca yang terkendali
-- ════════════════════════════════════════════════════════════════════

-- Siapa saja yang sudah melewati sebuah petak.
--
-- ATURAN LINGKUP: pemanggil hanya boleh melihat detail petak yang
-- dirinya sendiri sudah pernah lewati. Ini menutup panen borongan —
-- untuk memetakan pergerakan seseorang, penyerang harus lebih dulu
-- benar-benar berjalan kaki melewati setiap petak yang ingin diintipnya.
--
-- Yang dikembalikan hanya nama dan waktu kasar. Tidak ada koordinat,
-- tidak ada kecepatan, tidak ada rute.
create or replace function petak_detail(p_petak_kode text)
returns table (
  profil_id    uuid,
  nama         text,
  kelurahan_id text,
  waktu_pertama timestamptz
)
language sql
security definer
set search_path = public
stable
as $$
  select l.profil_id, p.nama, l.kelurahan_id, l.waktu_pertama
  from lintasan l
  join profil p on p.id = l.profil_id
  where l.petak_kode = p_petak_kode
    and l.waktu_terakhir > now() - interval '7 days'
    and exists (
      select 1 from lintasan milik
      where milik.petak_kode = p_petak_kode
        and milik.profil_id = auth.uid()
    )
  order by l.waktu_pertama;
$$;

-- Mencatat bahwa pemanggil melewati sekumpulan petak.
--
-- Upsert: melintas berulang kali hanya memperbarui waktu_terakhir, tidak
-- pernah menambah hitungan orang. Aturan "3 orang BERBEDA" ditegakkan
-- oleh bentuk tabelnya sendiri, bukan oleh logika yang bisa lupa dipanggil.
create or replace function catat_lintasan(p_petak_kode text[])
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_kelurahan text;
begin
  select kelurahan_id into v_kelurahan from profil where id = auth.uid();
  if v_kelurahan is null then
    raise exception 'Profil belum ada';
  end if;

  insert into lintasan (petak_kode, profil_id, kelurahan_id)
  select unnest(p_petak_kode), auth.uid(), v_kelurahan
  on conflict (petak_kode, profil_id)
  do update set waktu_terakhir = now();
end;
$$;

-- Pemilik banyak petak sekaligus — untuk mewarnai peta.
--
-- Hanya data agregat: kode petak dan kelurahan pemenangnya. Tidak ada
-- nama, jadi aman dibaca luas.
create or replace function pemilik_petak(p_petak_kode text[])
returns table (petak_kode text, kelurahan_id text, jumlah_pelintas int)
language sql
security definer
set search_path = public
stable
as $$
  select pp.petak_kode, pp.kelurahan_id, pp.jumlah_pelintas
  from petak_pemilik pp
  where pp.petak_kode = any(p_petak_kode);
$$;

revoke all on function petak_detail(text)    from public, anon;
revoke all on function catat_lintasan(text[]) from public, anon;
revoke all on function pemilik_petak(text[])  from public, anon;

grant execute on function petak_detail(text)     to authenticated;
grant execute on function catat_lintasan(text[]) to authenticated;
grant execute on function pemilik_petak(text[])  to authenticated;

-- CATATAN OPERASIONAL: fungsi-fungsi di atas tetap perlu pembatasan laju
-- di tingkat gateway. RLS mencegah panen borongan, bukan permintaan
-- bertubi-tubi.
