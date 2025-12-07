# Sets in Python

## 🎯 Learning Objectives
- Understand what sets are and their properties
- Create and modify sets
- Perform set operations (union, intersection, difference)
- Use set methods effectively
- Understand frozen sets
- Apply sets to real-world problems

---

## 📝 What is a Set?

A **set** is an **unordered** collection of **unique** elements. No duplicates allowed!

```python
# Creating sets
numbers = {1, 2, 3, 4, 5}
fruits = {"apple", "banana", "cherry"}

# Duplicates are automatically removed
numbers_with_dupes = {1, 2, 2, 3, 3, 3, 4}
print(numbers_with_dupes)  # {1, 2, 3, 4}

# Empty set (must use set(), not {})
empty = set()  # ✅ Correct
# empty = {}   # ❌ This creates an empty dictionary!
```

**Key Features:**
- ✅ Unordered (no indexing)
- ✅ No duplicates
- ✅ Mutable (can add/remove elements)
- ✅ Elements must be immutable (hashable)
- ✅ Fast membership testing
- ✅ Mathematical set operations

---

## 🔍 Sets vs Lists vs Tuples vs Dictionaries

| Feature | List | Tuple | Set | Dictionary |
|---------|------|-------|-----|------------|
| **Syntax** | `[1, 2]` | `(1, 2)` | `{1, 2}` | `{"a": 1}` |
| **Ordered** | ✅ Yes | ✅ Yes | ❌ No | ✅ (3.7+) |
| **Duplicates** | ✅ Yes | ✅ Yes | ❌ No | Keys: ❌ |
| **Mutable** | ✅ Yes | ❌ No | ✅ Yes | ✅ Yes |
| **Indexing** | ✅ Yes | ✅ Yes | ❌ No | Key-based |
| **Use Case** | Ordered data | Fixed data | Unique items | Key-value |

---

## 📊 Creating Sets

### Method 1: Literal Syntax
```python
# Simple set
numbers = {1, 2, 3, 4, 5}
colors = {"red", "green", "blue"}

# Mixed types
mixed = {1, "hello", 3.14, True}
```

### Method 2: set() Constructor
```python
# From list (removes duplicates)
list_data = [1, 2, 2, 3, 3, 3, 4]
unique_numbers = set(list_data)
print(unique_numbers)  # {1, 2, 3, 4}

# From string (splits into characters)
letters = set("hello")
print(letters)  # {'h', 'e', 'l', 'o'} - no duplicate 'l'

# From tuple
tuple_data = (1, 2, 3, 4, 5)
number_set = set(tuple_data)

# From range
evens = set(range(0, 11, 2))
print(evens)  # {0, 2, 4, 6, 8, 10}
```

### Method 3: Set Comprehension
```python
# Even squares
even_squares = {x**2 for x in range(10) if x % 2 == 0}
print(even_squares)  # {0, 4, 16, 36, 64}

# Uppercase letters
text = "Hello World"
uppercase = {char for char in text if char.isupper()}
print(uppercase)  # {'H', 'W'}
```

---

## ➕ Adding Elements

### add() - Add Single Element
```python
fruits = {"apple", "banana"}

fruits.add("cherry")
print(fruits)  # {'apple', 'banana', 'cherry'}

# Adding duplicate (no effect)
fruits.add("apple")
print(fruits)  # Still {'apple', 'banana', 'cherry'}
```

### update() - Add Multiple Elements
```python
fruits = {"apple", "banana"}

# From list
fruits.update(["cherry", "mango"])

# From another set
tropical = {"pineapple", "coconut"}
fruits.update(tropical)

# Multiple iterables
fruits.update(["grape"], {"kiwi"}, ("orange",))

print(fruits)
# {'apple', 'banana', 'cherry', 'mango', 'pineapple', 'coconut', 'grape', 'kiwi', 'orange'}
```

---

## ➖ Removing Elements

### remove() - Remove element (raises error if not found)
```python
colors = {"red", "green", "blue", "yellow"}

colors.remove("green")
print(colors)  # {'red', 'blue', 'yellow'}

# ❌ KeyError if element doesn't exist
# colors.remove("purple")  # KeyError: 'purple'
```

