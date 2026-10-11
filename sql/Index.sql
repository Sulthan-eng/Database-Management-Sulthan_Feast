CREATE INDEX idx_menu_nama ON menu(nama);  

-- dengan index
EXPLAIN SELECT * FROM menu WHERE nama LIKE 'keb%';
-- wildcard di depan
EXPLAIN SELECT * FROM menu WHERE nama LIKE '%b%';

SHOW INDEX FROM menu;  


CREATE INDEX idx_reservasi_ruangan_waktu ON reservasi(id_ruangan, waktu_reservasi);

SHOW INDEX FROM reservasi;
                     
CREATE INDEX idx_log_reservasi ON log_status_reservasi(id_reservasi, id_log);

SHOW INDEX FROM log_status_reservasi;