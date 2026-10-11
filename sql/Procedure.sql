SHOW PROCEDURE STATUS WHERE Db = 'sulthan_feast';


DELIMITER //
CREATE PROCEDURE sp_tambah_kategori_menu(
	IN p_kategori VARCHAR(100)
)
SQL SECURITY DEFINER
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        INSERT INTO kategori_menu(kategori)
        VALUES (NULLIF(TRIM(p_kategori), ''));
    COMMIT;
END //
DELIMITER ;


CALL sp_tambah_kategori_menu(' ')



DELIMITER //
CREATE PROCEDURE sp_ubah_kategori_menu(
	IN p_id_kategori INT,
	IN p_kategori VARCHAR(100)
)
SQL SECURITY DEFINER
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    UPDATE kategori_menu
    SET kategori = NULLIF(TRIM(p_kategori), '')
    WHERE id_kategori = p_id_kategori;

    IF ROW_COUNT() = 0 THEN
        -- Baris yg mau diubah tidak ada ATAU nilainya memang sama dgn yg lama?
        IF NOT EXISTS (SELECT 1 FROM kategori_menu
                       WHERE id_kategori = p_id_kategori) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Kategori tidak ditemukan';
        END IF;
    END IF;

    COMMIT;
END //
DELIMITER ;


CALL sp_ubah_kategori_menu(1, 'Appetizer')



DELIMITER //
CREATE PROCEDURE sp_hapus_kategori_menu(
    IN p_id_kategori INT,
    IN p_hapus_menu BOOLEAN
)
SQL SECURITY DEFINER
BEGIN
    DECLARE v_dipakai INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_dipakai
    FROM menu
    WHERE id_kategori = p_id_kategori;

    IF v_dipakai > 0 THEN
        IF COALESCE(p_hapus_menu, FALSE) THEN
            DELETE FROM menu WHERE id_kategori = p_id_kategori;
        ELSE
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Kategori masih dipakai oleh menu. Hapus menunya dulu atau gunakan opsi hapus beserta menu';
        END IF;
    END IF;

    DELETE FROM kategori_menu
    WHERE id_kategori = p_id_kategori;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Kategori tidak ditemukan';
    END IF;

    COMMIT;
END //
DELIMITER ;

CALL sp_hapus_kategori_menu(7, FALSE)



DELIMITER //
CREATE PROCEDURE sp_lihat_kategori_menu()
SQL SECURITY DEFINER
READS SQL DATA
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
	
    START TRANSACTION READ ONLY;
        SELECT * FROM v_lihat_kategori_menu
    COMMIT;
END // 
DELIMITER ;

CALL sp_lihat_kategori_menu()



DELIMITER //
CREATE PROCEDURE sp_tambah_ruangan(
	IN p_ruangan VARCHAR(100),
	IN p_deskripsi VARCHAR(255)
)
SQL SECURITY DEFINER
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        INSERT INTO ruangan(ruangan, deskripsi)
        VALUES (NULLIF(TRIM(p_ruangan), ''), p_deskripsi);
    COMMIT;
END //
DELIMITER ;


CALL sp_tambah_ruangan('Santai Room','Ruangan khusus untuk bersantai.')



DELIMITER //
CREATE PROCEDURE sp_ubah_ruangan(
    IN p_id_ruangan INT,
    IN p_ruangan VARCHAR(100),
    IN p_deskripsi VARCHAR(255),
    IN p_status_ruangan VARCHAR(20)
)
SQL SECURITY DEFINER
BEGIN
    DECLARE v_status_lama VARCHAR(20) DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_status_ruangan IS NULL
       OR p_status_ruangan NOT IN ('Tersedia','Sedang Dipakai','Pemeliharaan','Nonaktif') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Status ruangan tidak valid';
    END IF;

    START TRANSACTION;

    SELECT status_ruangan INTO v_status_lama
    FROM ruangan
    WHERE id_ruangan = p_id_ruangan
    FOR UPDATE;

    IF v_status_lama IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ruangan tidak ditemukan';
    END IF;

    IF p_status_ruangan <> v_status_lama THEN
        IF p_status_ruangan = 'Sedang Dipakai' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Status Sedang Dipakai diatur otomatis oleh reservasi';
        END IF;

        IF v_status_lama = 'Sedang Dipakai' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Ruangan sedang dipakai, selesaikan reservasinya dulu';
        END IF;

        IF p_status_ruangan IN ('Pemeliharaan','Nonaktif')
           AND EXISTS (SELECT 1 FROM reservasi
                       WHERE id_ruangan = p_id_ruangan
                         AND status_reservasi IN ('pending','confirmed','berlangsung')
                         AND waktu_selesai > NOW()) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Ruangan masih memiliki reservasi aktif';
        END IF;
    END IF;

    UPDATE ruangan
    SET ruangan        = NULLIF(TRIM(p_ruangan), ''),
        deskripsi      = p_deskripsi,
        status_ruangan = p_status_ruangan
    WHERE id_ruangan = p_id_ruangan;

    COMMIT;
