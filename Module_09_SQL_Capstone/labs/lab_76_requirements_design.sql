/*******************************************************************************
 * LAB 76: SQL Capstone - Requirements and Design
 * Module 09: SQL Capstone Project
 * 
 * Objective: Define project requirements, create logical data model, and
 *            plan the overall architecture for the GlobalMart data platform.
 * 
 * Duration: 6-8 hours
 * 
 * Topics Covered:
 * - Requirements gathering
 * - Logical data modeling
 * - Entity relationship diagrams
 * - Architecture planning
 ******************************************************************************/

/*******************************************************************************
 * PART 1: PROJECT OVERVIEW AND REQUIREMENTS
 ******************************************************************************/

/*
=============================================================================
GLOBALMART ENTERPRISE DATA PLATFORM
=============================================================================

COMPANY BACKGROUND:
- GlobalMart is an international retail company
- Operates in 5 regions: North America, Europe, Asia, South America, Australia
- 150+ stores worldwide
- 50,000+ products across 20 categories
- 2 million+ customers
- 10+ years of historical data

CURRENT CHALLENGES:
1. Data scattered across multiple systems
2. No single source of truth
3. Manual reporting processes
4. Inconsistent metrics definitions
5. Limited historical analysis capability

PROJECT GOALS:
1. Centralized data warehouse
2. Automated ETL processes
3. Self-service BI reporting
4. Real-time operational dashboards
5. Historical trend analysis
*/

-- Document business requirements
CREATE TABLE #BusinessRequirements (
    RequirementID INT IDENTITY(1,1),
    Category NVARCHAR(50),
    RequirementDescription NVARCHAR(500),
    Priority NVARCHAR(20),
    Status NVARCHAR(20)
);

INSERT INTO #BusinessRequirements VALUES
-- Functional Requirements
('Functional', 'System must consolidate sales data from all regional systems', 'High', 'Planned'),
('Functional', 'System must track customer purchase history for 7+ years', 'High', 'Planned'),
('Functional', 'System must support daily sales reporting by 6 AM local time', 'High', 'Planned'),
('Functional', 'System must calculate customer lifetime value', 'Medium', 'Planned'),
('Functional', 'System must track inventory levels across all locations', 'High', 'Planned'),
('Functional', 'System must support promotional analysis', 'Medium', 'Planned'),
('Functional', 'System must track supplier performance metrics', 'Medium', 'Planned'),
('Functional', 'System must support currency conversion for global reporting', 'High', 'Planned'),

-- Non-Functional Requirements
('Performance', 'Dashboard queries must complete within 3 seconds', 'High', 'Planned'),
('Performance', 'Daily ETL must complete within 4 hours', 'High', 'Planned'),
('Performance', 'System must handle 10 million transactions per day', 'High', 'Planned'),
('Scalability', 'System must support 5 years of growth (5x data volume)', 'Medium', 'Planned'),
('Availability', 'System must have 99.5% uptime during business hours', 'High', 'Planned'),
('Security', 'Data must be accessible only to authorized users', 'High', 'Planned'),
('Security', 'System must implement row-level security by region', 'High', 'Planned'),
('Compliance', 'System must support GDPR requirements for EU data', 'High', 'Planned');

SELECT * FROM #BusinessRequirements;

/*******************************************************************************
 * PART 2: SOURCE SYSTEM ANALYSIS
 ******************************************************************************/

/*
=============================================================================
SOURCE SYSTEMS INVENTORY
=============================================================================

1. REGIONAL POS SYSTEMS (5 systems)
   - Technology: Various (SQL Server, Oracle, MySQL)
   - Update Frequency: Real-time
   - Data: Transactions, line items, payments

2. INVENTORY MANAGEMENT SYSTEM
   - Technology: Oracle
   - Update Frequency: Hourly
   - Data: Stock levels, movements, warehouses

3. CUSTOMER CRM SYSTEM
   - Technology: Salesforce (API)
   - Update Frequency: Daily
   - Data: Customer profiles, segments, interactions

4. PRODUCT MASTER DATA
   - Technology: SQL Server
   - Update Frequency: Weekly
   - Data: Products, categories, pricing

5. SUPPLIER MANAGEMENT SYSTEM
   - Technology: SAP (Files)
   - Update Frequency: Weekly
   - Data: Suppliers, purchase orders, deliveries

6. HR SYSTEM
   - Technology: Workday (API)
   - Update Frequency: Daily
   - Data: Employees, stores, regions
*/