### discard() - Remove element (no error if not found)
```python
colors = {"red", "green", "blue"}

colors.discard("green")   # Removes "green"
colors.discard("purple")  # No error, does nothing

print(colors)  # {'red', 'blue'}
```

### pop() - Remove and return arbitrary element
```python
numbers = {1, 2, 3, 4, 5}

removed = numbers.pop()
print(f"Removed: {removed}")
print(f"Remaining: {numbers}")

# ❌ KeyError on empty set
empty = set()
# empty.pop()  # KeyError
```

### clear() - Remove all elements
```python
colors = {"red", "green", "blue"}
colors.clear()
print(colors)  # set()
```

---

## 🔍 Set Operations

### Union (|) - All Elements from Both Sets
```python
set1 = {1, 2, 3, 4}
set2 = {3, 4, 5, 6}

# Using operator
union1 = set1 | set2
print(union1)  # {1, 2, 3, 4, 5, 6}

# Using method
union2 = set1.union(set2)
print(union2)  # {1, 2, 3, 4, 5, 6}

# Multiple sets
set3 = {7, 8}
union_all = set1 | set2 | set3
print(union_all)  # {1, 2, 3, 4, 5, 6, 7, 8}
```

### Intersection (&) - Common Elements
```python
set1 = {1, 2, 3, 4, 5}
set2 = {4, 5, 6, 7, 8}

# Using operator
common = set1 & set2
print(common)  # {4, 5}

# Using method
common2 = set1.intersection(set2)
print(common2)  # {4, 5}

# Multiple sets
set3 = {4, 9, 10}
common_all = set1 & set2 & set3
print(common_all)  # {4}
```

### Difference (-) - Elements in First but Not Second
```python
set1 = {1, 2, 3, 4, 5}
set2 = {4, 5, 6, 7, 8}

# Using operator
diff = set1 - set2
print(diff)  # {1, 2, 3}

# Using method
diff2 = set1.difference(set2)
print(diff2)  # {1, 2, 3}

# Order matters!
diff3 = set2 - set1
print(diff3)  # {6, 7, 8}
```

### Symmetric Difference (^) - Elements in Either but Not Both
```python
set1 = {1, 2, 3, 4, 5}
set2 = {4, 5, 6, 7, 8}

# Using operator
sym_diff = set1 ^ set2
print(sym_diff)  # {1, 2, 3, 6, 7, 8}

# Using method
sym_diff2 = set1.symmetric_difference(set2)
print(sym_diff2)  # {1, 2, 3, 6, 7, 8}
```

---

## 📊 Visual Representation of Set Operations

```
Set A = {1, 2, 3, 4, 5}
Set B = {4, 5, 6, 7, 8}

Union (A | B):
{1, 2, 3, 4, 5, 6, 7, 8}  ← All elements from both

Intersection (A & B):
{4, 5}  ← Only common elements

Difference (A - B):
{1, 2, 3}  ← Only in A, not in B

Symmetric Difference (A ^ B):
{1, 2, 3, 6, 7, 8}  ← In A or B, but not both
```

---

## 🔍 Set Relationships

### Subset (<=) - All elements of A are in B
```python
set_a = {1, 2, 3}
set_b = {1, 2, 3, 4, 5}

# Is A subset of B?
is_subset = set_a <= set_b
print(is_subset)  # True

# Using method
is_subset2 = set_a.issubset(set_b)
print(is_subset2)  # True

# Proper subset (A ⊂ B, A ≠ B)
is_proper_subset = set_a < set_b
print(is_proper_subset)  # True
```

### Superset (>=) - All elements of B are in A
```python
set_a = {1, 2, 3, 4, 5}
set_b = {1, 2, 3}

# Is A superset of B?
is_superset = set_a >= set_b
print(is_superset)  # True

# Using method
is_superset2 = set_a.issuperset(set_b)
print(is_superset2)  # True

# Proper superset
is_proper_superset = set_a > set_b
print(is_proper_superset)  # True
```

### Disjoint - No Common Elements
```python
set_a = {1, 2, 3}
set_b = {4, 5, 6}
set_c = {3, 4, 5}

# Are A and B disjoint?
print(set_a.isdisjoint(set_b))  # True (no common elements)
print(set_a.isdisjoint(set_c))  # False (3 is common)
```

