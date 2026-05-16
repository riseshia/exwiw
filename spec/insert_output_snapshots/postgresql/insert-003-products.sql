INSERT INTO products (id, name, price, shop_id, updated_at, created_at) VALUES
('1', 'Product 1', '10.00', '1', '2025-01-01 00:00:00', '2025-01-01 00:00:00'),
('2', 'Product 2', '20.00', '1', '2025-01-01 00:00:00', '2025-01-01 00:00:00'),
('3', 'Product 3', '30.00', '1', '2025-01-01 00:00:00', '2025-01-01 00:00:00');
DO $exwiw$
DECLARE
  seq_name text := pg_get_serial_sequence('products', 'id');
BEGIN
  IF seq_name IS NOT NULL THEN
    PERFORM setval(seq_name, COALESCE((SELECT MAX(id) FROM products), 1));
  END IF;
END $exwiw$;