-- Document source systems
CREATE TABLE #SourceSystems (
    SystemID INT IDENTITY(1,1),
    SystemName NVARCHAR(100),
    Technology NVARCHAR(50),
    DataDomain NVARCHAR(100),
    UpdateFrequency NVARCHAR(50),
    IntegrationMethod NVARCHAR(50),
    EstimatedRowsPerDay INT
);

INSERT INTO #SourceSystems VALUES
('North America POS', 'SQL Server 2019', 'Sales Transactions', 'Real-time', 'Database Link', 500000),
('Europe POS', 'Oracle 19c', 'Sales Transactions', 'Real-time', 'Database Link', 300000),
('Asia POS', 'MySQL 8', 'Sales Transactions', 'Real-time', 'Database Link', 400000),
('South America POS', 'SQL Server 2017', 'Sales Transactions', 'Real-time', 'Database Link', 150000),
('Australia POS', 'SQL Server 2019', 'Sales Transactions', 'Real-time', 'Database Link', 100000),
('Inventory Management', 'Oracle', 'Inventory', 'Hourly', 'Database Link', 50000),
('Customer CRM', 'Salesforce', 'Customers', 'Daily', 'REST API', 10000),
('Product Master', 'SQL Server', 'Products', 'Weekly', 'Database Link', 500),
('Supplier Management', 'SAP', 'Suppliers/PO', 'Weekly', 'Flat Files', 1000),
('HR System', 'Workday', 'Employees', 'Daily', 'REST API', 100);

SELECT * FROM #SourceSystems;

/*******************************************************************************
 * PART 3: LOGICAL DATA MODEL
 ******************************************************************************/

/*
=============================================================================
ENTITY RELATIONSHIP DIAGRAM (ERD)
=============================================================================

                              ┌─────────────────┐
                              │    CUSTOMER     │
                              │─────────────────│
                              │ CustomerID (PK) │
                              │ Name            │
                              │ Email           │
                              │ Address         │
                              │ Segment         │
                              └────────┬────────┘
                                       │ 1
                                       │
                                       │ *
┌─────────────┐     ┌─────────────┐    │    ┌─────────────┐
│   REGION    │     │    STORE    │────┼────│    ORDER    │
│─────────────│     │─────────────│         │─────────────│
│ RegionID(PK)│◄────│ RegionID(FK)│         │ OrderID (PK)│
│ RegionName  │     │ StoreID (PK)│◄────────│ StoreID (FK)│
│ Currency    │     │ StoreName   │         │ CustomerID  │
└─────────────┘     │ Manager     │         │ OrderDate   │
                    └─────────────┘         │ TotalAmount │
                          │                 └──────┬──────┘
                          │ 1                      │ 1
                          │                        │
                          │ *                      │ *
                    ┌─────┴─────┐          ┌───────┴───────┐
                    │ INVENTORY │          │  ORDER_ITEM   │
                    │───────────│          │───────────────│
                    │ InvID (PK)│          │ ItemID (PK)   │
                    │ ProductID │          │ OrderID (FK)  │
                    │ StoreID   │          │ ProductID (FK)│
                    │ Quantity  │          │ Quantity      │
                    └───────────┘          │ UnitPrice     │
                          │                └───────┬───────┘
                          │                        │
                          │ *                      │ *
                          └──────────┬─────────────┘
                                     │ 1
                              ┌──────┴──────┐
                              │   PRODUCT   │
                              │─────────────│
                              │ProductID(PK)│
                              │ Name        │
                              │ CategoryID  │
                              │ SupplierID  │
                              │ UnitPrice   │
                              └──────┬──────┘
                                     │ *
                    ┌────────────────┼────────────────┐
                    │ 1              │ 1              │
             ┌──────┴──────┐  ┌──────┴──────┐  ┌──────┴──────┐
             │  CATEGORY   │  │  SUPPLIER   │  │ PRICE_HIST  │
             │─────────────│  │─────────────│  │─────────────│
             │CategoryID   │  │ SupplierID  │  │ PriceHistID │
             │CategoryName │  │ CompanyName │  │ ProductID   │
             │ParentID     │  │ Country     │  │ Price       │
             └─────────────┘  └─────────────┘  │ EffectDate  │
                                               └─────────────┘
*/

