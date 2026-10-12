USE sulthan_feast;

CREATE TABLE kategori_menu (
	id_kategori INT PRIMARY KEY AUTO_INCREMENT,
	kategori VARCHAR(100) NOT NULL 
);


CREATE TABLE menu (
    id_menu INT PRIMARY KEY AUTO_INCREMENT,
    nama VARCHAR(100)  NOT NULL,
    deskripsi VARCHAR(255),
    harga_pokok_penjualan DECIMAL(12,2) NOT NULL,
    harga_jual DECIMAL(12,2) NOT NULL,
    id_kategori INT NOT NULL,
    FOREIGN KEY (id_kategori) REFERENCES kategori_menu(id_kategori),
    CONSTRAINT chk_menu_harga CHECK (harga_pokok_penjualan >= 0 AND harga_jual > harga_pokok_penjualan)
);


CREATE TABLE ruangan (
    id_ruangan INT PRIMARY KEY AUTO_INCREMENT,
    ruangan VARCHAR(100) NOT NULL,
    deskripsi VARCHAR(255),
    status_ruangan ENUM('Tersedia', 'Sedang Dipakai', 'Pemeliharaan', 'Nonaktif') NOT NULL DEFAULT 'Tersedia'
);

CREATE TABLE user_sistem (
    id_user INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL    
);


CREATE TABLE customer (
    id_customer INT PRIMARY KEY AUTO_INCREMENT,
    nama VARCHAR(100) NOT NULL,
    no_WA VARCHAR(20) NOT NULL UNIQUE,
    CONSTRAINT chk_customer_no_wa CHECK (no_WA REGEXP '^08[0-9]{8,11}$')
);


CREATE TABLE reservasi (
    id_reservasi INT PRIMARY KEY AUTO_INCREMENT,
    nama_pemesan VARCHAR(100) NOT NULL,
    waktu_reservasi DATETIME NOT NULL,  
    waktu_selesai DATETIME NOT NULL,   
    jumlah_orang INT NOT NULL,
    status_reservasi ENUM('pending', 'confirmed', 'berlangsung', 'selesai', 'cancelled') NOT NULL DEFAULT 'pending',
    catatan JSON,
    id_ruangan INT NOT NULL,
    id_customer INT NOT NULL,
    FOREIGN KEY (id_ruangan)  REFERENCES ruangan(id_ruangan),
    FOREIGN KEY (id_customer) REFERENCES customer(id_customer),
    CONSTRAINT chk_reservasi_durasi CHECK (waktu_selesai > waktu_reservasi),
    CONSTRAINT chk_reservasi_jumlah_orang CHECK (jumlah_orang > 0)
);


CREATE TABLE log_status_reservasi (
    id_log INT PRIMARY KEY AUTO_INCREMENT,
    id_reservasi INT NOT NULL,
    nama_pemesan VARCHAR(100) NOT NULL,
    status_reservasi ENUM('pending', 'confirmed', 'berlangsung', 'selesai', 'cancelled') NOT NULL,
    waktu TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

