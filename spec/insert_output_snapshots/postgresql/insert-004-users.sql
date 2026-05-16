INSERT INTO users (id, name, email, shop_id, updated_at, created_at) VALUES
('1', 'masked1', 'masked1@example.com', '1', '2025-01-01 00:00:00', '2025-01-01 00:00:00'),
('2', 'masked2', 'masked2@example.com', '1', '2025-01-01 00:00:00', '2025-01-01 00:00:00');
DO $exwiw$
DECLARE
  seq_name text := pg_get_serial_sequence('users', 'id');
BEGIN
  IF seq_name IS NOT NULL THEN
    PERFORM setval(seq_name, COALESCE((SELECT MAX(id) FROM users), 1));
  END IF;
END $exwiw$;