---

## 🔄 Set Methods Summary

| Method | Description | Example |
|--------|-------------|---------|
| `add(x)` | Add element | `s.add(5)` |
| `update(iterable)` | Add multiple | `s.update([1, 2])` |
| `remove(x)` | Remove (error if missing) | `s.remove(5)` |
| `discard(x)` | Remove (no error) | `s.discard(5)` |
| `pop()` | Remove arbitrary | `s.pop()` |
| `clear()` | Remove all | `s.clear()` |
| `copy()` | Shallow copy | `s2 = s.copy()` |
| `union()` | A ∪ B | `s1.union(s2)` |
| `intersection()` | A ∩ B | `s1.intersection(s2)` |
| `difference()` | A - B | `s1.difference(s2)` |
| `symmetric_difference()` | A △ B | `s1.symmetric_difference(s2)` |
| `issubset()` | A ⊆ B | `s1.issubset(s2)` |
| `issuperset()` | A ⊇ B | `s1.issuperset(s2)` |
| `isdisjoint()` | A ∩ B = ∅ | `s1.isdisjoint(s2)` |

---

## 📚 Practical Examples

### Example 1: Remove Duplicates from List
```python
# List with duplicates
numbers = [1, 2, 3, 2, 4, 3, 5, 1, 6, 4]

# Convert to set (removes duplicates), then back to list
unique_numbers = list(set(numbers))
print(unique_numbers)  # [1, 2, 3, 4, 5, 6] (order may vary)

# Preserve order (Python 3.7+)
unique_ordered = list(dict.fromkeys(numbers))
print(unique_ordered)  # [1, 2, 3, 4, 5, 6] (preserves order)
```

### Example 2: Find Common Elements
```python
# Students enrolled in different courses
python_students = {"Alice", "Bob", "Carol", "Dave"}
sql_students = {"Bob", "Dave", "Eve", "Frank"}
java_students = {"Carol", "Dave", "Frank", "Grace"}

# Students in both Python and SQL
both = python_students & sql_students
print(f"Python AND SQL: {both}")  # {'Bob', 'Dave'}

# Students in Python or SQL or both
either = python_students | sql_students
print(f"Python OR SQL: {either}")

# Students in all three courses
all_three = python_students & sql_students & java_students
print(f"All three courses: {all_three}")  # {'Dave'}

# Students in Python but not SQL
python_only = python_students - sql_students
print(f"Python only: {python_only}")  # {'Alice', 'Carol'}
```

### Example 3: Email List Management
```python
# Email lists from different sources
newsletter_subscribers = {"alice@email.com", "bob@email.com", "carol@email.com"}
purchased_product = {"bob@email.com", "dave@email.com"}
webinar_attendees = {"carol@email.com", "dave@email.com", "eve@email.com"}

# All contacts (union)
all_contacts = newsletter_subscribers | purchased_product | webinar_attendees
print(f"Total contacts: {len(all_contacts)}")

# Engaged users (in multiple lists)
engaged = (newsletter_subscribers & purchased_product) | \
          (newsletter_subscribers & webinar_attendees) | \
          (purchased_product & webinar_attendees)
print(f"Engaged users: {engaged}")

# Newsletter subscribers who never purchased
never_purchased = newsletter_subscribers - purchased_product
print(f"Never purchased: {never_purchased}")
```

### Example 4: Data Validation
```python
# Required fields for user registration
required_fields = {"username", "email", "password", "age"}

# User submitted data
user_data = {"username": "john_doe", "email": "john@example.com", "password": "secret"}

# Check for missing fields
submitted_fields = set(user_data.keys())
missing_fields = required_fields - submitted_fields

if missing_fields:
    print(f"Missing fields: {', '.join(missing_fields)}")
else:
    print("All required fields present")

# Check for extra/unknown fields
allowed_fields = required_fields | {"phone", "address"}  # Optional fields
unknown_fields = submitted_fields - allowed_fields

if unknown_fields:
    print(f"Unknown fields: {', '.join(unknown_fields)}")
```

