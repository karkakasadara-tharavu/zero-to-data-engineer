/*
================================================================================
LAB 31 (ENHANCED): DATABASE INDEXING - COMPLETE GUIDE
Module 04: Database Administration
================================================================================

WHAT YOU WILL LEARN:
✅ What indexes are and how they work internally
✅ Clustered vs Non-Clustered indexes explained
✅ When to create indexes (and when NOT to)
✅ Index design strategies
✅ Covering indexes and included columns
✅ Index maintenance and fragmentation
✅ Reading execution plans
✅ Interview preparation

DURATION: 2-3 hours
DIFFICULTY: ⭐⭐⭐⭐ (Advanced)
DATABASE: AdventureWorks2022

================================================================================
SECTION 1: UNDERSTANDING INDEXES - THE FUNDAMENTALS
================================================================================

WHAT IS AN INDEX?
-----------------
An index is a DATA STRUCTURE that improves the speed of data retrieval.
Think of it like a book index - instead of reading every page to find a topic,
you look up the topic in the index and go directly to that page.

WITHOUT INDEX:  Table Scan - read EVERY row (slow for large tables)
WITH INDEX:     Index Seek - go directly to matching rows (fast!)

HOW INDEXES WORK INTERNALLY:
----------------------------
Indexes use a B-TREE (Balanced Tree) structure:

                    ┌─────────────┐
                    │  Root Node  │
                    │   M         │
                    └─────┬───────┘
              ┌───────────┴───────────┐
              ▼                       ▼
        ┌─────────┐             ┌─────────┐
        │ A - L   │             │ N - Z   │
        └────┬────┘             └────┬────┘
    ┌────────┴────────┐    ┌────────┴────────┐
    ▼        ▼        ▼    ▼        ▼        ▼
┌──────┐ ┌──────┐ ┌──────┐┌──────┐ ┌──────┐ ┌──────┐
│A-C   │ │D-F   │ │G-L   ││N-P   │ │Q-T   │ │U-Z   │
│Data →│ │Data →│ │Data →││Data →│ │Data →│ │Data →│
└──────┘ └──────┘ └──────┘└──────┘ └──────┘ └──────┘

SEARCH EXAMPLE: Find "Jones"
1. Root: J comes after M? No → go LEFT
2. Branch: J in G-L range → go to G-L leaf
3. Leaf: Find "Jones" in sorted list → Get row location
4. Retrieve the actual data

COMPARISON:
Without index: Check 1,000,000 rows → O(n)
With index: Check ~20 nodes → O(log n)

THE TWO MAIN INDEX TYPES:
-------------------------
1. CLUSTERED INDEX: 
   - Determines the PHYSICAL ORDER of data in the table
   - Only ONE per table (data can only be sorted one way)
   - The leaf nodes ARE the actual data rows
   - Usually created on PRIMARY KEY

2. NON-CLUSTERED INDEX:
   - Separate structure pointing to the data
   - Can have MANY per table (up to 999)
   - Leaf nodes contain pointers (row locators)
   - Like a book index pointing to page numbers
*/

USE AdventureWorks2022;
GO

-- ============================================================================
-- SECTION 2: CLUSTERED INDEXES
-- ============================================================================
/*
CLUSTERED INDEX = The Table Itself (Sorted)

When you create a clustered index:
- The table data is PHYSICALLY REORDERED
- Row are stored in the index order
- The leaf level of the B-tree IS the data

RULES:
- Only ONE clustered index per table
- Primary key creates clustered index by default
- Choose wisely - it's the foundation of your table!

BEST CANDIDATES FOR CLUSTERED INDEX:
✓ Primary key (usually auto-increment)
✓ Frequently used in range queries (dates)
✓ Narrow (small data type)
✓ Unique or mostly unique
✓ Static (doesn't change often)
*/

