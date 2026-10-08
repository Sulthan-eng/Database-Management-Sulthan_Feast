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

