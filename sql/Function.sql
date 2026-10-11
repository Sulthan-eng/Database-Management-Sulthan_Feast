SHOW FUNCTION STATUS WHERE Db = 'sulthan_feast';


DELIMITER //
CREATE FUNCTION fn_cek_ketersediaan_ruangan(
    p_id_ruangan INT,
    p_mulai DATETIME,
    p_selesai DATETIME
)
RETURNS BOOLEAN
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    RETURN NOT EXISTS (
        SELECT 1 FROM reservasi
        WHERE id_ruangan = p_id_ruangan
          AND status_reservasi <> 'cancelled'
          AND waktu_reservasi < p_selesai
          AND waktu_selesai > p_mulai
    );
END 
DELIMITER ;

SELECT fn_cek_ketersediaan_ruangan(1, '2026-12-25 19:00:00', '2026-12-25 21:00:00'); -- TRUE kalau belum ada yang booking slot


DELIMITER //
CREATE FUNCTION fn_hitung_margin_menu(
    p_harga_pokok_penjualan DECIMAL(12,2),
    p_harga_jual DECIMAL(12,2)
)
RETURNS DECIMAL(9,2)
DETERMINISTIC
NO SQL
BEGIN
    RETURN ROUND(((p_harga_jual - p_harga_pokok_penjualan) / p_harga_jual) * 100, 2);
END //
DELIMITER ;

SELECT fn_hitung_margin_menu(25000, 35000); 


DELIMITER //
CREATE FUNCTION fn_hitung_waktu_selesai(
    p_waktu_mulai DATETIME,
    p_durasi_menit INT
)
RETURNS DATETIME
DETERMINISTIC
NO SQL
BEGIN
    RETURN p_waktu_mulai + INTERVAL p_durasi_menit MINUTE;
END //
DELIMITER ;

SELECT fn_hitung_waktu_selesai('2026-12-20 23:00:00', 180); -- 2026-12-21 02:00:00


SHOW FUNCTION STATUS WHERE Db = 'sulthan_feast';