-- Create a demo table
IF OBJECT_ID('dbo.IndexDemo', 'U') IS NOT NULL DROP TABLE dbo.IndexDemo;

CREATE TABLE dbo.IndexDemo (
    ID INT IDENTITY(1,1),
    CustomerName NVARCHAR(100),
    Email NVARCHAR(200),
    City NVARCHAR(50),
    OrderDate DATE,
    Amount DECIMAL(10,2),
    Category NVARCHAR(50)
);

-- Insert sample data
INSERT INTO dbo.IndexDemo (CustomerName, Email, City, OrderDate, Amount, Category)
SELECT TOP 100000
    'Customer ' + CAST(ABS(CHECKSUM(NEWID())) % 10000 AS VARCHAR),
    'cust' + CAST(ABS(CHECKSUM(NEWID())) % 10000 AS VARCHAR) + '@email.com',
    CASE ABS(CHECKSUM(NEWID())) % 5 
        WHEN 0 THEN 'New York'
        WHEN 1 THEN 'Chicago'
        WHEN 2 THEN 'Los Angeles'
        WHEN 3 THEN 'Houston'
        ELSE 'Phoenix'
    END,
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 1000, GETDATE()),
    CAST(ABS(CHECKSUM(NEWID())) % 10000 AS DECIMAL(10,2)),
    CASE ABS(CHECKSUM(NEWID())) % 4
        WHEN 0 THEN 'Electronics'
        WHEN 1 THEN 'Clothing'
        WHEN 2 THEN 'Food'
        ELSE 'Books'
    END
FROM sys.all_objects a CROSS JOIN sys.all_objects b;

PRINT 'Created table with 100,000 rows';

-- Check current state: No clustered index = HEAP
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    index_id,
    type_desc,
    name AS IndexName
FROM sys.indexes
WHERE object_id = OBJECT_ID('dbo.IndexDemo');

-- Query WITHOUT clustered index (TABLE SCAN)
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT * FROM dbo.IndexDemo WHERE ID = 50000;

-- Create clustered index on ID
CREATE CLUSTERED INDEX CIX_IndexDemo_ID ON dbo.IndexDemo(ID);
PRINT 'Created CLUSTERED index on ID';

-- Same query WITH clustered index (INDEX SEEK)
SELECT * FROM dbo.IndexDemo WHERE ID = 50000;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

/*
OBSERVE THE DIFFERENCE:
- Without index: Table Scan (reads ALL pages)
- With index: Clustered Index Seek (reads few pages)

Check the "logical reads" - should be much lower with index!
*/

-- ============================================================================
-- SECTION 3: NON-CLUSTERED INDEXES
-- ============================================================================
/*
NON-CLUSTERED INDEX = Separate Lookup Structure

Structure:
┌───────────────────────────────┐
│     Non-Clustered Index       │
│  ┌─────────────────────────┐  │
│  │ Index Key + Row Locator │  │
│  │ "Chicago" → Row 5       │  │
│  │ "Houston" → Row 12      │  │
│  │ "New York" → Row 3      │  │
│  └─────────────────────────┘  │
└───────────────────────────────┘
              │
              │ Lookup (Key Lookup/RID Lookup)
              ▼
┌───────────────────────────────┐
│      Clustered Index/Heap     │
│  (Actual Table Data)          │
└───────────────────────────────┘

ROW LOCATOR:
- If table has clustered index: Locator = Clustering Key
- If table is a heap: Locator = RID (Row ID)
*/

-- Query on City WITHOUT non-clustered index
SET STATISTICS IO ON;

SELECT * FROM dbo.IndexDemo WHERE City = 'Chicago';

-- Create non-clustered index on City
CREATE NONCLUSTERED INDEX IX_IndexDemo_City ON dbo.IndexDemo(City);
PRINT 'Created NON-CLUSTERED index on City';

-- Same query WITH non-clustered index
SELECT * FROM dbo.IndexDemo WHERE City = 'Chicago';