END //
DELIMITER ;

CALL sp_ubah_ruangan(6, 'Chill Room', 'Ruangan untuk menghabiskan waktu bersama orang orang spesial.', 'Pemeliharaan')



DELIMITER //
CREATE PROCEDURE sp_hapus_ruangan(
    IN p_id_ruangan INT
)
SQL SECURITY DEFINER
BEGIN
    DECLARE v_id INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT id_ruangan INTO v_id
    FROM ruangan
    WHERE id_ruangan = p_id_ruangan
    FOR UPDATE;

    IF v_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ruangan tidak ditemukan';
    END IF;

    IF EXISTS (SELECT 1 FROM reservasi WHERE id_ruangan = p_id_ruangan) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ruangan memiliki riwayat reservasi dan tidak bisa dihapus. Ubah statusnya menjadi Nonaktif';
    END IF;

    DELETE FROM ruangan
    WHERE id_ruangan = p_id_ruangan;

    COMMIT;
END //
DELIMITER ;	

CALL sp_hapus_ruangan(6)




DELIMITER //
CREATE PROCEDURE sp_lihat_ruangan()
SQL SECURITY DEFINER
READS SQL DATA
BEGIN 
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
	
	START TRANSACTION READ ONLY;
		SELECT * FROM v_lihat_ruangan
	COMMIT;
END //
DELIMITER ;


CALL sp_lihat_ruangan();


-- antara hapus atau ubah biar dia kembalikan kapan aja ruangan itu direservasi
DELIMITER //
CREATE PROCEDURE sp_lihat_jadwal_ruangan(
    IN p_id_ruangan INT
)
READS SQL DATA
SQL SECURITY DEFINER
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION READ ONLY;

    IF p_id_ruangan IS NULL THEN
        SELECT * FROM v_lihat_jadwal_ruangan
        ORDER BY nama_ruangan, waktu_reservasi;
    ELSE
        SELECT * FROM v_lihat_jadwal_ruangan
        WHERE id_ruangan = p_id_ruangan
        ORDER BY waktu_reservasi;
    END IF;

    COMMIT;
END //
DELIMITER ;
CALL sp_lihat_jadwal_ruangan(NULL);
CALL sp_lihat_jadwal_ruangan(4);
CALL sp_lihat_jadwal_ruangan(9999);   


DELIMITER //
CREATE PROCEDURE sp_tambah_menu(
	IN p_nama VARCHAR(100),
	IN p_id_kategori INT,
	IN p_deskripsi VARCHAR(255),
	IN p_harga_pokok_penjualan DECIMAL(12,2),
	IN p_harga_jual DECIMAL(12,2)
)
SQL SECURITY DEFINER
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        INSERT INTO menu(nama, id_kategori, deskripsi, harga_pokok_penjualan, harga_jual)
        VALUES (NULLIF(TRIM(p_nama), ''), p_id_kategori, p_deskripsi, p_harga_pokok_penjualan, p_harga_jual);
    COMMIT;
END //
DELIMITER ;

CALL sp_tambah_menu('Kopi', 6, 'Kopi bikin ga tidur', 5000, 8000)



DELIMITER //
CREATE PROCEDURE sp_ubah_menu(
	IN p_id_menu INT,
	IN p_nama VARCHAR(100),
	IN p_id_kategori INT,
	IN p_deskripsi VARCHAR(255),
	IN p_harga_pokok_penjualan DECIMAL(12,2),
	IN p_harga_jual DECIMAL(12,2)
)
SQL SECURITY DEFINER
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    UPDATE menu
    SET nama = NULLIF(TRIM(p_nama), ''),
        id_kategori = p_id_kategori,
        deskripsi = p_deskripsi,
        harga_pokok_penjualan = p_harga_pokok_penjualan,
        harga_jual = p_harga_jual
    WHERE id_menu = p_id_menu;

    IF ROW_COUNT() = 0 THEN
        -- bisa berarti: baris tidak ada ATAU nilainya memang sama
        IF NOT EXISTS (SELECT 1 FROM menu WHERE id_menu = p_id_menu) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Menu tidak ditemukan';
        END IF;
    END IF;

    COMMIT;