-- Document entities and attributes
CREATE TABLE #EntityDefinitions (
    EntityID INT IDENTITY(1,1),
    EntityName NVARCHAR(50),
    AttributeName NVARCHAR(50),
    DataType NVARCHAR(30),
    IsPrimaryKey BIT,
    IsForeignKey BIT,
    RelatedEntity NVARCHAR(50),
    IsRequired BIT,
    Description NVARCHAR(200)
);

INSERT INTO #EntityDefinitions VALUES
-- Customer Entity
('Customer', 'CustomerID', 'INT', 1, 0, NULL, 1, 'Unique customer identifier'),
('Customer', 'FirstName', 'NVARCHAR(50)', 0, 0, NULL, 1, 'Customer first name'),
('Customer', 'LastName', 'NVARCHAR(50)', 0, 0, NULL, 1, 'Customer last name'),
('Customer', 'Email', 'NVARCHAR(100)', 0, 0, NULL, 0, 'Customer email address'),
('Customer', 'Phone', 'NVARCHAR(20)', 0, 0, NULL, 0, 'Customer phone number'),
('Customer', 'Address', 'NVARCHAR(200)', 0, 0, NULL, 0, 'Customer street address'),
('Customer', 'City', 'NVARCHAR(50)', 0, 0, NULL, 0, 'Customer city'),
('Customer', 'Country', 'NVARCHAR(50)', 0, 0, NULL, 0, 'Customer country'),
('Customer', 'Segment', 'NVARCHAR(20)', 0, 0, NULL, 0, 'Customer segment (Gold/Silver/Bronze)'),
('Customer', 'JoinDate', 'DATE', 0, 0, NULL, 1, 'Date customer joined'),

-- Product Entity
('Product', 'ProductID', 'INT', 1, 0, NULL, 1, 'Unique product identifier'),
('Product', 'ProductName', 'NVARCHAR(100)', 0, 0, NULL, 1, 'Product name'),
('Product', 'CategoryID', 'INT', 0, 1, 'Category', 1, 'Product category'),
('Product', 'SupplierID', 'INT', 0, 1, 'Supplier', 1, 'Product supplier'),
('Product', 'UnitPrice', 'DECIMAL(10,2)', 0, 0, NULL, 1, 'Current unit price'),
('Product', 'Cost', 'DECIMAL(10,2)', 0, 0, NULL, 1, 'Product cost'),
('Product', 'SKU', 'NVARCHAR(20)', 0, 0, NULL, 1, 'Stock keeping unit'),
('Product', 'IsActive', 'BIT', 0, 0, NULL, 1, 'Active product flag'),

-- Order Entity
('Order', 'OrderID', 'INT', 1, 0, NULL, 1, 'Unique order identifier'),
('Order', 'CustomerID', 'INT', 0, 1, 'Customer', 1, 'Customer placing order'),
('Order', 'StoreID', 'INT', 0, 1, 'Store', 1, 'Store where order placed'),
('Order', 'OrderDate', 'DATETIME', 0, 0, NULL, 1, 'Date and time of order'),
('Order', 'Status', 'NVARCHAR(20)', 0, 0, NULL, 1, 'Order status'),
('Order', 'TotalAmount', 'DECIMAL(12,2)', 0, 0, NULL, 1, 'Order total amount');

SELECT * FROM #EntityDefinitions ORDER BY EntityName, IsPrimaryKey DESC;