SET STATISTICS IO OFF;

/*
What happened?
The query now uses:
1. Index Seek on IX_IndexDemo_City (find Chicago rows)
2. Key Lookup on clustered index (get remaining columns)

Key Lookup is expensive! Solution: Covering Index (next section)
*/

-- ============================================================================
-- SECTION 4: COVERING INDEXES AND INCLUDED COLUMNS
-- ============================================================================
/*
COVERING INDEX: An index that contains ALL columns needed by a query.
No need to go back to the table (no Key Lookup)!

Two ways to create covering indexes:

1. Add columns to the index key:
   CREATE INDEX IX_Name ON Table(Col1, Col2, Col3);
   - Columns are sorted and in the B-tree structure
   - Good for columns in WHERE, ORDER BY, GROUP BY

2. Use INCLUDE clause:
   CREATE INDEX IX_Name ON Table(Col1) INCLUDE (Col2, Col3);
   - Included columns stored at leaf level only (not sorted)
   - Good for columns only in SELECT (not filtering)
   - Smaller index size (not in non-leaf nodes)

INCLUDE is better when:
- Column is only needed for output (not filtering)
- Column is wide (strings, etc.)
- You want to reduce index size
*/

-- Query that needs multiple columns
SELECT CustomerName, Email, Amount 
FROM dbo.IndexDemo 
WHERE City = 'New York';

-- Without covering index: Index Seek + Key Lookup
-- Check execution plan - you'll see Key Lookup

-- Create covering index with INCLUDE
CREATE NONCLUSTERED INDEX IX_IndexDemo_City_Covering 
ON dbo.IndexDemo(City) 
INCLUDE (CustomerName, Email, Amount);

PRINT 'Created COVERING index with INCLUDE columns';

-- Same query now - NO Key Lookup!
SELECT CustomerName, Email, Amount 
FROM dbo.IndexDemo 
WHERE City = 'New York';

-- Check execution plan - should be Index Seek only!

-- ============================================================================
-- SECTION 5: COMPOSITE INDEXES (MULTI-COLUMN)
-- ============================================================================
/*
COMPOSITE INDEX: Index on multiple columns.

COLUMN ORDER MATTERS!
Index on (A, B, C) can be used for:
✓ WHERE A = ?
✓ WHERE A = ? AND B = ?
✓ WHERE A = ? AND B = ? AND C = ?
✗ WHERE B = ?          (A must be first!)
✗ WHERE C = ?
✗ WHERE B = ? AND C = ?

Think of it like a phone book:
- Sorted by: LastName, FirstName, MiddleName
- Can search: LastName
- Can search: LastName, FirstName
- CANNOT efficiently search: FirstName alone

RULE: Most selective column FIRST (for equality conditions)
      Range columns LAST
*/

-- Query filtering on multiple columns
SELECT * FROM dbo.IndexDemo 
WHERE City = 'Chicago' AND Category = 'Electronics' AND OrderDate > '2024-01-01';

-- Create composite index
CREATE NONCLUSTERED INDEX IX_IndexDemo_City_Category_Date
ON dbo.IndexDemo(City, Category, OrderDate);

PRINT 'Created COMPOSITE index on (City, Category, OrderDate)';

-- Query will use the composite index efficiently

-- But this query WON'T use the index efficiently:
SELECT * FROM dbo.IndexDemo WHERE Category = 'Electronics';
-- Because City (the first column) is not in the WHERE clause!

-- ============================================================================
-- SECTION 6: INDEX FRAGMENTATION AND MAINTENANCE
-- ============================================================================
/*
WHAT IS FRAGMENTATION?
----------------------
Over time, as data is inserted, updated, and deleted, indexes become 
FRAGMENTED - the logical order no longer matches physical order.

Two types:
1. INTERNAL FRAGMENTATION: Pages are not full (wasted space)
2. EXTERNAL FRAGMENTATION: Pages are out of order (slow scans)

Fragmentation % | Action
----------------|--------
< 5%            | No action needed
5% - 30%        | REORGANIZE (online, lightweight)
> 30%           | REBUILD (more thorough, can be offline)
*/

