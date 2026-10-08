-- 1. Buat akun (ganti password, jangan di-commit ke repo)  placeholder udh diganti pw.
CREATE USER IF NOT EXISTS 'app_customer'@'localhost' IDENTIFIED BY 'GantiPasswordCustomer1!';
CREATE USER IF NOT EXISTS 'app_admin'@'localhost'    IDENTIFIED BY 'GantiPasswordAdmin1!';


-- 2. Hak app_customer: procedure publik saja
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_lihat_menu_customer TO 'app_customer'@'localhost';
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_cari_menu           TO 'app_customer'@'localhost';
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_lihat_kategori_menu TO 'app_customer'@'localhost';
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_lihat_ruangan       TO 'app_customer'@'localhost';
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_buat_reservasi      TO 'app_customer'@'localhost';


-- 3. Hak app_admin: semua procedure
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_lihat_kategori_menu TO 'app_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_lihat_ruangan       TO 'app_admin'@'localhost';

GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_lihat_menu_admin    TO 'app_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_tambah_menu         TO 'app_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_ubah_menu           TO 'app_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_hapus_menu          TO 'app_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_tambah_kategori_menu TO 'app_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_ubah_kategori_menu  TO 'app_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_hapus_kategori_menu TO 'app_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_tambah_ruangan      TO 'app_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_ubah_ruangan        TO 'app_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_hapus_ruangan       TO 'app_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_lihat_reservasi     TO 'app_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_ubah_status_reservasi TO 'app_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_ubah_nama_customer  TO 'app_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_lihat_log_status_reservasi TO 'app_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_verifikasi_login    TO 'app_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_tambah_user         TO 'app_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_hapus_user          TO 'app_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE sulthan_feast.sp_lihat_user          TO 'app_admin'@'localhost';


SHOW GRANTS FOR 'app_customer'@'localhost';
SHOW GRANTS FOR 'app_admin'@'localhost';

SELECT CURRENT_USER();