# Design Document

By KETEVAN KOBIASHVILI

Video overview: <URL HERE>

## Scope

![Entity Relationship Diagram](erd.jpg)

In this section you should answer the following questions:

* What is the purpose of your database?

The purpose of this database is to manage manufacturing supply chain system. It acts as an operational data storege and calculation engine for factory operations, synchronizing master product and client records with operations. This includes managing Sales Forecasting, Bill of Materials (BoM), Production Planning, manufacturing performance (KPI) tracking, Sales Orders, and real-time Inventory.

* Which people, places, things, etc. are you including in the scope of your database?

Stakeholders: Customers, Production Planning and Control Manager, Warehouse Manager, Production, Porcurement.

Physical & Master Items: Products Catalogue and Bill of Materials (BoM).

Operational Workflows: Monthly and yearly Sales Forecasts, Master Production Plans, Daily Production Performance Logs (tracking intake, completed finished goods, scrap, and defects), Sales Orders, and Inventory Tracking.

* Which people, places, things, etc. are *outside* the scope of your database?

HR & Labor: Factory personnel (operators, shift schedules, HR).

Logistics: Physical warehouse mapping and external shipping/freight tracking.

Financial Accounting: Dynamic pricing, cost of goods sold, margins, manufacturing overhead, and invoicing workflows.

Maintenance: Machine maintenance, breakdown tracking, and vendor profiling.

## Functional Requirements

In this section you should answer the following questions:

* What should a user be able to do with your database?

Unified Catalog Maintenance: Maintain a centralized product and raw material catalog categorized by group, line, and status.

Material Deficit Control: Compare forecasted demand against real-time active stock via the Production Planning and Control (ppc) view to highlight material shortfalls for items categorized as 'FINISHED'.

Procurement Forecasting & Ordering: Generate material requirement projections via the rmf (Raw Material Forecast) view and calculate immediate raw material ordering needs via the rmo (Raw Material Order) view based only on plans with a 'Scheduled' status.

Automated Log: Automatically initialize a shop-floor performance record (kpi) whenever a new production plan is scheduled via an AFTER INSERT trigger.

Automated Inventory: Rely on automated inventory updates. Inserting a sales order, scheduling a production plan (drawing raw materials), or posting production results (UPDATE on kpi.finished_goods) instantly routes exact positive or negative adjustments to the inventory via triggers.

Client Behavior Tracking: Aggregate historical client purchasing habits and total ordered volumes per product.

* What's beyond the scope of what a user should be able to do with your database?

Process dynamic invoice pricing, apply customer tier discounts, or calculate VAT/taxes.

Track vendor procurement lead times or track external supplier fulfillment cycles.

Log sub-second real-time manufacturing machinery sensor metrics.

## Representation

### Entities

In this section you should answer the following questions:

* Which entities will you choose to represent in your database?

The database implements the following tables:

Master Data Entities
product: Holds the core catalog of all raw materials, consumables and finished goods.

customers: Stores client information.

Operational Entities
BoM (Bill of Materials): Stores multi-ingredient manufacturing formulas.

forecast: Tracks projected sales demands segmented by year, month and products.

inventory: An transaction ledger tracking positive and negative changes to stock levels.

production_plan: Stores scheduled manufacturing plans and daily targets.

kpi: Tracks operational shop-floor outcomes per run.

sales_orders: Registers client orders.

* What attributes will those entities have?

product: id (INTEGER, PK), name (TEXT, Unique), category (TEXT), group (TEXT), line (TEXT), market (TEXT), country (TEXT), status (TEXT), packing (TEXT), net_weight (NUMERIC), unit_of_measure (TEXT), min_stock_percentage (INTEGER).

customers: id (INTEGER, PK), name (TEXT), contact_person (TEXT), phone (TEXT).

BoM: id (INTEGER, PK), product_id (INTEGER, FK), rm_id (INTEGER, FK), quantity (NUMERIC), batch_size (INTEGER).

forecast: id (INTEGER, PK), product_id (INTEGER, FK), year (INTEGER), month (INTEGER), quantity (INTEGER), delete (INTEGER).

production_plan: id (INTEGER, PK), production_date (DATE), product_id (INTEGER, FK), quantity (INTEGER), status (TEXT).

kpi: id (INTEGER, PK), product_id (INTEGER, FK), production_date (DATE), production_quantity (INTEGER), production_start_time (DATETIME), production_end_time (DATETIME), line (TEXT), group (TEXT), shift (TEXT), intake (INTEGER), finished_goods (INTEGER), scrap (INTEGER), defected (INTEGER).

sales_orders: id (INTEGER, PK), product_id (TEXT), quantity (INTEGER), client_id (TEXT), so_date (NUMERIC).

* Why did you choose the types you did?

INTEGER for Primary Keys and Foreign Keys: Enforces structural standard indexing across master and transactional operational tables.

TEXT for Category, Group, and Line Classifications: human-readable strings.

NUMERIC for Weights & Formulations: Applied to product.net_weight and BoM.quantity to avoid floating-point errors.

DATE / DATETIME / NUMERIC for Timelines: Used to record daily operations.

* Why did you choose the constraints you did?

PRIMARY KEY (without manual sequence increments): Assigned across tables to enforce entity integrity.

UNIQUE and NOT NULL on product.name: Prevents duplications in the core catalogue data stream.

DEFAULT Values: Applied to shield calculations from null breaks (e.g., batch_size DEFAULT 1000, finished_goods DEFAULT 0, delete DEFAULT 0).

FOREIGN KEY References: Prevents orphan transactions.

### Relationships

Many-to-Many (product to BoM): A single finished product requires multiple raw materials, and raw materials are shared across different product recipes. This is structurally managed via the product_id and rm_id foreign keys inside the BoM table (both referencing the product.id primary key).

One-to-Many Operational Mappings: The product table shares a one-to-many relationship with all core transactions including forecast, inventory, production_plan, kpi, and sales_orders. The customers table maintains a one-to-many relationship with sales_orders through the client_id foreign key.

## Optimizations

In this section you should answer the following questions:

* Which optimizations (e.g., indexes, views) did you create? Why?

Built-in Views
view_live_inventory & product_forecast: Decouple stock and forecast aggregations into modular steps.

ppc (Production Planning & Control): Combines inventory levels and demand targets using LEFT JOIN and COALESCE statements. This ensures that items with unfulfilled forecasts and 0 stock do not crash into NULL outputs, protecting deficit visibility.

rmf & rmo: Automate the material requirements planning formulas by scaling raw material quantities based on target forecasts and production plans against their defined batch_size.

production_results & view_customer_sales_info: Pre-aggregate shop-floor performance metrics and customer total sales metrics to minimize query syntax complexity for business users.

Indexes
idx_product_mappings ON BoM (product_id, rm_id): A composite covering index that accelerates multi-join formula lookups and automated trigger executions.

idx_plan_lookup ON production_plan (production_date): Optimizes date-based sorting for time-sensitive production planning boards.

idx_sales_client_search ON sales_orders (client_id, product_id): Matches the aggregation grouping structure of customer history views.

## Limitations

In this section you should answer the following questions:

* What are the limitations of your design?

Deleting or modifying an production_plan or a historical kpi log will fail to reverse raw material deduction or finished goods  adjustments.

* What might your database not be able to represent very well?

Lack of Tracebility: Inventory balances are calculated accordint to product_id. The schema does not include a "Lot Number" or unique "Batch Run ID" component.
