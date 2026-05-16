INSERT INTO shops (id, name, updated_at, created_at) VALUES
('1', 'Shop 1', '2025-01-01 00:00:00', '2025-01-01 00:00:00');
DO $exwiw$
DECLARE
  seq_name text := pg_get_serial_sequence('shops', 'id');
BEGIN
  IF seq_name IS NOT NULL THEN
    PERFORM setval(seq_name, COALESCE((SELECT MAX(id) FROM shops), 1));
  END IF;
END $exwiw$;
