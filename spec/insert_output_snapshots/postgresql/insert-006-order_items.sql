INSERT INTO order_items (id, quantity, order_id, product_id, updated_at, created_at) VALUES
('3', '1', '3', '3', '2025-01-01 00:00:00', '2025-01-01 00:00:00'),
('4', '1', '4', '1', '2025-01-01 00:00:00', '2025-01-01 00:00:00'),
('5', '1', '5', '2', '2025-01-01 00:00:00', '2025-01-01 00:00:00'),
('6', '1', '6', '3', '2025-01-01 00:00:00', '2025-01-01 00:00:00');
DO $exwiw$
DECLARE
  seq_name text := pg_get_serial_sequence('order_items', 'id');
BEGIN
  IF seq_name IS NOT NULL THEN
    PERFORM setval(seq_name, COALESCE((SELECT MAX(id) FROM order_items), 1));
  END IF;
END $exwiw$;