-- Check fragmentation levels
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.index_type_desc,
    ips.avg_fragmentation_in_percent,
    ips.page_count,
    ips.avg_page_space_used_in_percent,
    CASE 
        WHEN ips.avg_fragmentation_in_percent < 5 THEN 'OK'
        WHEN ips.avg_fragmentation_in_percent < 30 THEN 'REORGANIZE'
        ELSE 'REBUILD'
    END AS RecommendedAction
FROM sys.dm_db_index_physical_stats(
    DB_ID(), 
    OBJECT_ID('dbo.IndexDemo'), 
    NULL, 
    NULL, 
    'LIMITED'
) ips
JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.page_count > 0
ORDER BY ips.avg_fragmentation_in_percent DESC;

-- REORGANIZE: Defragment the leaf level (online operation)
ALTER INDEX IX_IndexDemo_City ON dbo.IndexDemo REORGANIZE;
PRINT 'Index reorganized';

-- REBUILD: Completely recreate the index
ALTER INDEX IX_IndexDemo_City ON dbo.IndexDemo REBUILD;
PRINT 'Index rebuilt';

-- REBUILD ALL indexes on a table
ALTER INDEX ALL ON dbo.IndexDemo REBUILD;
PRINT 'All indexes rebuilt';

-- ============================================================================
-- SECTION 7: READING EXECUTION PLANS
-- ============================================================================
/*
EXECUTION PLAN OPERATORS TO KNOW:

GOOD (Index is being used):
✓ Index Seek      - Direct lookup using index (best!)
✓ Index Scan      - Reading index in order (ok for ranges)
✓ Clustered Index Seek - Direct lookup on clustered index

BAD (Missing or poor index):
✗ Table Scan      - Reading entire heap (no clustered index)
✗ Clustered Index Scan - Reading entire table
✗ Key Lookup      - Going back to table for missing columns
✗ RID Lookup      - Going back to heap for missing columns

WARNING SIGNS:
⚠ High cost percentage on one operator
⚠ Thick arrows (many rows flowing)
⚠ Yellow exclamation mark (missing index warning)
⚠ Parallelism when not expected
*/

-- Enable execution plan
SET SHOWPLAN_TEXT ON;
GO

-- See the plan for this query
SELECT * FROM dbo.IndexDemo WHERE City = 'Chicago';
GO

SET SHOWPLAN_TEXT OFF;
GO

-- Or use graphical plan: Ctrl+L in SSMS

-- ============================================================================
-- SECTION 8: FILTERED INDEXES
-- ============================================================================
/*
FILTERED INDEX: Index on a SUBSET of rows.

Benefits:
- Smaller index size
- Better performance for specific queries
- Less maintenance overhead

Use cases:
- Active records only (WHERE IsActive = 1)
- Recent data (WHERE Date > '2024-01-01')
- Non-null values (WHERE Column IS NOT NULL)
*/

-- Create filtered index for only "Electronics" category
CREATE NONCLUSTERED INDEX IX_IndexDemo_Electronics
ON dbo.IndexDemo(City, OrderDate)
WHERE Category = 'Electronics';

PRINT 'Created FILTERED index for Electronics only';

-- This query will use the filtered index
SELECT * FROM dbo.IndexDemo 
WHERE Category = 'Electronics' AND City = 'Chicago';

