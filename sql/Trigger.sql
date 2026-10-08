DELIMITER //
CREATE TRIGGER trg_hapus_reservasi_sebelum_ruangan_dihapus
BEFORE DELETE ON ruangan
FOR EACH ROW
BEGIN
	DELETE FROM reservasi
	WHERE id_ruangan = OLD.id_ruangan;
END
DELIMITER ;


DELIMITER //
CREATE TRIGGER trg_log_status_reservasi
AFTER UPDATE ON reservasi
FOR EACH ROW
BEGIN
    IF OLD.status_reservasi <> NEW.status_reservasi THEN
        INSERT INTO log_status_reservasi(id_reservasi, status_lama, status_baru)
        VALUES (NEW.id_reservasi, OLD.status_reservasi, NEW.status_reservasi);
    END IF;
END
DELIMITER ;