/*******************************************************************************
 * PART 4: DATA WAREHOUSE CONCEPTUAL DESIGN
 ******************************************************************************/

/*
=============================================================================
DIMENSIONAL MODEL - STAR SCHEMA
=============================================================================

                              ┌─────────────────┐
                              │    DimDate      │
                              │─────────────────│
                              │ DateKey (PK)    │
                              │ Date            │
                              │ Year            │
                              │ Quarter         │
                              │ Month           │
                              │ DayOfWeek       │
                              └────────┬────────┘
                                       │
    ┌─────────────────┐               │               ┌─────────────────┐
    │   DimCustomer   │               │               │    DimProduct   │
    │─────────────────│               │               │─────────────────│
    │ CustomerKey(PK) │               │               │ ProductKey (PK) │
    │ CustomerID (NK) │               │               │ ProductID (NK)  │
    │ CustomerName    │               │               │ ProductName     │
    │ Segment         │               │               │ Category        │
    │ Region          │               │               │ SubCategory     │
    └────────┬────────┘               │               └────────┬────────┘
             │                        │                        │
             │    ┌───────────────────┴───────────────────┐   │
             │    │                                       │   │
             └────►            FACT SALES                 ◄───┘
                  │───────────────────────────────────────│
                  │ SalesKey (PK)                         │
                  │ DateKey (FK) ─────────────────────────│──► DimDate
                  │ CustomerKey (FK) ─────────────────────│──► DimCustomer
                  │ ProductKey (FK) ──────────────────────│──► DimProduct
                  │ StoreKey (FK) ────────────────────────│──► DimStore
                  │ PromotionKey (FK) ────────────────────│──► DimPromotion
                  │                                       │
                  │ -- Measures --                        │
                  │ Quantity                              │
                  │ UnitPrice                             │
                  │ SalesAmount                           │
                  │ Cost                                  │
                  │ Profit                                │
                  │ Discount                              │
                  └───────────────────────────────────────┘
                                     │
             ┌───────────────────────┴───────────────────────┐
             │                                               │
    ┌────────┴────────┐                             ┌────────┴────────┐
    │    DimStore     │                             │  DimPromotion   │
    │─────────────────│                             │─────────────────│
    │ StoreKey (PK)   │                             │ PromoKey (PK)   │
    │ StoreID (NK)    │                             │ PromoName       │
    │ StoreName       │                             │ DiscountPct     │
    │ Region          │                             │ StartDate       │
    │ Country         │                             │ EndDate         │
    └─────────────────┘                             └─────────────────┘

NK = Natural Key (Business Key)
PK = Primary Key (Surrogate Key)
FK = Foreign Key
*/

-- Document fact and dimension tables
CREATE TABLE #DimensionalModel (
    TableType NVARCHAR(20),
    TableName NVARCHAR(50),
    ColumnName NVARCHAR(50),
    DataType NVARCHAR(30),
    KeyType NVARCHAR(20),
    Description NVARCHAR(200)
);

INSERT INTO #DimensionalModel VALUES
-- DimDate
('Dimension', 'DimDate', 'DateKey', 'INT', 'PK', 'Surrogate key (YYYYMMDD format)'),
('Dimension', 'DimDate', 'Date', 'DATE', 'NK', 'Actual date'),
('Dimension', 'DimDate', 'Year', 'INT', NULL, 'Calendar year'),
('Dimension', 'DimDate', 'Quarter', 'INT', NULL, 'Calendar quarter (1-4)'),
('Dimension', 'DimDate', 'Month', 'INT', NULL, 'Calendar month (1-12)'),
('Dimension', 'DimDate', 'MonthName', 'NVARCHAR(20)', NULL, 'Month name'),
('Dimension', 'DimDate', 'Week', 'INT', NULL, 'Week of year'),
('Dimension', 'DimDate', 'DayOfWeek', 'INT', NULL, 'Day of week (1-7)'),
('Dimension', 'DimDate', 'DayName', 'NVARCHAR(20)', NULL, 'Day name'),
('Dimension', 'DimDate', 'IsWeekend', 'BIT', NULL, 'Weekend flag'),
('Dimension', 'DimDate', 'IsHoliday', 'BIT', NULL, 'Holiday flag'),

