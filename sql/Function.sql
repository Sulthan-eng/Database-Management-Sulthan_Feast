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
END //
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


SHOW FUNCTION STATUS WHERE Db = 'sulthan_feast';

