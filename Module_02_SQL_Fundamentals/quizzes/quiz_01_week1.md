# Module 02 - Week 1 Quiz

**Duration**: 45 minutes  
**Total Points**: 100 (20 questions × 5 points each)  
**Passing Score**: 70%  

---

## Instructions

- Answer all 20 questions
- Each question is worth 5 points
- No partial credit (all or nothing per question)
- Open book (you may reference course materials)
- Type your SQL answers in the provided spaces
- When complete, check answers in `quiz_01_answers.md`

---

## 📚 Topics Covered

- SELECT basics (Sections 01)
- WHERE clause and filtering (Section 02)
- Sorting and limiting (Section 03)
- Aggregate functions (Section 04)
- GROUP BY and HAVING (Section 05)

---

## Questions

### Question 1 (⭐ Easy) - 5 points
Write a query to show ProductID, Name, and ListPrice for all products. Sort by ListPrice descending.

**Database**: AdventureWorksLT2022  
**Table**: SalesLT.Product

```sql
-- Your answer:




```

---

### Question 2 (⭐ Easy) - 5 points
Select CustomerID, FirstName, and LastName from customers where LastName equals 'Harris'.

```sql
-- Your answer:




```

---

### Question 3 (⭐⭐ Medium) - 5 points
Write a query to count the total number of products in the Product table.

```sql
-- Your answer:




```

---

### Question 4 (⭐⭐ Medium) - 5 points
Show all products where Color is 'Red' AND ListPrice is greater than $100. Include ProductID, Name, Color, and ListPrice.

```sql
-- Your answer:




```

---

### Question 5 (⭐⭐ Medium) - 5 points
Retrieve products where the Name contains the word 'Bike' (anywhere in the name). Sort by Name alphabetically.

```sql
-- Your answer:




```

---

### Question 6 (⭐⭐ Medium) - 5 points
Calculate the average ListPrice of all products. Round to 2 decimal places and alias as 'AveragePrice'.

```sql
-- Your answer:




```

---

### Question 7 (⭐⭐⭐ Hard) - 5 points
Find products where ListPrice is between $500 and $1000 (inclusive) AND Color is NOT NULL. Show ProductID, Name, Color, and ListPrice.

```sql
-- Your answer:




```

---

### Question 8 (⭐⭐⭐ Hard) - 5 points
Show the top 10 most expensive products. Include ProductID, Name, and ListPrice. Use TOP clause.

```sql
-- Your answer:




```

---

### Question 9 (⭐⭐⭐ Hard) - 5 points
Count how many products exist for each Color. Exclude NULLs. Show Color and ProductCount. Sort by ProductCount descending.

```sql
-- Your answer:




```

---

### Question 10 (⭐⭐⭐ Hard) - 5 points
Find all unique product colors (no duplicates). Exclude NULL values. Sort alphabetically.

```sql
-- Your answer:




```

---

### Question 11 (⭐⭐⭐ Hard) - 5 points
What does this query return?
```sql
SELECT COUNT(*) FROM SalesLT.Product WHERE Color IS NULL;
```

**A)** Number of products with color specified  
**B)** Number of products without color (NULL)  
**C)** Total number of products  
**D)** Error - invalid syntax  

**Your answer**: ______

---

### Question 12 (⭐⭐⭐⭐ Hard) - 5 points
Write a query to show MIN, MAX, and AVG of ListPrice for products. Label columns as MinPrice, MaxPrice, AvgPrice.

```sql
-- Your answer:




```

---

### Question 13 (⭐⭐⭐⭐ Hard) - 5 points
Find customers with email addresses ending in '@adventure-works.com'. Show CustomerID, FirstName, LastName, and EmailAddress.

```sql
-- Your answer:




```

---

### Question 14 (⭐⭐⭐⭐ Hard) - 5 points
Calculate total revenue from all orders (sum of TotalDue from SalesOrderHeader). Alias as 'TotalRevenue'.

```sql
-- Your answer:




```

---

### Question 15 (⭐⭐⭐⭐ Hard) - 5 points
Show CustomerID and count of orders for each customer. Only include customers with more than 1 order. Sort by order count descending.

```sql
-- Your answer:




```

---

### Question 16 (⭐⭐⭐⭐⭐ Expert) - 5 points
What's the difference between these two queries?

**Query A:**
```sql
SELECT COUNT(*) FROM SalesLT.Product;
```

**Query B:**
```sql
SELECT COUNT(Color) FROM SalesLT.Product;
```

**Your explanation:**
_______________________________________________
_______________________________________________
_______________________________________________

---

### Question 17 (⭐⭐⭐⭐⭐ Expert) - 5 points
Write a query to find products where Name starts with 'Mountain' AND (Color is 'Black' OR Color is 'Silver'). Show ProductID, Name, Color.

```sql
-- Your answer:




```

---

### Question 18 (⭐⭐⭐⭐⭐ Expert) - 5 points
Show total number of orders and total revenue grouped by YEAR of OrderDate. Columns: OrderYear, TotalOrders, TotalRevenue.

```sql
-- Your answer:




```

---

### Question 19 (⭐⭐⭐⭐⭐ Expert) - 5 points
Find the 2nd most expensive product (not including ties). Show ProductID, Name, and ListPrice. Use OFFSET/FETCH.

```sql
-- Your answer:




```

---

### Question 20 (⭐⭐⭐⭐⭐ Expert) - 5 points
What will this query return?

```sql
SELECT Color, COUNT(*) AS ProductCount
FROM SalesLT.Product
GROUP BY Color
HAVING COUNT(*) > 20
ORDER BY ProductCount DESC;
```

**A)** All product colors with their counts  
**B)** Colors with more than 20 products, sorted by count  
**C)** Colors with exactly 20 products  
**D)** Error - HAVING without aggregate function  

**Your answer**: ______

---

## Submission

1. Save your completed quiz
2. Check your answers against `quiz_01_answers.md`
3. Calculate your score: ______ / 100
4. **Pass**: 70+ (proceed to Week 2)
5. **Below 70**: Review sections and retake

---

## Score Interpretation

- **90-100**: Excellent! Strong SQL foundation
- **80-89**: Good! Minor review recommended
- **70-79**: Pass. Review weak areas before Week 2
- **Below 70**: Review Sections 01-05 and retake quiz

---

*Next: Week 2 Quiz (Sections 06-10)*
