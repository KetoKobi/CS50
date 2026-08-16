-- ====================================================================
-- 1. MASTER DATA
-- ====================================================================

CREATE TABLE "product" (
    "id" INTEGER,
    "name" TEXT UNIQUE NOT NULL,
    "category" TEXT NOT NULL,
    "group" TEXT NOT NULL,
    "line" TEXT NOT NULL,
    "market" TEXT,
    "country" TEXT,
    "status" TEXT DEFAULT 'Active',
    "packing" TEXT,
    "net_weight" NUMERIC,
    "unit_of_measure" TEXT,
    "min_stock_percentage" INTEGER,
     PRIMARY KEY ("id")
);

.import --csv --skip 1 Catalogue.csv product

CREATE TABLE "customers" (
    "id" INTEGER,
    "name" TEXT,
    "contact_person" TEXT,
    "phone" TEXT,
    PRIMARY KEY ("id")
);

-- ====================================================================
-- 2. OPERATIONAL TABLES
-- ====================================================================

CREATE TABLE "BoM" (
    "id" INTEGER,
    "product_id" INTEGER,
    "rm_id" INTEGER,
    "quantity" NUMERIC,
    "batch_size" INTEGER DEFAULT 1000,
    PRIMARY KEY ("id"),
    FOREIGN KEY ("product_id") REFERENCES "product" ("id"),
    FOREIGN KEY ("rm_id") REFERENCES "product" ("id")
);

.import --csv BoM.csv temp_BoM

INSERT INTO "BoM" ("product_id", "rm_id", "quantity", "batch_size")
SELECT "product_id", "rm_id", "quantity", "batch_size" FROM "temp_BoM";

CREATE TABLE "forecast" (
    "id" INTEGER,
    "product_id" INTEGER,
    "year" INTEGER,
    "month" INTEGER,
    "quantity" INTEGER,
    "delete" INTEGER DEFAULT 0,
    PRIMARY KEY ("id"),
    FOREIGN KEY ("product_id") REFERENCES "product" ("id")
);

.import --csv Forecast.csv forecast_temp

INSERT INTO "forecast" ("product_id", "year", "month", "quantity")
SELECT "product_id", "year", "month", "quantity" FROM "forecast_temp";

CREATE TABLE "inventory" (
    "id" INTEGER,
    "product_id" TEXT,
    "quantity" INTEGER DEFAULT 0,
    PRIMARY KEY ("id"),
    FOREIGN KEY ("product_id") REFERENCES "product" ("id")
);

.import --csv Inventory.csv inventory_temp

INSERT INTO "inventory" ("product_id", "quantity")
SELECT "product_id", "quantity" FROM "inventory_temp";

CREATE TABLE "production_plan" (
    "id" INTEGER,
    "production_date" DATE,
    "product_id" INTEGER NOT NULL,
    "quantity" INTEGER,
    "status" TEXT DEFAULT 'Scheduled',
    PRIMARY KEY ("id"),
    FOREIGN KEY ("product_id") REFERENCES "product" ("id")
);

CREATE TABLE "kpi" (
    "id" INTEGER,
    "product_id" INTEGER,
    "production_date" DATE,
    "production_quantity" INTEGER,
    "production_start_time" DATETIME,
    "production_end_time" DATETIME,
    "line" TEXT,
    "group" TEXT,
    "shift" TEXT,
    "intake" INTEGER,
    "finished_goods" INTEGER DEFAULT 0,
    "scrap" INTEGER DEFAULT 0,
    "defected" INTEGER DEFAULT 0,
    PRIMARY KEY ("id"),
    FOREIGN KEY ("product_id") REFERENCES "product" ("id")
);

CREATE TABLE "sales_orders" (
    "id" INTEGER,
    "product_id" TEXT,
    "quantity" INTEGER,
    "client_id" TEXT,
    "so_date" NUMERIC,
    PRIMARY KEY ("id"),
    FOREIGN KEY ("product_id") REFERENCES "product" ("id"),
    FOREIGN KEY ("client_id") REFERENCES "customers" ("id")
);

-- ====================================================================
-- 3. VIEWS
-- ====================================================================

CREATE VIEW "view_live_inventory" AS
SELECT
    "p"."id",
    "p"."name",
    SUM("i"."quantity") AS "total_stock"
FROM "product" "p"
JOIN "inventory" "i"
ON "p"."id" = "i"."product_id"
WHERE "p"."status" = 'Active'
GROUP BY "p"."id";

CREATE VIEW "product_forecast" AS
SELECT
    "p"."id",
    "p"."name",
    SUM("f"."quantity") AS "total_forecast"
FROM "product" "p"
JOIN "forecast" "f"
ON "p"."id" = "f"."product_id"
WHERE "p"."status" = 'Active' AND "f"."delete"= 0
GROUP BY "f"."year", "p"."id";

