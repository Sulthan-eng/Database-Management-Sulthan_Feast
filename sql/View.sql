CREATE VIEW v_menu_customer AS
SELECT m.id_menu, m.nama, m.deskripsi, m.harga_jual, m.id_kategori, 
		km.kategori AS nama_kategori
FROM menu m
JOIN kategori_menu km ON m.id_kategori = km.id_kategori;



CREATE VIEW v_menu_admin AS	
SELECT m.id_menu, m.nama, m.deskripsi, m.harga_pokok_penjualan, m.harga_jual, fn_hitung_margin_menu(m.harga_pokok_penjualan, m.harga_jual) AS margin_persen, m.id_kategori, 
		km.kategori AS nama_kategori
FROM menu m
JOIN kategori_menu km ON m.id_kategori = km.id_kategori;


CREATE VIEW v_lihat_reservasi AS
SELECT re.id_reservasi,
       c.id_customer, 
       re.nama_pemesan,
       c.nama AS nama_customer,
       c.no_WA,
       re.waktu_reservasi,
       re.waktu_selesai,
       re.jumlah_orang,
       re.status_reservasi,
	   ru.ruangan AS nama_ruangan,
       JSON_UNQUOTE(JSON_EXTRACT(re.catatan, '$.acara')) AS acara,
	   re.catatan
FROM reservasi re
JOIN customer c ON re.id_customer = c.id_customer
JOIN ruangan ru ON re.id_ruangan = ru.id_ruangan
ORDER BY re.waktu_reservasi DESC, re.id_reservasi DESC;



CREATE VIEW v_lihat_reservasi_aktif AS 
SELECT re.id_reservasi,
       c.id_customer,
       re.nama_pemesan,
       c.nama AS nama_customer,
       c.no_WA,
       re.waktu_reservasi,
       re.waktu_selesai,
       re.jumlah_orang,
       re.status_reservasi,
       ru.ruangan AS nama_ruangan,
       JSON_UNQUOTE(JSON_EXTRACT(re.catatan, '$.acara')) AS acara,
       re.catatan
FROM reservasi re
JOIN customer c ON re.id_customer = c.id_customer
JOIN ruangan ru ON re.id_ruangan = ru.id_ruangan
WHERE re.status_reservasi = 'berlangsung'
   OR (re.status_reservasi IN ('pending','confirmed')
       AND re.waktu_selesai > NOW())
ORDER BY re.waktu_reservasi, re.id_reservasi;


CREATE VIEW v_lihat_user AS 
SELECT id_user, username
FROM user_sistem;


CREATE VIEW v_lihat_kategori_menu AS 
SELECT id_kategori, kategori
FROM kategori_menu;


CREATE VIEW v_lihat_ruangan AS 
SELECT id_ruangan, ruangan, deskripsi, status_ruangan
FROM ruangan;

CREATE VIEW v_login_user AS 
SELECT id_user, username, password AS password_hash
FROM user_sistem;


CREATE VIEW v_lihat_jadwal_ruangan AS
SELECT ru.id_ruangan, ru.ruangan AS nama_ruangan, re.waktu_reservasi, re.waktu_selesai
FROM reservasi re
JOIN ruangan ru ON ru.id_ruangan = re.id_ruangan
WHERE re.status_reservasi <> 'cancelled'
  AND re.waktu_selesai > NOW();



CREATE VIEW v_lihat_log_status_reservasi AS
SELECT id_log, id_reservasi, nama_pemesan, status_reservasi, waktu
FROM log_status_reservasi;

