-- Kelurahan awal. Produksi mengisinya dari batas administratif asli
-- (mis. data BPS), dengan warna dibagikan supaya kelurahan bertetangga
-- tidak pernah berwarna sama.
insert into kelurahan (id, nama, warna) values
  ('tebet',     'Tebet',     'biru'),
  ('menteng',   'Menteng',   'merah'),
  ('kuningan',  'Kuningan',  'hijau'),
  ('senayan',   'Senayan',   'ungu')
on conflict (id) do nothing;