CREATE VIEW "ppc" AS
SELECT
    "p"."id",
    "p"."name",
    COALESCE("li"."total_stock", 0) AS "total_stock",
    COALESCE("pf"."total_forecast", 0) AS "total_forecast",
    (COALESCE("li"."total_stock", 0) - COALESCE("pf"."total_forecast", 0)) AS "deficit"
FROM "product" "p"
LEFT JOIN "view_live_inventory" "li" ON "p"."id" = "li"."id"
LEFT JOIN "product_forecast" "pf" ON "p"."id" = "pf"."id"
WHERE "p"."status" = 'Active' AND "category" = 'FINISHED';


CREATE VIEW "production_results" AS
SELECT
    "product_id",
    SUM("intake") AS "total_raw_material_intake",
    SUM("finished_goods" + "scrap" + "defected") AS "total_factory_output"
FROM "kpi"
GROUP BY "product_id";

CREATE VIEW "rmf" AS
SELECT
    "f"."year",
    "f"."month",
    "bom"."rm_id",
    "p"."name" AS "raw_material_name",
    SUM("f"."quantity" * "bom"."quantity") * 1.0 / "bom"."batch_size" AS "Raw Material Forecast"
FROM "forecast" "f"
JOIN "BoM" "bom" ON "f"."product_id" = "bom"."product_id"
JOIN "product" "p" ON "p"."id" = "bom"."rm_id"
WHERE "p"."status" = 'Active' AND "f"."delete"= 0
GROUP BY "f"."year", "f"."month", "bom"."rm_id", "p"."name", "bom"."batch_size";

CREATE VIEW "rmo" AS
SELECT
    "pp"."production_date",
    "bom"."rm_id",
    "p"."name" AS "raw_material_name",
    ("pp"."quantity" * "bom"."quantity") * 1.0 / "bom"."batch_size" AS "Raw Material Order"
FROM "production_plan" "pp"
JOIN "BoM" "bom" ON "pp"."product_id" = "bom"."product_id"
JOIN "product" "p" ON "p"."id" = "bom"."rm_id"
WHERE "pp"."status" = 'Scheduled';

CREATE VIEW "view_customer_sales_info" AS
SELECT
    "cm"."id" AS "customer_id",
    "cm"."name" AS "customer_name",
    "p"."id" AS "product_id",
    "p"."name" AS "product_name",
    SUM("so"."quantity") AS "total_quantity_purchased"
FROM "sales_orders" "so"
JOIN "customers" "cm" ON "so"."client_id" = "cm"."id"
JOIN "product" "p" ON "p"."id" = "so"."product_id"
GROUP BY "cm"."id", "cm"."name", "p"."id", "p"."name";


-- ====================================================================
-- 4. TRIGGERS
-- ====================================================================

DROP TRIGGER IF EXISTS "pplan_to_kpi";

CREATE TRIGGER "pplan_to_kpi"
AFTER INSERT ON "production_plan"
FOR EACH ROW
BEGIN
    INSERT INTO "kpi" (
        "production_date",
        "product_id",
        "production_quantity",
        "finished_goods",
        "scrap",
        "defected"
    )
    VALUES (
        NEW."production_date",
        NEW."product_id",
        NEW."quantity",
        0, 0, 0
    );
END;

CREATE TRIGGER "kpi_to_inventory"
AFTER UPDATE OF "finished_goods" ON "kpi"
BEGIN
    INSERT INTO "inventory" ("product_id", "quantity")
    VALUES (NEW."product_id", NEW."finished_goods" - OLD."finished_goods");
END;

CREATE TRIGGER "sales_from_inventory"
AFTER INSERT ON "sales_orders"
BEGIN
    INSERT INTO "inventory" ("product_id", "quantity")
    VALUES (NEW."product_id", -NEW."quantity");
END;

CREATE TRIGGER "sales_to_inventory"
AFTER DELETE ON "sales_orders"
BEGIN
    INSERT INTO "inventory" ("product_id", "quantity")
    VALUES (OLD."product_id", OLD."quantity");
END;

CREATE TRIGGER "rmo_from_inventory"
AFTER INSERT ON "production_plan"
BEGIN
    INSERT INTO "inventory" ("product_id", "quantity")
    SELECT
        "b"."rm_id",
        -ROUND(("b"."quantity" * 1.0 / "b"."batch_size") * NEW."quantity", 2)
    FROM "BoM" "b"
    WHERE "b"."product_id" = NEW."product_id";
END;

-- ====================================================================
-- 5. INDEXES
-- ====================================================================
CREATE INDEX "idx_product_mappings" ON "BoM" ("product_id", "rm_id");
CREATE INDEX "idx_plan_lookup" ON "production_plan" ("production_date");
CREATE INDEX "idx_sales_client_search" ON "sales_orders" ("client_id", "product_id");