### Example 5: Word Analysis
```python
# Find unique words in sentences
sentence1 = "the quick brown fox jumps over the lazy dog"
sentence2 = "the lazy cat sleeps under the warm sun"

# Split into words and create sets
words1 = set(sentence1.split())
words2 = set(sentence2.split())

# Words in both sentences
common_words = words1 & words2
print(f"Common words: {common_words}")
# {'the', 'lazy'}

# Words only in sentence 1
unique_to_1 = words1 - words2
print(f"Unique to sentence 1: {unique_to_1}")
# {'quick', 'brown', 'fox', 'jumps', 'over', 'dog'}

# All unique words
all_words = words1 | words2
print(f"Total unique words: {len(all_words)}")
```

---

## 🎓 Frozen Sets

Immutable version of sets. Can be used as dictionary keys or set elements.

```python
# Create frozen set
frozen = frozenset([1, 2, 3, 4, 5])
print(frozen)  # frozenset({1, 2, 3, 4, 5})

# Cannot be modified
# frozen.add(6)        # ❌ AttributeError
# frozen.remove(1)     # ❌ AttributeError

# Can be used as dictionary key
location_data = {
    frozenset(["NY", "USA"]): "New York",
    frozenset(["LON", "UK"]): "London"
}

# Can be element of another set
set_of_sets = {
    frozenset([1, 2]),
    frozenset([3, 4]),
    frozenset([5, 6])
}

# Set operations still work
fs1 = frozenset([1, 2, 3])
fs2 = frozenset([3, 4, 5])
print(fs1 | fs2)  # frozenset({1, 2, 3, 4, 5})
print(fs1 & fs2)  # frozenset({3})
```

---

## ⚠️ Common Pitfalls

### Mistake 1: Trying to Index a Set
```python
colors = {"red", "green", "blue"}

# ❌ Sets don't support indexing
# first = colors[0]  # TypeError

# ✅ Convert to list if indexing needed
colors_list = list(colors)
first = colors_list[0]

# ✅ Or iterate
for color in colors:
    print(color)
```

### Mistake 2: Using Mutable Elements
```python
# ❌ Lists are mutable, can't be in set
# my_set = {[1, 2], [3, 4]}  # TypeError

# ✅ Use tuples instead
my_set = {(1, 2), (3, 4)}
print(my_set)  # {(1, 2), (3, 4)}
```

### Mistake 3: Empty Set vs Empty Dictionary
```python
# ❌ This creates an empty dictionary, not set!
empty = {}
print(type(empty))  # <class 'dict'>

# ✅ Use set() for empty set
empty_set = set()
print(type(empty_set))  # <class 'set'>
```

### Mistake 4: Assuming Order
```python
numbers = {5, 2, 8, 1, 9}
print(numbers)  # May print in any order!

# ✅ Sort if order matters
sorted_numbers = sorted(numbers)
print(sorted_numbers)  # [1, 2, 5, 8, 9]
```

---

## 🎨 Set Comprehensions

Create sets using concise syntax.

```python
# Basic set comprehension
squares = {x**2 for x in range(10)}
print(squares)  # {0, 1, 4, 9, 16, 25, 36, 49, 64, 81}

# With condition
even_squares = {x**2 for x in range(10) if x % 2 == 0}
print(even_squares)  # {0, 4, 16, 36, 64}

# String manipulation
text = "Hello World"
unique_lowercase = {char.lower() for char in text if char.isalpha()}
print(unique_lowercase)  # {'h', 'e', 'l', 'o', 'w', 'r', 'd'}

# From nested loop
pairs = {(x, y) for x in range(3) for y in range(3) if x != y}
print(pairs)
# {(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)}
```

---

## ✅ Key Takeaways

1. ✅ Sets store unique elements only
2. ✅ Unordered - no indexing
3. ✅ Fast membership testing (`in` operator)
4. ✅ Elements must be immutable (hashable)
5. ✅ Use `set()` for empty set, not `{}`
6. ✅ Mathematical operations: union, intersection, difference
7. ✅ Great for removing duplicates
8. ✅ Use frozenset for immutable sets
9. ✅ Set comprehensions for concise creation
10. ✅ Perfect for membership testing and set algebra

---

**Practice**: Complete Lab 03 - Working with Sets and Dictionaries

**Next Section**: 07_conditionals.md

**கற்க கசடற** - Learn Flawlessly

