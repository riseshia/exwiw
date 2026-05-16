INSERT INTO orders (id, shop_id, user_id, updated_at, created_at) VALUES
('3', '1', '1', '2025-01-01 00:00:00', '2025-01-01 00:00:00'),
('4', '1', '2', '2025-01-01 00:00:00', '2025-01-01 00:00:00'),
('5', '1', '2', '2025-01-01 00:00:00', '2025-01-01 00:00:00'),
('6', '1', '2', '2025-01-01 00:00:00', '2025-01-01 00:00:00');
DO $exwiw$
DECLARE
  seq_name text := pg_get_serial_sequence('orders', 'id');
BEGIN
  IF seq_name IS NOT NULL THEN
    PERFORM setval(seq_name, COALESCE((SELECT MAX(id) FROM orders), 1));
  END IF;
END $exwiw$;
