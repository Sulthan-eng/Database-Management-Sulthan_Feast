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

    IF NOT fn_validasi_nama_kategori(p_kategori) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nama kategori tidak boleh kosong';
    END IF;

    START TRANSACTION;
        INSERT INTO kategori_menu(kategori)
        VALUES (TRIM(p_kategori));
    COMMIT;
END
DELIMITER ;


CALL sp_tambah_kategori_menu('Main Course')



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

    IF NOT fn_validasi_nama_kategori(p_kategori) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nama kategori tidak boleh kosong';
    END IF;

    START TRANSACTION;

    UPDATE kategori_menu
    SET kategori = TRIM(p_kategori)
    WHERE id_kategori = p_id_kategori;

    IF ROW_COUNT() = 0 THEN
        -- Baris tidak ada ATAU nilainya memang sama?
        IF NOT EXISTS (SELECT 1 FROM kategori_menu
                       WHERE id_kategori = p_id_kategori) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Kategori tidak ditemukan';
        END IF;
    END IF;

    COMMIT;
END
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

CALL sp_hapus_kategori_menu(2)



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
        SELECT id_kategori, kategori
        FROM kategori_menu
        ORDER BY id_kategori;
    COMMIT;
END  
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

    IF NOT fn_validasi_nama_ruangan(p_ruangan) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nama ruangan tidak boleh kosong';
    END IF;

    START TRANSACTION;
        INSERT INTO ruangan(ruangan, deskripsi)
        VALUES (TRIM(p_ruangan), p_deskripsi);
    COMMIT;
END
DELIMITER ;

CALL sp_tambah_ruangan('Meeting Room', 
'Ruangan khusus untuk rapat bersama dengan atasan atau rekan kerja anda.')



