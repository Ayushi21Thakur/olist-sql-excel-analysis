-- Olist E-Commerce analysis: load the CSV files into MySQL
--
-- Before running:
--   1. Put the Olist CSV files in C:/olist/ (change the paths below if yours differ;
--      use forward slashes).
--   2. Run: SET GLOBAL local_infile = 1;
--   3. In MySQL Workbench, add OPT_LOCAL_INFILE=1 to the connection's
--      Advanced > Others box, then reconnect.
--   4. If a table already has rows, empty it first: TRUNCATE TABLE table_name;
--
-- Expected row counts:
--   customers 99,441 | orders 99,441 | order_items 112,650 | order_payments 103,886
--   order_reviews 99,223 (source file has 99,224; one row is dropped by the parser)
--   products 32,951 | category_translation 71

USE olist_project;

-- 1. customers
LOAD DATA LOCAL INFILE 'C:/olist/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 2. orders (empty dates become NULL)
LOAD DATA LOCAL INFILE 'C:/olist/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, customer_id, order_status, order_purchase_timestamp,
 @approved, @carrier, @delivered, order_estimated_delivery_date)
SET order_approved_at = NULLIF(@approved, ''),
    order_delivered_carrier_date = NULLIF(@carrier, ''),
    order_delivered_customer_date = NULLIF(@delivered, '');

-- 3. order_items
LOAD DATA LOCAL INFILE 'C:/olist/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 4. order_payments
LOAD DATA LOCAL INFILE 'C:/olist/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 5. order_reviews (Windows line endings and multi-line comments)
LOAD DATA LOCAL INFILE 'C:/olist/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- 6. products (empty cells become NULL)
LOAD DATA LOCAL INFILE 'C:/olist/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(product_id, @cat, @nl, @dl, @photos, @w, @l, @h, @wd)
SET product_category_name = NULLIF(@cat, ''),
    product_name_lenght = NULLIF(@nl, ''),
    product_description_lenght = NULLIF(@dl, ''),
    product_photos_qty = NULLIF(@photos, ''),
    product_weight_g = NULLIF(@w, ''),
    product_length_cm = NULLIF(@l, ''),
    product_height_cm = NULLIF(@h, ''),
    product_width_cm = NULLIF(@wd, '');

-- 7. category_translation (Windows line endings)
LOAD DATA LOCAL INFILE 'C:/olist/product_category_name_translation.csv'
INTO TABLE category_translation
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- Check all row counts at once
SELECT 'customers' AS tbl, COUNT(*) AS n FROM customers
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'category_translation', COUNT(*) FROM category_translation;