-- DimCustomer (SCD Type 2)
('Dimension', 'DimCustomer', 'CustomerKey', 'INT', 'PK', 'Surrogate key'),
('Dimension', 'DimCustomer', 'CustomerID', 'INT', 'NK', 'Business key from source'),
('Dimension', 'DimCustomer', 'CustomerName', 'NVARCHAR(100)', NULL, 'Full customer name'),
('Dimension', 'DimCustomer', 'Email', 'NVARCHAR(100)', NULL, 'Email address'),
('Dimension', 'DimCustomer', 'City', 'NVARCHAR(50)', NULL, 'City'),
('Dimension', 'DimCustomer', 'State', 'NVARCHAR(50)', NULL, 'State/Province'),
('Dimension', 'DimCustomer', 'Country', 'NVARCHAR(50)', NULL, 'Country'),
('Dimension', 'DimCustomer', 'Region', 'NVARCHAR(50)', NULL, 'Business region'),
('Dimension', 'DimCustomer', 'Segment', 'NVARCHAR(20)', NULL, 'Customer segment'),
('Dimension', 'DimCustomer', 'EffectiveDate', 'DATE', 'SCD2', 'Row effective date'),
('Dimension', 'DimCustomer', 'ExpiryDate', 'DATE', 'SCD2', 'Row expiry date'),
('Dimension', 'DimCustomer', 'IsCurrent', 'BIT', 'SCD2', 'Current record flag'),

-- DimProduct (SCD Type 2)
('Dimension', 'DimProduct', 'ProductKey', 'INT', 'PK', 'Surrogate key'),
('Dimension', 'DimProduct', 'ProductID', 'INT', 'NK', 'Business key from source'),
('Dimension', 'DimProduct', 'ProductName', 'NVARCHAR(100)', NULL, 'Product name'),
('Dimension', 'DimProduct', 'Category', 'NVARCHAR(50)', NULL, 'Product category'),
('Dimension', 'DimProduct', 'SubCategory', 'NVARCHAR(50)', NULL, 'Product subcategory'),
('Dimension', 'DimProduct', 'Brand', 'NVARCHAR(50)', NULL, 'Brand name'),
('Dimension', 'DimProduct', 'Price', 'DECIMAL(10,2)', NULL, 'Current price'),
('Dimension', 'DimProduct', 'Cost', 'DECIMAL(10,2)', NULL, 'Product cost'),
('Dimension', 'DimProduct', 'EffectiveDate', 'DATE', 'SCD2', 'Row effective date'),
('Dimension', 'DimProduct', 'ExpiryDate', 'DATE', 'SCD2', 'Row expiry date'),
('Dimension', 'DimProduct', 'IsCurrent', 'BIT', 'SCD2', 'Current record flag'),

-- FactSales
('Fact', 'FactSales', 'SalesKey', 'BIGINT', 'PK', 'Surrogate key'),
('Fact', 'FactSales', 'DateKey', 'INT', 'FK', 'FK to DimDate'),
('Fact', 'FactSales', 'CustomerKey', 'INT', 'FK', 'FK to DimCustomer'),
('Fact', 'FactSales', 'ProductKey', 'INT', 'FK', 'FK to DimProduct'),
('Fact', 'FactSales', 'StoreKey', 'INT', 'FK', 'FK to DimStore'),
('Fact', 'FactSales', 'PromotionKey', 'INT', 'FK', 'FK to DimPromotion'),
('Fact', 'FactSales', 'OrderID', 'INT', 'DD', 'Degenerate dimension'),
('Fact', 'FactSales', 'LineNumber', 'INT', 'DD', 'Degenerate dimension'),
('Fact', 'FactSales', 'Quantity', 'INT', 'Measure', 'Units sold'),
('Fact', 'FactSales', 'UnitPrice', 'DECIMAL(10,2)', 'Measure', 'Unit selling price'),
('Fact', 'FactSales', 'SalesAmount', 'DECIMAL(12,2)', 'Measure', 'Total sale amount'),
('Fact', 'FactSales', 'Cost', 'DECIMAL(12,2)', 'Measure', 'Total cost'),
('Fact', 'FactSales', 'Profit', 'DECIMAL(12,2)', 'Measure', 'Profit (Sales - Cost)'),
('Fact', 'FactSales', 'Discount', 'DECIMAL(10,2)', 'Measure', 'Discount amount');

