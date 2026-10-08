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

ALTER TABLE menu RENAME COLUMN harga_bersih TO harga_jual 



CREATE TABLE ruangan (
	id_ruangan INT PRIMARY KEY AUTO_INCREMENT,
	ruangan VARCHAR(100) NOT NULL,
	deskripsi VARCHAR(255)
);


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
ALTER TABLE reservasi MODIFY status_reservasi ENUM('pending', 'confirmed', 'cancelled') NOT NULL DEFAULT 'pending';



CREATE TABLE log_status_reservasi (
    id_log INT PRIMARY KEY AUTO_INCREMENT,
    id_reservasi INT NOT NULL,
    status_lama ENUM('pending', 'confirmed', 'cancelled') NOT NULL,
    status_baru ENUM('pending', 'confirmed', 'cancelled') NOT NULL,
    waktu TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


