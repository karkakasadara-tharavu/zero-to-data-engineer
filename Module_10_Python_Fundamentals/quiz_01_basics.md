# Module 10 - Quiz 01: Python Basics
## Sections 1-7: Setup through Conditionals

**கற்க கசடற** - Learn Flawlessly

**Time Limit**: 30 minutes  
**Passing Score**: 70% (14/20 correct)  
**Instructions**: Choose the best answer for each question.

---

### Section 1-3: Python Setup, Variables, Lists

**1. Which is the recommended way to install Python on Windows?**
- a) From python.org
- b) Microsoft Store
- c) Anaconda
- d) All are acceptable

**Answer**: d) All are acceptable (but Microsoft Store is easiest for beginners)

---

**2. What is the output of: `type(5.0)`**
- a) `<class 'int'>`
- b) `<class 'float'>`
- c) `<class 'number'>`
- d) `5.0`

**Answer**: b) `<class 'float'>`

---

**3. Which variable name is INVALID in Python?**
- a) `my_variable`
- b) `_private`
- c) `2ndPlace`
- d) `firstName`

**Answer**: c) `2ndPlace` (cannot start with a digit)

---

**4. What is the output of: `[1, 2, 3][1:3]`**
- a) `[1, 2]`
- b) `[2, 3]`
- c) `[1, 2, 3]`
- d) `[2]`

**Answer**: b) `[2, 3]` (indices 1 and 2, not including 3)

---

**5. Which method adds an item to the END of a list?**
- a) `add()`
- b) `append()`
- c) `insert()`
- d) `extend()`

**Answer**: b) `append()`

---

### Section 4-5: Tuples, Dictionaries

**6. What makes tuples different from lists?**
- a) Tuples use parentheses
- b) Tuples are immutable
- c) Tuples are faster
- d) All of the above

**Answer**: d) All of the above

---

**7. How do you create a single-element tuple?**
- a) `(5)`
- b) `(5,)`
- c) `tuple(5)`
- d) `[5]`

**Answer**: b) `(5,)` (comma is required)

---

**8. What is the output of: `{'a': 1, 'b': 2}.get('c', 0)`**
- a) `None`
- b) `KeyError`
- c) `0`
- d) `'c'`

**Answer**: c) `0` (default value when key not found)

---

**9. Which is the correct dictionary comprehension?**
- a) `{x: x**2 for x in range(3)}`
- b) `[x: x**2 for x in range(3)]`
- c) `{x => x**2 for x in range(3)}`
- d) `dict(x: x**2 for x in range(3))`

**Answer**: a) `{x: x**2 for x in range(3)}`

---

**10. What does `dict.keys()` return?**
- a) A list of keys
- b) A tuple of keys
- c) A dict_keys view object
- d) A set of keys

**Answer**: c) A dict_keys view object

---

### Section 6: Sets

**11. What is the output of: `{1, 2, 3} & {2, 3, 4}`**
- a) `{1, 2, 3, 4}`
- b) `{2, 3}`
- c) `{1, 4}`
- d) `{2}`

**Answer**: b) `{2, 3}` (intersection)

---

**12. Which is TRUE about sets?**
- a) Sets maintain insertion order
- b) Sets allow duplicate elements
- c) Sets are mutable
- d) Sets can be used as dictionary keys

**Answer**: c) Sets are mutable (frozensets are immutable)

---

**13. What is the output of: `len({1, 2, 2, 3, 3, 3})`**
- a) `6`
- b) `3`
- c) `{1, 2, 3}`
- d) `TypeError`

**Answer**: b) `3` (duplicates removed automatically)

---

### Section 7: Conditionals

**14. What is the output of: `10 if True else 20`**
- a) `True`
- b) `10`
- c) `20`
- d) `SyntaxError`

**Answer**: b) `10` (ternary operator)

---

**15. Which operator checks identity (same object)?**
- a) `==`
- b) `is`
- c) `===`
- d) `equals`

**Answer**: b) `is`

---

**16. What is the output of: `bool([])`**
- a) `True`
- b) `False`
- c) `[]`
- d) `TypeError`

**Answer**: b) `False` (empty list is falsy)

---

**17. Which is a falsy value in Python?**
- a) `0`
- b) `""`
- c) `None`
- d) All of the above

**Answer**: d) All of the above

---

**18. What is the output of: `5 < 10 and 10 > 15`**
- a) `True`
- b) `False`
- c) `5`
- d) `10`

**Answer**: b) `False` (second condition is false)

---

**19. What does `'a' in 'hello'` return?**
- a) `True`
- b) `False`
- c) `1`
- d) `None`

**Answer**: b) `False` ('a' is not in 'hello')

---

**20. Which is the correct syntax for elif?**
- a) `else if condition:`
- b) `elif condition:`
- c) `elseif condition:`
- d) `elsif condition:`

**Answer**: b) `elif condition:`

---

## Answer Key

| Question | Answer | Topic |
|----------|---------|-------|
| 1 | d | Python Installation |
| 2 | b | Data Types |
| 3 | c | Variable Naming |
| 4 | b | List Slicing |
| 5 | b | List Methods |
| 6 | d | Tuples vs Lists |
| 7 | b | Tuple Syntax |
| 8 | c | Dictionary get() |
| 9 | a | Dict Comprehension |
| 10 | c | Dictionary Methods |
| 11 | b | Set Operations |
| 12 | c | Set Properties |
| 13 | b | Set Uniqueness |
| 14 | b | Ternary Operator |
| 15 | b | Identity vs Equality |
| 16 | b | Truthiness |
| 17 | d | Falsy Values |
| 18 | b | Logical Operators |
| 19 | b | Membership Testing |
| 20 | b | Conditional Syntax |

---

## Grading Scale

- **18-20 correct (90-100%)**: Excellent! Ready for next sections
- **16-17 correct (80-89%)**: Very Good! Review missed topics
- **14-15 correct (70-79%)**: Good! Review sections 1-7 again
- **Below 14 (< 70%)**: Need more practice - review all sections

---

## Review Resources

- Section 01: Python Setup
- Section 02: Variables and Data Types
- Section 03: Lists
- Section 04: Tuples
- Section 05: Dictionaries
- Section 06: Sets
- Section 07: Conditionals

**Next**: Complete Labs 01-05 for hands-on practice!

**கற்க கசடற** - Learn Flawlessly