END //
DELIMITER ;

CALL sp_ubah_menu(1, 'Kebab Sapi', 1, 'Daging sapi berbumbu khas Timur Tengah, disajikan dengan roti tortilla, sayuran segar, dan saus yoghurt.', 25000, 35000);
CALL sp_ubah_menu(1, 'Kebab Sapi', 1, 'Daging sapi berbumbu khas Timur Tengah, disajikan dengan roti tortilla, sayuran segar, dan saus yoghurt.', 25000, 35000);
CALL sp_ubah_menu(1, 'X', 1, NULL, 14000, 10000); 


DELIMITER //
CREATE PROCEDURE sp_hapus_menu(
	IN p_id_menu INT
)
SQL SECURITY DEFINER
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    DELETE FROM menu
    WHERE id_menu = p_id_menu;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Menu tidak ditemukan';
    END IF;

    COMMIT;
END //
DELIMITER ;

CALL sp_hapus_menu(5);


DELIMITER //
CREATE PROCEDURE sp_lihat_menu_customer()
SQL SECURITY DEFINER
READS SQL DATA
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
	
	START TRANSACTION READ ONLY;
    	SELECT * FROM v_menu_customer;
	COMMIT;
END //
DELIMITER ; 

CALL sp_lihat_menu_customer


DELIMITER //
CREATE PROCEDURE sp_lihat_menu_admin()
SQL SECURITY DEFINER
READS SQL DATA
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
	
    START TRANSACTION READ ONLY;
    	SELECT * FROM v_menu_admin;
	COMMIT;
END //
DELIMITER ;

CALL sp_lihat_menu_admin



DELIMITER //
CREATE PROCEDURE sp_buat_reservasi(
    IN p_nama VARCHAR(100),
    IN p_no_wa VARCHAR(20),
    IN p_waktu_reservasi DATETIME,
    IN p_waktu_selesai DATETIME,
    IN p_jumlah_orang INT,
    IN p_id_ruangan INT,
    IN p_catatan JSON
)
SQL SECURITY DEFINER
BEGIN
    DECLARE v_status_ruangan VARCHAR(20) DEFAULT NULL;
    DECLARE v_id_customer INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

 	IF p_waktu_reservasi IS NULL OR p_waktu_reservasi <= NOW() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Waktu reservasi harus di masa depan';
    END IF;

	IF p_waktu_selesai IS NULL OR p_waktu_selesai <= p_waktu_reservasi THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Waktu selesai harus setelah waktu mulai';
    END IF;

    START TRANSACTION;

    -- Kunci baris ruangan supaya dua request untuk ruangan yang sama
    -- diproses bergantian, bukan bersamaan
    SELECT status_ruangan INTO v_status_ruangan
    FROM ruangan
    WHERE id_ruangan = p_id_ruangan
    FOR UPDATE;

    IF v_status_ruangan IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ruangan tidak ditemukan';
    END IF;

    -- Cek ketersediaan setelah lock didapat
    IF v_status_ruangan IN ('Pemeliharaan', 'Nonaktif') THEN
    	SIGNAL SQLSTATE '45000'
    		SET MESSAGE_TEXT = 'Ruangan tidak dapat dipesan';
    END IF;
    
    IF NOT fn_cek_ketersediaan_ruangan(p_id_ruangan, p_waktu_reservasi, p_waktu_selesai) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ruangan sudah direservasi pada waktu tersebut';
    END IF;

    -- update insert customer liat no_WA
    INSERT INTO customer(nama, no_WA)
    VALUES (NULLIF(TRIM(p_nama), ''), p_no_wa) AS baru
    ON DUPLICATE KEY UPDATE 
    	id_customer = LAST_INSERT_ID(customer.id_customer),
    	nama        = baru.nama;

    SET v_id_customer = LAST_INSERT_ID();

    
    INSERT INTO reservasi (nama_pemesan, waktu_reservasi, waktu_selesai, jumlah_orang, 
    		catatan, id_ruangan, id_customer)
    VALUES (NULLIF(TRIM(p_nama), ''), p_waktu_reservasi, p_waktu_selesai, p_jumlah_orang,
            p_catatan, p_id_ruangan, v_id_customer);
    COMMIT;
