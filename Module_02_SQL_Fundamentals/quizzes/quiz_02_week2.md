# Module 02 - Week 2 Quiz

**Duration**: 60 minutes  
**Total Points**: 100 (20 questions × 5 points each)  
**Passing Score**: 70%  

---

## Instructions

- Answer all 20 questions
- Each question is worth 5 points
- Open book (you may reference course materials)
- Type your SQL answers in the provided spaces
- When complete, check answers in `quiz_02_answers.md`

---

## 📚 Topics Covered

- JOINs (Section 06)
- Subqueries (Section 07)
- String & Date Functions (Section 08)
- CASE Expressions (Section 09)

---

## Questions

### Question 1 (⭐⭐ Medium) - 5 points
Write an INNER JOIN to show Customer names with their order totals. Include: CustomerID, CustomerName (FirstName + LastName), SalesOrderID, TotalDue.

**Tables**: Customer, SalesOrderHeader

```sql
-- Your answer:




```

---

### Question 2 (⭐⭐⭐ Hard) - 5 points
Find customers who have NEVER placed an order. Use LEFT JOIN. Show CustomerID, FirstName, LastName.

```sql
-- Your answer:




```

---

### Question 3 (⭐⭐⭐ Hard) - 5 points
Join Orders with OrderDetails and Products (3 tables). Show: SalesOrderID, ProductName, OrderQty, UnitPrice, LineTotal.

```sql
-- Your answer:




```

---

### Question 4 (⭐⭐⭐ Hard) - 5 points
What's the difference between INNER JOIN and LEFT JOIN?

**Your explanation:**
_______________________________________________
_______________________________________________
_______________________________________________

---

### Question 5 (⭐⭐⭐ Hard) - 5 points
Write a query using a subquery to find products with ListPrice greater than the average ListPrice.

```sql
-- Your answer:




```

---

### Question 6 (⭐⭐⭐⭐ Hard) - 5 points
Extract the domain from email addresses (everything after @). Show: EmailAddress, Domain. Use SUBSTRING and CHARINDEX.

```sql
-- Your answer:




```

---

### Question 7 (⭐⭐⭐⭐ Hard) - 5 points
Calculate days between OrderDate and today for each order. Show: SalesOrderID, OrderDate, DaysSinceOrder. Use DATEDIFF and GETDATE().

```sql
-- Your answer:




```

---

### Question 8 (⭐⭐⭐⭐ Hard) - 5 points
Use CASE to categorize products by price:
- 'Budget' if < $100
- 'Mid-Range' if $100-$500
- 'Premium' if > $500

Show: ProductID, Name, ListPrice, PriceCategory

```sql
-- Your answer:




```

---

### Question 9 (⭐⭐⭐⭐ Hard) - 5 points
Find customers whose CustomerID is IN the list of customers who placed orders. Use IN with subquery.

```sql
-- Your answer:




```

---

### Question 10 (⭐⭐⭐⭐ Hard) - 5 points
What does this query return?

```sql
SELECT c.CustomerID, c.FirstName
FROM SalesLT.Customer c
WHERE EXISTS (
    SELECT 1 FROM SalesLT.SalesOrderHeader soh
    WHERE soh.CustomerID = c.CustomerID
);
```

**A)** All customers  
**B)** Customers with orders  
**C)** Customers without orders  
**D)** Syntax error  

**Your answer**: ______

---

### Question 11 (⭐⭐⭐⭐⭐ Expert) - 5 points
Find products that were NEVER sold. Use LEFT JOIN between Product and SalesOrderDetail. Show: ProductID, Name, ListPrice.

```sql
-- Your answer:




```

---

### Question 12 (⭐⭐⭐⭐⭐ Expert) - 5 points
Convert all product names to uppercase. Show: ProductID, Name, UppercaseName. Use UPPER().

```sql
-- Your answer:




```

---

### Question 13 (⭐⭐⭐⭐⭐ Expert) - 5 points
Get the YEAR and MONTH name from OrderDate. Show: SalesOrderID, OrderDate, OrderYear, OrderMonth. Use YEAR() and DATENAME().

```sql
-- Your answer:




```

---

### Question 14 (⭐⭐⭐⭐⭐ Expert) - 5 points
Explain what a correlated subquery is and when you'd use it.

**Your explanation:**
_______________________________________________
_______________________________________________
_______________________________________________

---

### Question 15 (⭐⭐⭐⭐⭐ Expert) - 5 points
Use CASE to label customers:
- 'Active' if they placed an order in last 180 days
- 'Inactive' otherwise

Show: CustomerID, CustomerName, Status (use GROUP BY and MAX(OrderDate))

```sql
-- Your answer:




```

---

### Question 16 (⭐⭐⭐⭐⭐ Expert) - 5 points
Write a query to find the 3 most recent orders using TOP. Show: SalesOrderID, OrderDate, TotalDue.

```sql
-- Your answer:




```

---

### Question 17 (⭐⭐⭐⭐⭐ Expert) - 5 points
What's the difference between WHERE and HAVING?

**Your explanation:**
_______________________________________________
_______________________________________________
_______________________________________________

---

### Question 18 (⭐⭐⭐⭐⭐ Expert) - 5 points
Find products where Name contains 'Mountain' AND Color is NOT NULL. Show: ProductID, Name, Color. Use LIKE and IS NOT NULL.

```sql
-- Your answer:




```

---

### Question 19 (⭐⭐⭐⭐⭐ Expert) - 5 points
Join Customer, SalesOrderHeader, SalesOrderDetail, and Product (4 tables). Calculate total quantity sold per customer. Show: CustomerID, CustomerName, TotalQuantityPurchased.

```sql
-- Your answer:




```

---

### Question 20 (⭐⭐⭐⭐⭐ Expert) - 5 points
Use IIF() to create a column showing 'Expensive' if ListPrice > 1000, else 'Affordable'. Show: ProductID, Name, ListPrice, PriceLabel.

```sql
-- Your answer:




```

---

## Submission

1. Save your completed quiz
2. Check your answers against `quiz_02_answers.md`
3. Calculate your score: ______ / 100
4. **Pass**: 70+ (proceed to Module 03)
5. **Below 70**: Review sections and retake

---

## Score Interpretation

- **90-100**: Excellent! Ready for advanced SQL
- **80-89**: Good! Solid understanding
- **70-79**: Pass. Review weak topics before Module 03
- **Below 70**: Review Sections 06-10 and retake quiz

---

## Module 02 Completion

If you passed both quizzes (Week 1 + Week 2) with 70% or higher:

✅ **Congratulations!** You've completed Module 02: SQL Fundamentals

**Next Steps**:
1. Complete Practice Project (Lab 10) if not done
2. Review any weak areas
3. **Start Module 03: Advanced SQL** (CTEs, Window Functions, Query Optimization)

---

*கற்க கசடற - Learn Flawlessly! 🎉*
