USE sulthan_feast;

CREATE TABLE kategori_menu (
	id_kategori INT PRIMARY KEY AUTO_INCREMENT,
	kategori VARCHAR(100) NOT NULL 
);


CREATE TABLE menu (
	id_menu INT PRIMARY KEY AUTO_INCREMENT,
	nama VARCHAR(100) NOT NULL,
	deskripsi VARCHAR(255),
	harga_pokok_penjualan FLOAT NOT NULL,
	harga_bersih FLOAT NOT NULL,
	id_kategori INT NOT NULL,
	
	FOREIGN KEY(id_kategori) REFERENCES kategori_menu(id_kategori)
);

ALTER TABLE menu RENAME COLUMN harga_bersih TO harga_jual; 

-- nambah constraint harga_pokok_penjualan < harga_jual
ALTER TABLE menu ADD CONSTRAINT chk_menu_harga
CHECK (harga_pokok_penjualan >= 0 AND harga_jual > harga_pokok_penjualan);

ALTER TABLE menu
MODIFY harga_pokok_penjualan DECIMAL(12,2) NOT NULL,
MODIFY harga_jual DECIMAL(12,2) NOT NULL;



CREATE TABLE ruangan (
	id_ruangan INT PRIMARY KEY AUTO_INCREMENT,
	ruangan VARCHAR(100) NOT NULL,
	deskripsi VARCHAR(255)
);

ALTER TABLE ruangan ADD COLUMN status_ruangan ENUM('Tersedia', 'Sedang Dipakai', 'Pemeliharaan', 'Nonaktif') NOT NULL DEFAULT 'Tersedia';


CREATE TABLE user_sistem (
	id_user INT PRIMARY KEY AUTO_INCREMENT,
	username VARCHAR(100) NOT NULL UNIQUE,
	password VARCHAR(255) NOT NULL,
	role VARCHAR(50) NOT NULL
);
-- hapus role
ALTER TABLE user_sistem DROP COLUMN role;


CREATE TABLE customer (
	id_customer INT PRIMARY KEY AUTO_INCREMENT,
	nama VARCHAR(100) NOT NULL,
	no_WA VARCHAR(20) NOT NULL UNIQUE
);
ALTER TABLE customer ADD CONSTRAINT chk_customer_no_wa CHECK (no_WA REGEXP '^08[0-9]{8,11}$');


CREATE TABLE reservasi (
	id_reservasi INT PRIMARY KEY AUTO_INCREMENT,
	tanggal DATE NOT NULL,
	jam TIME NOT NULL,
	jumlah_orang INT NOT NULL,
	status_reservasi ENUM('pending', 'confirmed', 'cancelled') DEFAULT 'pending' ,
	deskripsi JSON,
	id_ruangan INT NOT NULL,
	id_customer INT NOT NULL,
	FOREIGN KEY(id_ruangan) REFERENCES ruangan(id_ruangan),
	FOREIGN KEY(id_customer) REFERENCES customer(id_customer)
);
ALTER TABLE reservasi ADD COLUMN nama_pemesan VARCHAR(100) NOT NULL AFTER id_reservasi;

ALTER TABLE reservasi MODIFY status_reservasi ENUM('pending', 'confirmed', 'cancelled', 'berlangsung', 'selesai') NOT NULL DEFAULT 'pending';

ALTER TABLE reservasi CHANGE COLUMN tanggal waktu_reservasi DATETIME NOT NULL;

ALTER TABLE reservasi DROP COLUMN jam;

ALTER TABLE reservasi RENAME COLUMN deskripsi to catatan;

ALTER TABLE reservasi ADD CONSTRAINT chk_reservasi_jumlah_orang CHECK (jumlah_orang > 0);

ALTER TABLE reservasi ADD COLUMN waktu_selesai DATETIME NULL AFTER waktu_reservasi;
ALTER TABLE reservasi MODIFY COLUMN waktu_selesai DATETIME NOT NULL;
ALTER TABLE reservasi ADD CONSTRAINT chk_reservasi_durasi CHECK (waktu_selesai > waktu_reservasi);



CREATE TABLE log_status_reservasi (
    id_log INT PRIMARY KEY AUTO_INCREMENT,
    id_reservasi INT NOT NULL,
    status_lama ENUM('pending', 'confirmed', 'cancelled') NOT NULL,
    status_baru ENUM('pending', 'confirmed', 'cancelled') NOT NULL,
    waktu TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE log_status_reservasi DROP COLUMN status_lama;
ALTER TABLE log_status_reservasi RENAME COLUMN status_baru TO status_reservasi;
ALTER TABLE log_status_reservasi MODIFY COLUMN status_reservasi
  ENUM('pending','confirmed','cancelled','berlangsung','selesai') NOT NULL;