SELECT * FROM #DimensionalModel ORDER BY TableType DESC, TableName;

/*******************************************************************************
 * PART 5: ARCHITECTURE DIAGRAM
 ******************************************************************************/

/*
=============================================================================
SOLUTION ARCHITECTURE
=============================================================================

┌─────────────────────────────────────────────────────────────────────────────┐
│                          SOURCE SYSTEMS LAYER                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐     │
│  │ POS NA    │ │ POS EU    │ │ POS ASIA  │ │ POS SA    │ │ POS AU    │     │
│  │ SQL Server│ │ Oracle    │ │ MySQL     │ │ SQL Server│ │ SQL Server│     │
│  └─────┬─────┘ └─────┬─────┘ └─────┬─────┘ └─────┬─────┘ └─────┬─────┘     │
│        │             │             │             │             │            │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐                                  │
│  │ CRM       │ │ Inventory │ │ Product   │                                  │
│  │ Salesforce│ │ Oracle    │ │ Master    │                                  │
│  └─────┬─────┘ └─────┬─────┘ └─────┬─────┘                                  │
│        │             │             │                                         │
└────────┼─────────────┼─────────────┼────────────────────────────────────────┘
         │             │             │
         ▼             ▼             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          ETL LAYER (SSIS)                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                        SSIS ETL Packages                             │    │
│  │  ┌───────────┐    ┌───────────────┐    ┌───────────────────┐        │    │
│  │  │ Extract   │───►│  Staging      │───►│  Transform &      │        │    │
│  │  │ Packages  │    │  Database     │    │  Load Packages    │        │    │
│  │  └───────────┘    └───────────────┘    └───────────────────┘        │    │
│  │                                                                      │    │
│  │  ┌─────────────────────────────────────────────────────────────┐    │    │
│  │  │ Error Handling │ Logging │ Metadata │ Scheduling             │    │    │
│  │  └─────────────────────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                       DATA WAREHOUSE LAYER                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                    SQL Server Data Warehouse                         │    │
│  │                                                                      │    │
│  │  ┌───────────────┐                                                  │    │
│  │  │ Staging Layer │  Raw data landing zone                           │    │
│  │  └───────────────┘                                                  │    │
│  │           │                                                          │    │
│  │           ▼                                                          │    │
│  │  ┌───────────────────────────────────────────────────────────┐      │    │
│  │  │              Star Schema (Presentation Layer)              │      │    │
│  │  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │      │    │
│  │  │  │DimDate  │ │DimCust  │ │DimProd  │ │DimStore │          │      │    │
│  │  │  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘          │      │    │
│  │  │       │           │           │           │                │      │    │
│  │  │       └───────────┴─────┬─────┴───────────┘                │      │    │
│  │  │                         │                                  │      │    │
│  │  │                   ┌─────▼─────┐                            │      │    │
│  │  │                   │ FactSales │                            │      │    │
│  │  │                   └───────────┘                            │      │    │
│  │  └───────────────────────────────────────────────────────────┘      │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        REPORTING LAYER                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         Power BI                                     │    │
│  │                                                                      │    │
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐            │    │
│  │  │ Executive     │  │ Sales         │  │ Operations    │            │    │
│  │  │ Dashboard     │  │ Analysis      │  │ Dashboard     │            │    │
│  │  └───────────────┘  └───────────────┘  └───────────────┘            │    │
│  │                                                                      │    │
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐            │    │
│  │  │ Customer      │  │ Inventory     │  │ Financial     │            │    │
│  │  │ Analytics     │  │ Analysis      │  │ Reports       │            │    │
│  │  └───────────────┘  └───────────────┘  └───────────────┘            │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
*/

