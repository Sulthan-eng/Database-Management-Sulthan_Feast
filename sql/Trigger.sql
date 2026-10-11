DELIMITER //
CREATE TRIGGER trg_log_reservasi_dibuat
AFTER INSERT ON reservasi
FOR EACH ROW
BEGIN
	INSERT INTO log_status_reservasi(id_reservasi, status_reservasi)
	VALUES(NEW.id_reservasi, NEW.status_reservasi);
END //
DELIMITER ;


DELIMITER //
CREATE TRIGGER trg_log_status_reservasi
AFTER UPDATE ON reservasi
FOR EACH ROW
BEGIN
    IF OLD.status_reservasi <> NEW.status_reservasi THEN
        INSERT INTO log_status_reservasi(id_reservasi, status_reservasi)
        VALUES (NEW.id_reservasi, NEW.status_reservasi);
    END IF;
END //
DELIMITER ;


DELIMITER //
CREATE TRIGGER trg_sinkron_status_ruangan
AFTER UPDATE ON reservasi
FOR EACH ROW
BEGIN
    IF OLD.status_reservasi <> NEW.status_reservasi THEN
        IF NEW.status_reservasi = 'berlangsung' THEN
            UPDATE ruangan
            SET status_ruangan = 'Sedang Dipakai'
            WHERE id_ruangan = NEW.id_ruangan;
        ELSEIF OLD.status_reservasi = 'berlangsung' THEN
            UPDATE ruangan
            SET status_ruangan = 'Tersedia'
            WHERE id_ruangan = NEW.id_ruangan
              AND status_ruangan = 'Sedang Dipakai';
        END IF;
    END IF;
END //
DELIMITER ;