-- ============================================================================
-- SECTION 9: INDEX DESIGN GUIDELINES
-- ============================================================================
/*
WHEN TO CREATE INDEXES:
-----------------------
✓ Primary keys (automatic)
✓ Foreign keys (not automatic - CREATE THEM!)
✓ Columns in WHERE clauses
✓ Columns in JOIN conditions
✓ Columns in ORDER BY
✓ Columns in GROUP BY
✓ High selectivity columns (many unique values)

WHEN NOT TO CREATE INDEXES:
---------------------------
✗ Small tables (< 1000 rows)
✗ Low selectivity (few unique values - e.g., Gender)
✗ Frequently updated columns
✗ Tables with heavy INSERT/UPDATE/DELETE
✗ Wide columns (long strings)
✗ Already have too many indexes

INDEX OVERHEAD:
---------------
Every index has a cost:
- Storage space
- Slower INSERT/UPDATE/DELETE (must update index too)
- Maintenance overhead

Rule of thumb: 
- OLTP (many writes): 5-10 indexes max
- OLAP (mostly reads): More indexes are OK

MISSING INDEX DMV:
------------------
SQL Server tracks potentially helpful indexes:
*/

SELECT TOP 10
    mig.index_group_handle,
    mid.statement AS TableName,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns,
    migs.unique_compiles,
    migs.user_seeks,
    migs.avg_user_impact,
    'CREATE INDEX IX_Missing_' + CAST(mig.index_group_handle AS VARCHAR) + 
    ' ON ' + mid.statement + 
    ' (' + ISNULL(mid.equality_columns, '') + 
    CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL 
         THEN ', ' ELSE '' END +
    ISNULL(mid.inequality_columns, '') + ')' +
    CASE WHEN mid.included_columns IS NOT NULL 
         THEN ' INCLUDE (' + mid.included_columns + ')' ELSE '' END AS CreateStatement
FROM sys.dm_db_missing_index_groups mig
JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE mid.database_id = DB_ID()
ORDER BY migs.avg_user_impact * migs.user_seeks DESC;