END //
DELIMITER ;


-- sukses
CALL sp_buat_reservasi('Tester', '081200000002', '2026-12-30 19:00:00', '2026-12-30 21:00:00', 2, 4, '{"alergi": "benang sari"}');
-- ditolak: selesai sebelum mulai
CALL sp_buat_reservasi('Tester', '081200000002', '2026-12-30 19:00:00', '2026-12-30 18:00:00', 2, 4, NULL);
-- ditolak: bentrok dengan reservasi tadi
CALL sp_buat_reservasi('Tester', '081200000002', '2026-12-30 20:00:00', '2026-12-30 22:00:00', 2, 4, NULL);



DELIMITER //
CREATE PROCEDURE sp_lihat_reservasi()
SQL SECURITY DEFINER
READS SQL DATA
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION READ ONLY;
        SELECT * FROM v_lihat_reservasi
   COMMIT;
END //
DELIMITER ;

CALL sp_lihat_reservasi();


DELIMITER //
CREATE PROCEDURE sp_lihat_reservasi_aktif()
SQL SECURITY DEFINER
READS SQL DATA
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION READ ONLY;
        SELECT * FROM v_lihat_reservasi_aktif
   COMMIT;
END //
DELIMITER ;


CALL sp_lihat_reservasi_aktif();



DELIMITER //
CREATE PROCEDURE sp_ubah_status_reservasi(
    IN p_id_reservasi INT,
    IN p_status VARCHAR(20)
)
SQL SECURITY DEFINER
BEGIN
    DECLARE v_id_ruangan INT DEFAULT NULL;
    DECLARE v_status_ruangan VARCHAR(20) DEFAULT NULL;
    DECLARE v_status_lama VARCHAR(20) DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    SELECT id_ruangan INTO v_id_ruangan
    FROM reservasi
    WHERE id_reservasi = p_id_reservasi;
    
    IF v_id_ruangan IS NULL THEN
    	SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Reservasi tidak ditemukan';
    END IF;

    -- kunci ruangan for update
    SELECT status_ruangan INTO v_status_ruangan
    FROM ruangan
    WHERE id_ruangan = v_id_ruangan
    FOR UPDATE;
    
	--  kunci reservasi for update
    SELECT status_reservasi INTO v_status_lama
    FROM reservasi
    WHERE id_reservasi = p_id_reservasi
    FOR UPDATE;

    -- validasi transisi (COALESCE: NULL pada p_status jg ditolak)
    IF NOT COALESCE(
           (v_status_lama = 'pending'     AND p_status IN ('confirmed', 'cancelled'))
        OR (v_status_lama = 'confirmed'   AND p_status IN ('berlangsung', 'cancelled'))
        OR (v_status_lama = 'berlangsung' AND p_status = 'selesai'),
        FALSE) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Perubahan status tidak diizinkan';
    END IF;

    -- Tamu baru tak boleh msuk klo ruangan belum bebas
    IF p_status = 'berlangsung' AND v_status_ruangan <> 'Tersedia' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ruangan sedang tidak tersedia. Selesaikan reservasi sebelumnya atau periksa status ruangan';
    END IF;
    
    --     trg tbel log
    UPDATE reservasi
    SET status_reservasi = p_status
    WHERE id_reservasi = p_id_reservasi;

    COMMIT;
END //
DELIMITER ;


CALL sp_ubah_status_reservasi(1, 'confirmed');    -- sukses, log +1
CALL sp_ubah_status_reservasi(1, 'confirmed');    -- ditolak: status sama
CALL sp_ubah_status_reservasi(1, 'selesai');      -- ditolak: loncat status
CALL sp_ubah_status_reservasi(1, 'berlangsung');  -- sukses, ruangan jadi 'Sedang Dipakai'
CALL sp_ubah_status_reservasi(1, 'selesai');      -- sukses, ruangan kembali 'Tersedia'
CALL sp_ubah_status_reservasi(1, 'cancelled');    -- ditolak: selesai itu final
CALL sp_ubah_status_reservasi(1, NULL);           -- ditolak
CALL sp_ubah_status_reservasi(1, 'xyz');          -- ditolak
CALL sp_ubah_status_reservasi(999, 'confirmed');  -- "Reservasi tidak ditemukan"



