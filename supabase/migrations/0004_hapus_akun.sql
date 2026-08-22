-- ════════════════════════════════════════════════════════════════════
-- Rukun — hapus akun
--
-- App Store Review Guideline §5.1.1(v) mewajibkan setiap aplikasi yang
-- menawarkan pembuatan akun menyediakan jalur MENGHAPUS akun itu **dari
-- dalam aplikasi** — bukan lewat email, bukan lewat formulir web.
-- Menonaktifkan tidak dihitung; datanya harus benar-benar hilang.
--
-- Rukun mengambil sikap yang sama untuk alasannya sendiri: aplikasi ini
-- meminta izin lokasi setiap hari. Kepercayaan sebesar itu hanya masuk
-- akal kalau pintu keluarnya selebar pintu masuk.
-- ════════════════════════════════════════════════════════════════════

create or replace function hapus_akun()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid      uuid := auth.uid();
  v_terhapus int;
begin
  if v_uid is null then
    raise exception 'Belum masuk';
  end if;

  -- Foreign key sudah memakai `on delete cascade`, jadi menghapus baris
  -- auth.users saja sebenarnya cukup. Penghapusan di bawah ditulis tetap
  -- eksplisit supaya berkas ini bisa dibaca sebagai daftar lengkap "apa
  -- yang Rukun simpan tentang seseorang" — dan supaya ia tetap benar
  -- kalau suatu saat ada tabel yang lupa memasang cascade.
  delete from jejak    where profil_id = v_uid;
  delete from lintasan where profil_id = v_uid;
  delete from sesi     where profil_id = v_uid;
  delete from profil   where id = v_uid;

  -- Terakhir: identitasnya sendiri. Setelah baris ini, tidak ada satu pun
  -- baris di server yang bisa dihubungkan kembali ke orang tersebut.
  --
  -- Hasilnya DIPERIKSA, tidak diasumsikan. `auth.users` dimiliki
  -- `supabase_auth_admin`, dan hak peran pemilik fungsi ini atasnya datang
  -- dari skrip penyiapan Supabase — bukan sesuatu yang dijamin skema ini.
  -- Kalau RLS di `auth.users` menyaring baris itu, DELETE tidak melempar
  -- error, ia hanya mengenai NOL baris. Tanpa pemeriksaan ini transaksinya
  -- commit dengan tenang: seluruh data pengguna lenyap, identitasnya tetap
  -- hidup, dan orang itu masih bisa masuk ke akun yang katanya sudah
  -- dihapus — kegagalan paling buruk yang mungkin terjadi di sini.
  --
  -- Dengan `raise`, transaksinya rollback: datanya utuh kembali dan
  -- aplikasi menampilkan kegagalan yang jujur.
  delete from auth.users where id = v_uid;
  get diagnostics v_terhapus = row_count;

  if v_terhapus <> 1 then
    raise exception
      'Identitas gagal dihapus (% baris). Tidak ada yang diubah.', v_terhapus;
  end if;
end;
$$;

revoke all on function hapus_akun() from public, anon;
grant execute on function hapus_akun() to authenticated;

-- CATATAN: zona privat (radius buta rumah) tidak muncul di sini karena ia
-- memang tidak pernah dikirim ke server. Ia hidup di perangkat saja, dan
-- dihapus lewat "Hapus data di HP ini" di tab Aku.