DELIMITER //
CREATE PROCEDURE sp_ubah_ruangan(
	IN p_id_ruangan INT,
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

    IF NOT fn_validasi_nama_ruangan(p_ruangan) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nama ruangan tidak boleh kosong';
    END IF;

    START TRANSACTION;

    UPDATE ruangan
    SET ruangan = TRIM(p_ruangan), deskripsi = p_deskripsi
    WHERE id_ruangan = p_id_ruangan;

    IF ROW_COUNT() = 0 THEN
        -- Baris tidak ada ATAU nilainya memang sama?
        IF NOT EXISTS (SELECT 1 FROM ruangan
                       WHERE id_ruangan = p_id_ruangan) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Ruangan tidak ditemukan';
        END IF;
    END IF;

    COMMIT;
END
DELIMITER ;

CALL sp_ubah_ruangan(2, 'VIP Room', 'Ruangan untuk menghabiskan waktu bersama keluarga.')


DELIMITER //
CREATE PROCEDURE sp_hapus_ruangan(
	IN p_id_ruangan INT
)
SQL SECURITY DEFINER
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- trigger BEFORE DELETE kerja dlu
    DELETE FROM ruangan
    WHERE id_ruangan = p_id_ruangan;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ruangan tidak ditemukan';
    END IF;

    COMMIT;
END
DELIMITER ;

CALL sp_hapus_ruangan(2)



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
		SELECT id_ruangan, ruangan, deskripsi
		FROM ruangan
		ORDER BY id_ruangan;
	COMMIT;
END 
DELIMITER ;

CALL sp_lihat_ruangan();




-- UC 1
DELIMITER //
CREATE PROCEDURE sp_tambah_menu(
	IN p_nama VARCHAR(100),
	IN p_id_kategori INT,
	IN p_deskripsi VARCHAR(255),
	IN p_harga_pokok_penjualan FLOAT,
	IN p_harga_jual FLOAT
)
SQL SECURITY DEFINER
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF NOT fn_validasi_nama_menu(p_nama) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nama menu tidak boleh kosong';
    END IF;

    IF NOT fn_validasi_harga_menu(p_harga_pokok_penjualan, p_harga_jual) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Harga jual harus lebih besar dari harga pokok penjualan';
    END IF;

    START TRANSACTION;
        INSERT INTO menu(nama, id_kategori, deskripsi, harga_pokok_penjualan, harga_jual)
        VALUES (TRIM(p_nama), p_id_kategori, p_deskripsi, p_harga_pokok_penjualan, p_harga_jual);
    COMMIT;
END
DELIMITER ;

CALL sp_tambah_menu('Risoles', 1, 'Tersedia 2 rasa : isi telur + Bihun dan telur + sosis', 10000, 13000)


-- UC 2
DELIMITER //
CREATE PROCEDURE sp_ubah_menu(
	IN p_id_menu INT,
	IN p_nama VARCHAR(100),
	IN p_id_kategori INT,
	IN p_deskripsi VARCHAR(255),
	IN p_harga_pokok_penjualan FLOAT,
	IN p_harga_jual FLOAT
)
SQL SECURITY DEFINER
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF NOT fn_validasi_nama_menu(p_nama) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nama menu tidak boleh kosong';
    END IF;

    IF NOT fn_validasi_harga_menu(p_harga_pokok_penjualan, p_harga_jual) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Harga tidak valid: HPP tidak boleh negatif dan harga jual harus lebih besar dari HPP';
    END IF;

    START TRANSACTION;

    UPDATE menu
    SET nama = TRIM(p_nama),
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
END
DELIMITER;

CALL sp_ubah_menu(1, 'Kebab', 1, 'Daging sapi berbumbu khas Timur Tengah, disajikan dengan roti tortilla, sayuran segar, dan saus yoghurt.', 25000, 35000)


-- UC 4
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
END
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
END
DELIMITER ; 

CALL sp_lihat_menu_customer

DROP PROCEDURE sp_lihat_menu_customer


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
END
DELIMITER ;

CALL sp_lihat_menu_admin

DROP PROCEDURE sp_lihat_menu_admin



DELIMITER //
CREATE PROCEDURE sp_buat_reservasi(
    IN p_nama VARCHAR(100),
    IN p_no_wa VARCHAR(20),
    IN p_tanggal DATE,
    IN p_jam TIME,
    IN p_jumlah_orang INT,
    IN p_id_ruangan INT,
    IN p_deskripsi JSON
)
SQL SECURITY DEFINER
BEGIN
    DECLARE v_id_customer INT;
    DECLARE v_ruangan_ada INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

   
    IF NOT fn_validasi_nama_customer(p_nama) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nama customer tidak boleh kosong';
    END IF;

    IF NOT fn_validasi_format_no_wa(p_no_wa) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Format nomor WhatsApp tidak valid (contoh: 081234567890)';
    END IF;

    IF NOT fn_validasi_jumlah_orang(p_jumlah_orang) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Jumlah orang harus lebih dari 0';
    END IF;

    IF NOT fn_cek_waktu_valid(p_tanggal, p_jam) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Waktu reservasi telah lewat';
    END IF;

    START TRANSACTION;

    -- Kunci baris ruangan supaya dua request untuk ruangan yang sama
    -- diproses bergantian, bukan bersamaan
    SELECT id_ruangan INTO v_ruangan_ada
    FROM ruangan
    WHERE id_ruangan = p_id_ruangan
    FOR UPDATE;

    IF v_ruangan_ada IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ruangan tidak ditemukan';
    END IF;

    -- Cek ketersediaan setelah lock didapat
    IF NOT fn_cek_ketersediaan_ruangan(p_id_ruangan, p_tanggal, p_jam) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ruangan sudah dipesan pada tanggal dan jam tersebut';
    END IF;

    -- Reuse customer lewat no_WA, atau buat baru
    INSERT INTO customer(nama, no_WA)
    VALUES (TRIM(p_nama), p_no_wa)
    ON DUPLICATE KEY UPDATE id_customer = LAST_INSERT_ID(id_customer);

    SET v_id_customer = LAST_INSERT_ID();

    INSERT INTO reservasi(nama_pemesan, tanggal, jam, jumlah_orang, deskripsi, id_ruangan, id_customer)
    VALUES (TRIM(p_nama), p_tanggal, p_jam, p_jumlah_orang, p_deskripsi, p_id_ruangan, v_id_customer);

    COMMIT;
END
DELIMITER ;

-- sukses, customer baru dibuat
CALL sp_buat_reservasi('Ahmad', '081234567890', '2026-12-20', '19:00:00', 4, 4,
    '{"acara": "ulang tahun", "request": ["kursi bayi", "kue"]}');

-- sukses, nomor sama nama beda: customer tidak bertambah
CALL sp_buat_reservasi('Ahmad Fauzi', '081234567890', '2026-12-21', '19:00:00', 2, 4, NULL);

-- error: ruangan sudah dipesan
CALL sp_buat_reservasi('Budi', '082222222222', '2026-12-20', '19:00:00', 2, 4, NULL);

-- error: format no WA
CALL sp_buat_reservasi('Budi', '+6281234567890', '2026-12-22', '19:00:00', 2, 1, NULL);

-- error: waktu sudah lewat
CALL sp_buat_reservasi('Budi', '082222222222', '2020-01-01', '19:00:00', 2, 1, NULL);

-- error: ruangan tidak ada
CALL sp_buat_reservasi('Budi', '082222222222', '2026-12-22', '19:00:00', 2, 999, NULL);



DELIMITER //
CREATE PROCEDURE sp_ubah_nama_customer(
    IN p_id_customer INT,
    IN p_nama VARCHAR(100)
)
SQL SECURITY DEFINER
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF NOT fn_validasi_nama_customer(p_nama) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nama customer tidak boleh kosong';
    END IF;

    START TRANSACTION;

    UPDATE customer
    SET nama = TRIM(p_nama)
    WHERE id_customer = p_id_customer;

    IF ROW_COUNT() = 0 THEN
        -- bisa berarti: baris tidak ada ATAU nilainya memang sama
        IF NOT EXISTS (SELECT 1 FROM customer WHERE id_customer = p_id_customer) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Customer tidak ditemukan';
        END IF;
    END IF;

    COMMIT;
END
DELIMITER ;
CALL sp_ubah_nama_customer(1, 'Ahmad Fauzi')


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
        SELECT re.id_reservasi,
        	   c.id_customer, 
               re.nama_pemesan,
               c.nama AS nama_customer,
               c.no_WA,
               re.tanggal,
               re.jam,
               re.jumlah_orang,
               re.status_reservasi,
               ru.ruangan AS nama_ruangan,
               JSON_UNQUOTE(JSON_EXTRACT(re.deskripsi, '$.acara')) AS acara,
               re.deskripsi
        FROM reservasi re
        JOIN customer c ON re.id_customer = c.id_customer
        JOIN ruangan ru ON re.id_ruangan = ru.id_ruangan
        ORDER BY re.tanggal, re.jam;
   COMMIT;
END
DELIMITER ;

CALL sp_lihat_reservasi();

DROP PROCEDURE sp_lihat_reservasi


DELIMITER //
CREATE PROCEDURE sp_ubah_status_reservasi(
    IN p_id_reservasi INT,
    IN p_status VARCHAR(20)
)
SQL SECURITY DEFINER
BEGIN
    DECLARE v_status_lama VARCHAR(20) DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF NOT fn_validasi_status_reservasi(p_status) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Status tidak valid. Pilihan: pending, confirmed, cancelled';
    END IF;

    START TRANSACTION;

    -- Ambil status lama sekaligus mengunci barisnya
    SELECT status_reservasi INTO v_status_lama
    FROM reservasi
    WHERE id_reservasi = p_id_reservasi
    FOR UPDATE;

    IF v_status_lama IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Reservasi tidak ditemukan';
    END IF;

    IF v_status_lama = 'cancelled' AND p_status <> 'cancelled' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Reservasi yang sudah dibatalkan tidak bisa diaktifkan kembali. Buat reservasi baru';
    END IF;

    UPDATE reservasi
    SET status_reservasi = p_status
    WHERE id_reservasi = p_id_reservasi;

    COMMIT;
END
DELIMITER ;


CALL sp_ubah_status_reservasi(1, 'confirmed');   -- sukses, log bertambah
CALL sp_ubah_status_reservasi(1, 'confirmed');   -- sukses, log TIDAK bertambah (status sama)
CALL sp_ubah_status_reservasi(2, 'cancelled');   -- sukses, log bertambah
CALL sp_ubah_status_reservasi(2, 'pending');     -- error: sudah dibatalkan
CALL sp_ubah_status_reservasi(1, 'selesai');     -- error: status tidak valid
CALL sp_ubah_status_reservasi(1, NULL);          -- error: status tidak valid
CALL sp_ubah_status_reservasi(999, 'confirmed'); -- error: tidak ditemukan



DELIMITER //
CREATE PROCEDURE sp_cari_menu(
    IN p_keyword VARCHAR(100)
)
SQL SECURITY DEFINER
READS SQL DATA
BEGIN
    IF NOT fn_validasi_keyword_menu(p_keyword) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Kata kunci pencarian tidak boleh kosong';
    END IF;

    START TRANSACTION READ ONLY;
        SELECT * FROM v_menu_customer
        WHERE nama LIKE CONCAT(TRIM(p_keyword), '%')
        ORDER BY nama;
    COMMIT;
END
DELIMITER ;

CALL sp_cari_menu('keb');
CALL sp_cari_menu('   ');     -- error
CALL sp_cari_menu('zzz');


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
    	SELECT id_user, username, password AS password_hash
    	FROM user_sistem
    	WHERE username = p_username;
    COMMIT;
END
DELIMITER ;


CALL sp_verifikasi_login('admin1');     -- 1 baris: id_user, username, password_hash
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

    IF NOT fn_validasi_username(p_username) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Username tidak boleh kosong';
    END IF;

    IF NOT fn_validasi_password_hash(p_password_hash) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Password hash tidak valid (harus hash bcrypt)';
    END IF;

    START TRANSACTION;

    INSERT INTO user_sistem (username, password)
    VALUES (TRIM(p_username), p_password_hash);

    COMMIT;

    SELECT LAST_INSERT_ID() AS id_user;
END 
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
    DECLARE v_sisa INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    DELETE FROM user_sistem
    WHERE id_user = p_id_user;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'User tidak ditemukan';
    END IF;

    SELECT COUNT(*) INTO v_sisa FROM user_sistem;

    IF v_sisa = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Tidak boleh menghapus user terakhir';
    END IF;

    COMMIT;
END
DELIMITER ;
CALL sp_hapus_user(1); 



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
    	SELECT id_user, username
    	FROM user_sistem
    	ORDER BY id_user;
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
        SELECT l.id_log,
               l.id_reservasi,
               r.nama_pemesan,
               l.status_lama,
               l.status_baru,
               l.waktu
        FROM log_status_reservasi l
        LEFT JOIN reservasi r ON r.id_reservasi = l.id_reservasi
        ORDER BY l.waktu DESC, l.id_log DESC;
    ELSE
        SELECT l.id_log,
               l.id_reservasi,
               r.nama_pemesan,
               l.status_lama,
               l.status_baru,
               l.waktu
        FROM log_status_reservasi l
        LEFT JOIN reservasi r ON r.id_reservasi = l.id_reservasi
        WHERE l.id_reservasi = p_id_reservasi
        ORDER BY l.waktu DESC, l.id_log DESC;
    END IF;

    COMMIT;
END
DELIMITER ;
CALL sp_ubah_status_reservasi(1, 'confirmed');  -- ganti id sesuai data kamu, memicu trigger
CALL sp_lihat_log_status_reservasi(1);          -- riwayat reservasi 1
CALL sp_lihat_log_status_reservasi(NULL);       -- semua log
CALL sp_lihat_log_status_reservasi(9999);       -- kosong, bukan error



SHOW PROCEDURE STATUS WHERE Db = 'sulthan_feast';