DELIMITER //
CREATE PROCEDURE sp_cari_menu(
    IN p_keyword VARCHAR(100)
)
SQL SECURITY DEFINER
READS SQL DATA
BEGIN
	DECLARE v_keyword VARCHAR(100) DEFAULT NULL;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
	
	SET v_keyword = NULLIF(TRIM(p_keyword), '');
	
	IF v_keyword IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Kata kunci pencarian tidak boleh kosong';
    END IF;

    START TRANSACTION READ ONLY;
        SELECT * FROM v_menu_customer
        WHERE nama LIKE CONCAT(v_keyword, '%')
        ORDER BY nama;
    COMMIT;
END //
DELIMITER ;


CALL sp_cari_menu('k');
CALL sp_cari_menu('   ');     -- error
CALL sp_cari_menu('zzz');



-- Verif pw di api 
DELIMITER //
CREATE PROCEDURE sp_verifikasi_login(
    IN p_username VARCHAR(100)
)
READS SQL DATA
SQL SECURITY DEFINER
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
	
    START TRANSACTION READ ONLY;
    	SELECT * FROM v_login_user
    	WHERE username = p_username;
    COMMIT;
END //
DELIMITER ;

CALL sp_verifikasi_login('admint');     -- 1 baris: id_user, username, password_hash
CALL sp_verifikasi_login('tidakada');   -- kosong (bukan error, memang disengaja)
CALL sp_verifikasi_login('ADMIN1');     -- tetap 1 baris, karena collation _ci


DELIMITER //
CREATE PROCEDURE sp_tambah_user(
    IN p_username VARCHAR(100),
    IN p_password_hash VARCHAR(255)
)
SQL SECURITY DEFINER
BEGIN
    -- Username kembar (UNIQUE) diubah jadi pesan yang jelas, bebas race condition
    DECLARE EXIT HANDLER FOR 1062
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Username sudah dipakai';
    END;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO user_sistem (username, password)
    VALUES (NULLIF(TRIM(p_username), ''), p_password_hash);

    COMMIT;

    SELECT LAST_INSERT_ID() AS id_user;
END //
DELIMITER ;


CALL sp_tambah_user('admin1', '$2b$12$abcdefghijklmnopqrstuvABCDEFGHIJKLMNOPQRSTUVWXYZ01234');  -- sukses (hash dummy 60 karakter)
CALL sp_tambah_user('admin1', '$2b$12$abcdefghijklmnopqrstuvABCDEFGHIJKLMNOPQRSTUVWXYZ01234');  -- 'Username sudah dipakai'
CALL sp_tambah_user('  ', '$2b$12$abcdefghijklmnopqrstuvABCDEFGHIJKLMNOPQRSTUVWXYZ0123456');      -- 'Username tidak boleh kosong'
CALL sp_tambah_user('x', 'passwordmentah');  



DELIMITER //
CREATE PROCEDURE sp_hapus_user(
    IN p_id_user INT
)
SQL SECURITY DEFINER
BEGIN
    DECLARE v_total_admint INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_total_admint FROM user_sistem FOR UPDATE;
     
    DELETE FROM user_sistem
    WHERE id_user = p_id_user;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'User tidak ditemukan';
    END IF;

    IF v_total_admint <= 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Tidak boleh menghapus user terakhir';
    END IF;

    COMMIT;
END //
DELIMITER ;
CALL sp_hapus_user(6); 


DELIMITER //
CREATE PROCEDURE sp_lihat_user()
READS SQL DATA
SQL SECURITY DEFINER
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION READ ONLY;
    	SELECT * FROM v_lihat_user
    COMMIT;
END 
DELIMITER ;
CALL sp_lihat_user()



DELIMITER //
CREATE PROCEDURE sp_lihat_log_status_reservasi(
    IN p_id_reservasi INT
)
READS SQL DATA
SQL SECURITY DEFINER
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION READ ONLY;

    IF p_id_reservasi IS NULL THEN
        SELECT * FROM v_lihat_log_status_reservasi
        ORDER BY id_log DESC;
    ELSE
        SELECT * FROM v_lihat_log_status_reservasi
        WHERE id_reservasi = p_id_reservasi
        ORDER BY id_log DESC;
    END IF;

    COMMIT;
END //
DELIMITER ;

CALL sp_lihat_log_status_reservasi(1);          -- riwayat reservasi 1
CALL sp_lihat_log_status_reservasi(NULL);       -- semua log
CALL sp_lihat_log_status_reservasi(9999);       -- kosong, bukan error



SHOW PROCEDURE STATUS WHERE Db = 'sulthan_feast';

