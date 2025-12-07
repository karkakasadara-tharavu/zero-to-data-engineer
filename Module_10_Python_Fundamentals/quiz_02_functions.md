# Module 10 - Quiz 02: Functions and Advanced Topics
## Sections 8-14: Loops through Error Handling

**கற்க கசடற** - Learn Flawlessly

**Time Limit**: 25 minutes  
**Passing Score**: 70% (11/15 correct)  
**Instructions**: Choose the best answer for each question.

---

### Section 8-9: Loops, Functions

**1. What is the output of: `range(5)`**
- a) `[0, 1, 2, 3, 4]`
- b) `[1, 2, 3, 4, 5]`
- c) `range(0, 5)`
- d) `5`

**Answer**: c) `range(0, 5)` (range object, not a list)

---

**2. What does `enumerate(['a', 'b'])` provide?**
- a) `['a', 'b']`
- b) `[(0, 'a'), (1, 'b')]`
- c) `{'a': 0, 'b': 1}`
- d) `enumerate object`

**Answer**: d) `enumerate object` (can be converted to list for b)

---

**3. What is the purpose of `break` in a loop?**
- a) Skip current iteration
- b) Exit the loop entirely
- c) Restart the loop
- d) Pause the loop

**Answer**: b) Exit the loop entirely

---

**4. Which is true about function parameters?**
- a) Default parameters must come before non-default
- b) Non-default parameters must come before default
- c) Order doesn't matter
- d) Python doesn't allow default parameters

**Answer**: b) Non-default parameters must come before default

---

**5. What does `*args` do in a function?**
- a) Accepts multiple positional arguments
- b) Accepts multiple keyword arguments
- c) Returns multiple values
- d) Creates a global variable

**Answer**: a) Accepts multiple positional arguments

---

### Section 10-11: Lambda, Strings

**6. What is the output of: `(lambda x: x**2)(5)`**
- a) `10`
- b) `25`
- c) `5`
- d) `SyntaxError`

**Answer**: b) `25` (lambda function squares 5)

---

**7. Which is equivalent to: `list(map(lambda x: x*2, [1,2,3]))`**
- a) `[1, 2, 3, 1, 2, 3]`
- b) `[2, 4, 6]`
- c) `[1, 4, 9]`
- d) `6`

**Answer**: b) `[2, 4, 6]`

---

**8. What is the output of: `"hello {name}".format(name="world")`**
- a) `"hello world"`
- b) `"hello {name}"`
- c) `"hello name"`
- d) `SyntaxError`

**Answer**: a) `"hello world"`

---

**9. What does `"Python".lower()` return?**
- a) `"PYTHON"`
- b) `"python"`
- c) `"Python"`
- d) Modifies original string

**Answer**: b) `"python"` (strings are immutable, returns new string)

---

### Section 12: Regular Expressions

**10. Which regex pattern matches any digit?**
- a) `\d`
- b) `\w`
- c) `\s`
- d) `[0-9]`

**Answer**: a) `\d` (though d is also correct)

---

**11. What does `^` mean in regex?**
- a) End of string
- b) Beginning of string
- c) Not operator
- d) Any character

**Answer**: b) Beginning of string

---

### Section 13-14: File Operations, Error Handling

**12. Which mode opens a file for reading?**
- a) `'w'`
- b) `'r'`
- c) `'a'`
- d) `'x'`

**Answer**: b) `'r'` (read mode, default)

---

**13. What is the benefit of using `with open():`?**
- a) Faster file access
- b) Automatic file closing
- c) Better error handling
- d) Allows parallel file access

**Answer**: b) Automatic file closing

---

**14. Which exception is raised for division by zero?**
- a) `ValueError`
- b) `ZeroDivisionError`
- c) `TypeError`
- d) `ArithmeticError`

**Answer**: b) `ZeroDivisionError`

---

**15. What does `finally` do in try-except?**
- a) Runs only if exception occurs
- b) Runs only if no exception
- c) Always runs regardless of exception
- d) Raises a new exception

**Answer**: c) Always runs regardless of exception

---

## Answer Key

| Question | Answer | Topic |
|----------|---------|-------|
| 1 | c | range() Function |
| 2 | d | enumerate() |
| 3 | b | break Statement |
| 4 | b | Function Parameters |
| 5 | a | *args |
| 6 | b | Lambda Functions |
| 7 | b | map() Function |
| 8 | a | String Formatting |
| 9 | b | String Methods |
| 10 | a | Regex Patterns |
| 11 | b | Regex Anchors |
| 12 | b | File Modes |
| 13 | b | Context Managers |
| 14 | b | Exceptions |
| 15 | c | finally Clause |

---

## Grading Scale

- **14-15 correct (93-100%)**: Excellent! Module 10 mastered
- **13 correct (87%)**: Very Good! Minor review needed
- **11-12 correct (73-80%)**: Good! Review missed sections
- **Below 11 (< 73%)**: Need more practice - review sections 8-14

---

## Review Resources

- Section 08: Loops
- Section 09: Functions
- Section 10: Lambda Functions
- Section 11: Strings
- Section 12: Regular Expressions
- Section 13: File Operations
- Section 14: Error Handling

**Next**: Complete Labs 06-11 and Module 11!

**கற்க கசடற** - Learn Flawlessly
