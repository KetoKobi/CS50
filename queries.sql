-- In this SQL file, write (and comment!) the typical SQL queries users will run on your database

-- ====================================================================
-- 1. INSERTIN AND UPDATING DATA
-- ====================================================================

-- Add a new corporate client to the master customers table
INSERT INTO "customers" ("name", "contact_person", "phone")
VALUES  ('Universal', 'Nika Zarandia', '+1-555-0199'),
        ('New Farm', 'Nika Zarandia', '+1-555-0199'),
        ('Old Famr', 'Nika Zarandia', '+1-555-0199');

-- Add a newly sourced raw material to the product catalog
INSERT INTO "product" ("id", "name", "category", "group", "line", "unit_of_measure")
VALUES ('1007000', 'Spark - Adult Dog Food', 'Finished', 'DOG', 'PF', 'kg');

-- Update the minimum stock percentage safety threshold for a specific finished good
UPDATE "product"
SET "min_stock_percentage" = 15
WHERE "id" = '1007000';

INSERT INTO "production_plan" ("production_date", "product_id", "quantity", "status")
VALUES  ('2026-05-26', '1001786', 5000, 'Scheduled'),
        ('2026-05-27', '1001088', 50000, 'Scheduled'),
        ('2026-05-28', '1001089', 50000, 'Scheduled');

UPDATE "kpi"
SET "finished_goods" = 4950,
    "scrap" = 20,
    "defected" = 30,
    "intake" = 5000
WHERE "product_id" = '1001786' AND "production_date" = '2026-05-26';

UPDATE "kpi"
SET "finished_goods" = 48500,
    "scrap" = 500,
    "defected" = 1000,
    "intake" = 49990
WHERE "product_id" = '1001088' AND "production_date" = '2026-05-27';

UPDATE "kpi"
SET "finished_goods" = 49000,
    "scrap" = 200,
    "defected" = 800,
    "intake" = 50020
WHERE "product_id" = '1001089' AND "production_date" = '2026-05-28';

INSERT INTO "sales_orders" ("product_id", "quantity", "client_id", "so_date")
VALUES ('1001088', 10000, '1', '2026-05-27');

UPDATE "forecast"
SET "delete" = 1
WHERE "year" = '2025';

-- ====================================================================
-- 2. QUERING
-- ====================================================================

SELECT "name", "total_stock", "total_forecast", "deficit"
FROM "ppc"
WHERE "deficit" < 0
ORDER BY "deficit" ASC;

SELECT "raw_material_name", SUM("Raw Material Order") AS "total_required_kg"
FROM "rmo"
GROUP BY "raw_material_name"
ORDER BY "total_required_kg" DESC;

SELECT "product_id", "total_raw_material_intake", "total_factory_output", ("total_factory_output" - "total_raw_material_intake") AS "გამოსავლიოანობა"
FROM "production_results"
WHERE "total_factory_output" > 0;

SELECT "name", "total_stock"
FROM "view_live_inventory"
ORDER BY "total_stock" DESC;

SELECT "product_name", "total_quantity_purchased"
FROM "view_customer_sales_info"
WHERE "customer_id" = '1'
ORDER BY "total_quantity_purchased" DESC;

SELECT * FROM product;
SELECT * FROM customers;
SELECT * FROM BoM;
SELECT * FROM forecast;
SELECT * FROM inventory;
SELECT * FROM production_plan;
SELECT * FROM kpi;
SELECT * FROM sales_orders;
SELECT * FROM view_live_inventory;
SELECT * FROM product_forecast;
SELECT * FROM ppc;
SELECT * FROM production_results;
SELECT * FROM rmf;
SELECT * FROM rmo;
SELECT * FROM view_customer_sales_info;