-- ============================================================================
-- SECTION 10: INTERVIEW QUESTIONS AND ANSWERS
-- ============================================================================
/*
================================================================================
INTERVIEW FOCUS: DATABASE INDEXING - Top 20 Questions
================================================================================

Q1: What is an index and why is it important?
A1: An index is a data structure (B-tree) that improves query performance by 
    allowing the database to find rows without scanning the entire table.
    Like a book index - go directly to the page instead of reading everything.

Q2: What's the difference between clustered and non-clustered indexes?
A2: 
    CLUSTERED:
    - Determines physical order of data
    - Only ONE per table
    - Leaf nodes ARE the data
    - Usually on primary key
    
    NON-CLUSTERED:
    - Separate structure with pointers
    - Many per table (up to 999)
    - Leaf nodes contain row locators
    - Need to follow pointer to get data

Q3: What happens when you create a primary key?
A3: By default, SQL Server creates a CLUSTERED index on the primary key.
    You can override this with NONCLUSTERED keyword.

Q4: What is a covering index?
A4: An index that contains ALL columns needed by a query, eliminating 
    the need for Key Lookup. Use INCLUDE clause for non-filtering columns.

Q5: What is Key Lookup and how do you eliminate it?
A5: Key Lookup occurs when a non-clustered index doesn't have all needed 
    columns, so it must go back to the clustered index/heap.
    Solution: Create a covering index with INCLUDE clause.

Q6: Explain composite index column order.
A6: Order matters! Index on (A, B, C) works for:
    - WHERE A = ?
    - WHERE A = ? AND B = ?
    - WHERE A = ? AND B = ? AND C = ?
    But NOT for WHERE B = ? alone (leftmost column must be present).

Q7: What is index fragmentation?
A7: Fragmentation occurs when logical order doesn't match physical order.
    - Internal: Pages not full (wasted space)
    - External: Pages out of order (slow sequential reads)
    Fix with: REORGANIZE (< 30%) or REBUILD (> 30%)

Q8: What's the difference between REORGANIZE and REBUILD?
A8: 
    REORGANIZE: 
    - Defragments leaf level only
    - Always online
    - Less resource intensive
    
    REBUILD:
    - Creates new index structure
    - Can be offline (unless ONLINE=ON)
    - More thorough

Q9: What is a filtered index?
A9: An index with a WHERE clause that indexes only a subset of rows.
    Benefits: Smaller size, better performance for specific queries.
    Example: WHERE IsActive = 1

Q10: What are included columns (INCLUDE clause)?
A10: Columns stored at leaf level only (not in non-leaf nodes).
     Benefits: Cover queries without bloating the index key.
     Use for columns needed in SELECT but not in WHERE/ORDER BY.

Q11: How do you identify missing indexes?
A11: Query sys.dm_db_missing_index_* DMVs.
     SQL Server tracks queries that could benefit from indexes.
     Also: Check execution plans for missing index suggestions.

Q12: What are the downsides of too many indexes?
A12: 
     - Slower INSERT/UPDATE/DELETE (must update all indexes)
     - Storage space
     - Maintenance overhead
     - More choices for optimizer (can pick wrong one)

Q13: Should you index foreign keys?
A13: YES! SQL Server does NOT automatically index foreign keys.
     They should be indexed because:
     - JOIN operations use them
     - Cascade deletes need to find child rows

Q14: What is a heap and when would you use one?
A14: A heap is a table without a clustered index (data unordered).
     Use cases:
     - Staging tables (load then process)
     - Heavily insert-only tables
     Usually: Most tables should have a clustered index.

Q15: How do you read an execution plan?
A15: 
     - Read right-to-left (data flows right to left)
     - Look for: Index Seek (good), Table Scan (bad)
     - Check arrow thickness (row counts)
     - Look for warnings (yellow icons)
     - Check cost percentages

Q16: What is index selectivity?
A16: Selectivity = unique values / total rows
     High selectivity (many unique values) = good for indexing
     Low selectivity (few unique values) = bad for indexing
     Example: Email (high) vs Gender (low)

Q17: Can you have a non-clustered index on a heap?
A17: Yes! The row locator will be RID (Row ID) instead of 
     clustering key. RID Lookups are slightly faster than Key Lookups.

Q18: What is an index scan vs index seek?
A18: 
     SEEK: Direct lookup using the index structure (efficient)
     SCAN: Reading all/most of the index in order (less efficient)
     
     Seek requires an equality or range condition on the leading column.

Q19: How do statistics relate to indexes?
A19: Statistics describe data distribution in columns.
     - Created automatically on indexed columns
     - Help optimizer choose best execution plan
     - Should be kept up-to-date (UPDATE STATISTICS)

Q20: What is a columnstore index?
A20: Columnstore stores data by column instead of row.
     Benefits:
     - Excellent compression
     - Fast aggregation queries
     - Great for data warehouse workloads
     Not good for: OLTP with many single-row operations.

================================================================================
*/

-- ============================================================================
-- CLEANUP
-- ============================================================================

-- View all indexes on our demo table
SELECT 
    i.name AS IndexName,
    i.type_desc,
    i.is_primary_key,
    i.is_unique,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS KeyColumns,
    STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN c.name END, ', ') AS IncludedColumns
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('dbo.IndexDemo')
GROUP BY i.name, i.type_desc, i.is_primary_key, i.is_unique
ORDER BY i.type_desc, i.name;

-- Drop demo table when done
-- DROP TABLE dbo.IndexDemo;

/*
================================================================================
LAB COMPLETION CHECKLIST
================================================================================
□ Understand what indexes are and how B-trees work
□ Know the difference between clustered and non-clustered indexes
□ Can create covering indexes with INCLUDE clause
□ Understand composite index column ordering
□ Can check and fix index fragmentation
□ Can read execution plans to identify index issues
□ Know when to index and when not to
□ Can answer interview questions confidently
□ Practice with real database queries

NEXT LAB: Lab 32 - Monitoring and Performance Tuning
================================================================================
*/