/*******************************************************************************
 * PART 6: PROJECT TIMELINE
 ******************************************************************************/

CREATE TABLE #ProjectTimeline (
    PhaseID INT IDENTITY(1,1),
    PhaseName NVARCHAR(100),
    StartWeek INT,
    EndWeek INT,
    Duration NVARCHAR(20),
    Deliverables NVARCHAR(500)
);

INSERT INTO #ProjectTimeline VALUES
('Phase 1: Requirements & Design', 1, 2, '2 weeks', 'Requirements doc, ERD, Architecture diagram'),
('Phase 2: Source System Development', 3, 4, '2 weeks', 'OLTP database, Sample data, Documentation'),
('Phase 3: Data Warehouse Development', 5, 7, '3 weeks', 'Star schema, Dimensions, Fact tables'),
('Phase 4: ETL Development', 8, 11, '4 weeks', 'SSIS packages, Error handling, Scheduling'),
('Phase 5: Reporting Development', 12, 14, '3 weeks', 'Power BI model, Dashboards, RLS'),
('Phase 6: Testing & Deployment', 15, 16, '2 weeks', 'Test results, Deployment scripts, Documentation');

SELECT 
    PhaseName,
    'Week ' + CAST(StartWeek AS VARCHAR) + ' - Week ' + CAST(EndWeek AS VARCHAR) AS Timeline,
    Duration,
    Deliverables
FROM #ProjectTimeline;

/*******************************************************************************
 * PART 7: DELIVERABLES CHECKLIST
 ******************************************************************************/

PRINT '
=============================================================================
LAB 76 DELIVERABLES CHECKLIST
=============================================================================

□ Requirements Document
  □ Business requirements listed and prioritized
  □ Non-functional requirements defined
  □ Success criteria established

□ Source System Documentation
  □ All source systems identified
  □ Data domains documented
  □ Integration methods specified
  □ Update frequencies documented

□ Logical Data Model
  □ Entity relationship diagram
  □ All entities and attributes defined
  □ Relationships documented
  □ Primary and foreign keys identified

□ Dimensional Model Design
  □ Star schema diagram
  □ Fact tables defined with measures
  □ Dimension tables with SCD strategy
  □ Surrogate and natural keys documented

□ Architecture Diagram
  □ All layers documented
  □ Data flow illustrated
  □ Technologies identified
  □ Integration points shown

□ Project Plan
  □ Timeline with milestones
  □ Deliverables per phase
  □ Resource requirements
  □ Risk assessment

Submit these documents before proceeding to Lab 77.
';

/*******************************************************************************
 * LAB EXERCISE
 ******************************************************************************/

/*
EXERCISE: Create Your Design Documents

Based on the templates provided in this lab, create your own versions:

1. REQUIREMENTS DOCUMENT
   - Add 5 additional functional requirements specific to your scenario
   - Add 3 additional non-functional requirements
   - Define acceptance criteria for each

2. SOURCE SYSTEM ANALYSIS
   - If you have access to real systems, document them
   - Otherwise, expand the simulated source systems list
   - Define data quality rules for each source

3. ENTITY RELATIONSHIP DIAGRAM
   - Add at least 2 more entities to the logical model
   - Define all relationships with cardinality
   - Document business rules as comments

4. STAR SCHEMA DESIGN
   - Add DimPromotion dimension (complete design)
   - Add DimStore dimension (complete design)
   - Design a FactInventory fact table

5. ARCHITECTURE ENHANCEMENT
   - Add a data quality layer to the architecture
   - Include a metadata repository component
   - Design an audit trail approach

Submit your completed designs for review before proceeding to the next lab.
*/

-- Cleanup
DROP TABLE IF EXISTS #BusinessRequirements;
DROP TABLE IF EXISTS #SourceSystems;
DROP TABLE IF EXISTS #EntityDefinitions;
DROP TABLE IF EXISTS #DimensionalModel;
DROP TABLE IF EXISTS #ProjectTimeline;

PRINT 'Lab 76 completed. Proceed to Lab 77 for physical database design.';
GO
