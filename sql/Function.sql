SHOW FUNCTION STATUS WHERE Db = 'sulthan_feast';


DELIMITER //
CREATE FUNCTION fn_cek_ketersediaan_ruangan(
    p_id_ruangan INT,
    p_tanggal DATE,
    p_jam TIME
)
RETURNS BOOLEAN
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_jumlah INT;

    SELECT COUNT(*) INTO v_jumlah
    FROM reservasi
    WHERE id_ruangan = p_id_ruangan
      AND tanggal = p_tanggal
      AND jam = p_jam
      AND status_reservasi != 'cancelled';

    IF v_jumlah = 0 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END 
DELIMITER ;

SELECT fn_cek_ketersediaan_ruangan(1, '2026-12-25', '19:00:00'); -- TRUE kalau belum ada yang booking slot


DELIMITER //
CREATE FUNCTION fn_cek_waktu_valid(
    p_tanggal DATE,
    p_jam TIME
)
RETURNS BOOLEAN
NOT DETERMINISTIC
NO SQL
BEGIN
    DECLARE v_valid BOOLEAN;

    IF TIMESTAMP(p_tanggal, p_jam) > NOW() THEN
        SET v_valid = TRUE;
    ELSE
        SET v_valid = FALSE;
    END IF;

    RETURN v_valid;
END 
DELIMITER ;

SELECT fn_cek_waktu_valid('2026-12-25', '19:00:00');  
SELECT fn_cek_waktu_valid('2026-01-01', '10:00:00');  



DELIMITER //
CREATE FUNCTION fn_hitung_margin_menu(
    p_harga_pokok_penjualan FLOAT,
    p_harga_jual FLOAT
)
RETURNS FLOAT
DETERMINISTIC
NO SQL
BEGIN
    IF p_harga_jual = 0 THEN
        RETURN 0;
    END IF;

    RETURN ROUND(((p_harga_jual - p_harga_pokok_penjualan) / p_harga_jual) * 100, 2);
END 
DELIMITER ;

SELECT fn_hitung_margin_menu(25000, 35000); 



DELIMITER //
CREATE FUNCTION fn_validasi_format_no_wa(
    p_no_wa VARCHAR(20)
)
RETURNS BOOLEAN
DETERMINISTIC
NO SQL
BEGIN
    RETURN COALESCE(p_no_wa REGEXP '^08[0-9]{8,11}$', FALSE);
END 
DELIMITER ;

SELECT fn_validasi_format_no_wa('081234567890');   
SELECT fn_validasi_format_no_wa('+6281234567890'); 
SELECT fn_validasi_format_no_wa('6281234567890');  


DELIMITER //
CREATE FUNCTION fn_validasi_harga_menu(
	p_harga_pokok_penjualan FLOAT,
	p_harga_jual FLOAT
)
RETURNS BOOLEAN
DETERMINISTIC
NO SQL
BEGIN
	RETURN COALESCE(p_harga_pokok_penjualan >= 0 AND p_harga_jual > p_harga_pokok_penjualan, FALSE);
END
DELIMITER ;

SELECT fn_validasi_harga_menu(2000, 4000)



DELIMITER //
CREATE FUNCTION fn_validasi_jumlah_orang(
    p_jumlah_orang INT
)
RETURNS BOOLEAN
DETERMINISTIC
NO SQL
BEGIN
    RETURN p_jumlah_orang IS NOT NULL AND p_jumlah_orang > 0;
END
DELIMITER ;
SELECT fn_validasi_jumlah_orang(4);         -- 1
SELECT fn_validasi_jumlah_orang(0);         -- 0
SELECT fn_validasi_jumlah_orang(-2);        -- 0



DELIMITER //
CREATE FUNCTION fn_validasi_nama_kategori(
    p_kategori VARCHAR(100)
)
RETURNS BOOLEAN
DETERMINISTIC
NO SQL
BEGIN
    RETURN p_kategori IS NOT NULL AND TRIM(p_kategori) <> '';
END
DELIMITER;


DELIMITER //
CREATE FUNCTION fn_validasi_nama_menu(
    p_nama VARCHAR(100)
)
RETURNS BOOLEAN
DETERMINISTIC
NO SQL
BEGIN
    RETURN p_nama IS NOT NULL AND TRIM(p_nama) <> '';
END
DELIMITER ;

SELECT fn_validasi_nama_menu('Nasi Goreng');   -- hasil: 1 (TRUE)



DELIMITER //
CREATE FUNCTION fn_validasi_nama_ruangan(
    p_ruangan VARCHAR(100)
)
RETURNS BOOLEAN
DETERMINISTIC
NO SQL
BEGIN
    RETURN p_ruangan IS NOT NULL AND TRIM(p_ruangan) <> '';
END
DELIMITER ;
SELECT fn_validasi_nama_ruangan('')


DELIMITER //
CREATE FUNCTION fn_validasi_nama_customer(
    p_nama VARCHAR(100)
)
RETURNS BOOLEAN
DETERMINISTIC
NO SQL
BEGIN
    RETURN p_nama IS NOT NULL AND TRIM(p_nama) <> '';
END
DELIMITER ;

SELECT fn_validasi_nama_customer('Budi');  
SELECT fn_validasi_nama_customer('');    


DELIMITER //
CREATE FUNCTION fn_validasi_status_reservasi(
    p_status VARCHAR(20)
)
RETURNS BOOLEAN
DETERMINISTIC
NO SQL
BEGIN
    RETURN COALESCE(p_status IN ('pending', 'confirmed', 'cancelled'), FALSE);
END
DELIMITER ;


DELIMITER //
CREATE FUNCTION fn_validasi_keyword_menu(
    p_keyword VARCHAR(100)
)
RETURNS BOOLEAN
DETERMINISTIC
NO SQL
BEGIN
    RETURN p_keyword IS NOT NULL AND TRIM(p_keyword) <> '';
END 
DELIMITER ;



DELIMITER //
CREATE FUNCTION fn_validasi_username(p_username VARCHAR(100))
RETURNS BOOLEAN
DETERMINISTIC
NO SQL
BEGIN
    RETURN COALESCE(p_username IS NOT NULL AND TRIM(p_username) <> '', FALSE);
END
DELIMITER ;

DELIMITER //
CREATE FUNCTION fn_validasi_password_hash(p_hash VARCHAR(255))
RETURNS BOOLEAN
DETERMINISTIC
NO SQL
BEGIN
    -- Format bcrypt: $2b$12$ + 53 karakter = 60 karakter
    RETURN COALESCE(p_hash REGEXP '^\\$2[aby]\\$[0-9]{2}\\$.{53}$', FALSE);
END 
DELIMITER ;


SHOW FUNCTION STATUS WHERE Db = 'sulthan_feast';


