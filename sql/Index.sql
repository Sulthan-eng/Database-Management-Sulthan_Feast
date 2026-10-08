CREATE INDEX idx_menu_nama ON menu(nama);  

-- dengan index
EXPLAIN SELECT * FROM menu WHERE nama LIKE 'keb%';
-- wildcard di depan
EXPLAIN SELECT * FROM menu WHERE nama LIKE '%b%';

SHOW INDEX FROM menu;  


CREATE INDEX idx_reservasi_ruangan_waktu ON reservasi(id_ruangan, tanggal, jam);

SHOW INDEX FROM reservasi;
                     

SELECT CURRENT_USER();