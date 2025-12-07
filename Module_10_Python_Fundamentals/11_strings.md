# String Manipulation in Python

## 🎯 Learning Objectives
- Master string creation and formatting
- Use string methods effectively
- Understand string slicing and indexing
- Work with multi-line strings
- Apply string operations in data processing
- Format strings with f-strings and format()

---

## 📝 What are Strings?

Strings are sequences of characters enclosed in quotes. They're immutable (cannot be changed after creation).

### Creating Strings
```python
# Single quotes
name = 'Alice'

# Double quotes
message = "Hello World"

# Triple quotes (multi-line)
paragraph = """This is a
multi-line
string."""

# Triple single quotes also work
text = '''Another way
to create
multi-line strings.'''

# Empty string
empty = ""
```

### String Quotes Rules
```python
# Use double quotes when string contains single quote
text = "It's a beautiful day"

# Use single quotes when string contains double quote
message = 'He said "Hello"'

# Or escape quotes
text = 'It\'s a beautiful day'
message = "He said \"Hello\""

# Triple quotes for both
mixed = """He said "It's great!" """
```

---

## 🔤 String Indexing and Slicing

Access individual characters or substrings.

### Indexing
```python
text = "Python"

# Positive indexing (0-based)
print(text[0])   # 'P' (first character)
print(text[1])   # 'y'
print(text[5])   # 'n' (last character)

# Negative indexing (from end)
print(text[-1])  # 'n' (last character)
print(text[-2])  # 'o' (second from end)
print(text[-6])  # 'P' (first character)
```

### Slicing
```python
text = "Hello World"

# [start:end] - end is exclusive
print(text[0:5])    # 'Hello' (chars 0-4)
print(text[6:11])   # 'World'

# Omit start (defaults to 0)
print(text[:5])     # 'Hello'

# Omit end (goes to end of string)
print(text[6:])     # 'World'

# Negative indices
print(text[-5:])    # 'World' (last 5 chars)
print(text[:-6])    # 'Hello' (all but last 6)

# Step parameter [start:end:step]
print(text[::2])    # 'HloWrd' (every 2nd char)
print(text[::-1])   # 'dlroW olleH' (reverse)
```

### Practical Slicing
```python
# Extract filename components
filename = "report_2024_final.pdf"

# Get name without extension
name = filename[:filename.rindex('.')]
print(name)  # 'report_2024_final'

# Get extension
ext = filename[filename.rindex('.'):]
print(ext)   # '.pdf'

# Better way
name, ext = filename.rsplit('.', 1)
print(name, ext)  # 'report_2024_final' 'pdf'
```

---

## ➕ String Concatenation

Combine strings together.

### Using + Operator
```python
first_name = "John"
last_name = "Doe"

# Concatenate
full_name = first_name + " " + last_name
print(full_name)  # 'John Doe'

# Multiple concatenations
greeting = "Hello" + " " + "World" + "!"
print(greeting)  # 'Hello World!'
```

### Using join() (Better for Multiple Strings)
```python
# Join with space
words = ["Hello", "World", "Python"]
sentence = " ".join(words)
print(sentence)  # 'Hello World Python'

# Join with comma
items = ["apple", "banana", "cherry"]
csv_line = ",".join(items)
print(csv_line)  # 'apple,banana,cherry'

# Join with newline
lines = ["First line", "Second line", "Third line"]
text = "\n".join(lines)
print(text)
# First line
# Second line
# Third line
```

### Using * for Repetition
```python
# Repeat string
dash = "-" * 40
print(dash)  # ----------------------------------------

# Create separator
separator = "=" * 50
print(separator)

# Pattern
pattern = "ab" * 5
print(pattern)  # 'ababababab'
```

---

## 🎨 String Formatting

Multiple ways to format strings.

### 1. f-strings (Python 3.6+) - **Recommended**
```python
name = "Alice"
age = 25
salary = 75000.50

# Basic f-string
print(f"My name is {name}")

# Multiple variables
print(f"{name} is {age} years old")

# Expressions inside {}
print(f"In 5 years, {name} will be {age + 5}")

# Formatting numbers
print(f"Salary: ${salary:,.2f}")  # Salary: $75,000.50

# Alignment
print(f"|{name:<10}|")  # |Alice     | (left align)
print(f"|{name:>10}|")  # |     Alice| (right align)
print(f"|{name:^10}|")  # |  Alice   | (center)
```

### 2. format() Method
```python
name = "Bob"
age = 30

# Basic
print("My name is {}".format(name))

# Positional
print("{0} is {1} years old".format(name, age))

# Named
print("{name} is {age} years old".format(name=name, age=age))

# Number formatting
print("Price: ${:.2f}".format(19.99))  # Price: $19.99
```

### 3. % Operator (Old Style)
```python
name = "Carol"
age = 28

# String placeholder
print("My name is %s" % name)

# Multiple values
print("%s is %d years old" % (name, age))

# Float formatting
print("Pi is approximately %.2f" % 3.14159)  # Pi is approximately 3.14
```

### Number Formatting in f-strings
```python
# Decimal places
value = 3.14159
print(f"{value:.2f}")  # 3.14

# Thousands separator
number = 1000000
print(f"{number:,}")   # 1,000,000

# Both
price = 1234.5678
print(f"${price:,.2f}")  # $1,234.57

# Percentage
ratio = 0.75
print(f"{ratio:.1%}")  # 75.0%

# Scientific notation
big_num = 1000000
print(f"{big_num:e}")  # 1.000000e+06
```

---

## 🔧 Essential String Methods

### Case Conversion
```python
text = "Hello World"

print(text.upper())      # 'HELLO WORLD'
print(text.lower())      # 'hello world'
print(text.capitalize()) # 'Hello world' (first char only)
print(text.title())      # 'Hello World' (each word)
print(text.swapcase())   # 'hELLO wORLD' (swap case)

# Check case
print("HELLO".isupper())  # True
print("hello".islower())  # True
print("Hello".istitle())  # True
```

### Whitespace Handling
```python
text = "   Hello World   "

print(text.strip())   # 'Hello World' (both ends)
print(text.lstrip())  # 'Hello World   ' (left)
print(text.rstrip())  # '   Hello World' (right)

# Strip specific characters
text = "***Hello***"
print(text.strip('*'))  # 'Hello'

# Remove specific character
text = "Hello, World!"
print(text.replace(',', ''))  # 'Hello World!'
```

### Searching and Finding
```python
text = "Hello World"

# Check if contains
print("World" in text)     # True
print("Python" in text)    # False
print("Python" not in text) # True

# Find position
print(text.find("World"))    # 6 (index of 'W')
print(text.find("Python"))   # -1 (not found)
print(text.index("World"))   # 6 (raises ValueError if not found)

# Count occurrences
text = "banana"
print(text.count("a"))  # 3

# Check start/end
print(text.startswith("ban"))  # True
print(text.endswith("ana"))    # True
```

### Splitting and Joining
```python
# Split into list
text = "apple,banana,cherry"
fruits = text.split(",")
print(fruits)  # ['apple', 'banana', 'cherry']

# Split on whitespace (default)
sentence = "Hello World Python"
words = sentence.split()
print(words)  # ['Hello', 'World', 'Python']

# Limit splits
text = "one,two,three,four"
parts = text.split(",", 2)  # Split max 2 times
print(parts)  # ['one', 'two', 'three,four']

# Split lines
multiline = "Line 1\nLine 2\nLine 3"
lines = multiline.splitlines()
print(lines)  # ['Line 1', 'Line 2', 'Line 3']

# Join list into string
words = ["Python", "is", "awesome"]
sentence = " ".join(words)
print(sentence)  # 'Python is awesome'
```

### Replacing
```python
text = "Hello World"

# Replace substring
new_text = text.replace("World", "Python")
print(new_text)  # 'Hello Python'

# Replace all occurrences
text = "apple apple banana apple"
new_text = text.replace("apple", "orange")
print(new_text)  # 'orange orange banana orange'

# Limit replacements
new_text = text.replace("apple", "orange", 2)
print(new_text)  # 'orange orange banana apple'
```

### Checking Content
```python
# Check if alphanumeric
print("Hello123".isalnum())   # True
print("Hello 123".isalnum())  # False (has space)

# Check if alphabetic
print("Hello".isalpha())      # True
print("Hello123".isalpha())   # False

# Check if digits
print("12345".isdigit())      # True
print("123.45".isdigit())     # False (has dot)

# Check if decimal
print("123.45".isdecimal())   # False (dot)
print("12345".isdecimal())    # True

# Check if space
print("   ".isspace())         # True
print("Hello World".isspace()) # False
```

---

## 📊 Practical String Examples

### Example 1: Clean and Normalize Text
```python
def normalize_text(text):
    """Clean and normalize user input"""
    return text.strip().lower().replace("  ", " ")

# Test
inputs = ["  Hello World  ", "PYTHON  PROGRAMMING", "  Data   Science  "]
for text in inputs:
    print(f"'{text}' → '{normalize_text(text)}'")

# Output:
# '  Hello World  ' → 'hello world'
# 'PYTHON  PROGRAMMING' → 'python programming'
# '  Data   Science  ' → 'data  science'
```

### Example 2: Parse CSV Line
```python
def parse_csv_line(line):
    """Parse comma-separated values"""
    return [item.strip() for item in line.split(',')]

csv_line = "Alice, 25, Engineer, New York"
fields = parse_csv_line(csv_line)
print(fields)
# ['Alice', '25', 'Engineer', 'New York']

# Create record
name, age, job, city = fields
print(f"{name} is a {age}-year-old {job} from {city}")
```

### Example 3: Format Phone Number
```python
def format_phone(phone):
    """Format phone number to (XXX) XXX-XXXX"""
    # Remove non-digits
    digits = ''.join(c for c in phone if c.isdigit())
    
    if len(digits) == 10:
        return f"({digits[:3]}) {digits[3:6]}-{digits[6:]}"
    return "Invalid phone number"

# Test
phones = ["1234567890", "123-456-7890", "(123) 456-7890"]
for phone in phones:
    print(f"{phone} → {format_phone(phone)}")

# Output:
# 1234567890 → (123) 456-7890
# 123-456-7890 → (123) 456-7890
# (123) 456-7890 → (123) 456-7890
```

### Example 4: Extract Email Parts
```python
def parse_email(email):
    """Extract username and domain from email"""
    if '@' not in email:
        return None
    
    username, domain = email.split('@')
    domain_parts = domain.split('.')
    
    return {
        'username': username,
        'domain': domain,
        'domain_name': domain_parts[0] if domain_parts else '',
        'tld': domain_parts[-1] if domain_parts else ''
    }

# Test
email = "alice.smith@example.com"
parts = parse_email(email)
print(parts)
# {'username': 'alice.smith', 'domain': 'example.com', 
#  'domain_name': 'example', 'tld': 'com'}
```

### Example 5: Create Slug from Title
```python
def create_slug(title):
    """Convert title to URL-friendly slug"""
    slug = title.lower()
    slug = slug.replace(' ', '-')
    # Remove special characters
    slug = ''.join(c for c in slug if c.isalnum() or c == '-')
    # Remove multiple dashes
    while '--' in slug:
        slug = slug.replace('--', '-')
    return slug.strip('-')

# Test
titles = [
    "Hello World!",
    "Python Programming 101",
    "Data Science & Machine Learning"
]

for title in titles:
    print(f"'{title}' → '{create_slug(title)}'")

# Output:
# 'Hello World!' → 'hello-world'
# 'Python Programming 101' → 'python-programming-101'
# 'Data Science & Machine Learning' → 'data-science-machine-learning'
```

### Example 6: Word Frequency Counter
```python
def count_words(text):
    """Count word frequency in text"""
    # Normalize and split
    words = text.lower().split()
    
    # Remove punctuation
    words = [''.join(c for c in word if c.isalnum()) for word in words]
    
    # Count
    word_count = {}
    for word in words:
        if word:  # Skip empty strings
            word_count[word] = word_count.get(word, 0) + 1
    
    return word_count

# Test
text = "The quick brown fox jumps over the lazy dog. The dog was very lazy."
counts = count_words(text)

# Print sorted by frequency
for word, count in sorted(counts.items(), key=lambda x: x[1], reverse=True):
    print(f"{word}: {count}")

# Output:
# the: 3
# lazy: 2
# dog: 2
# quick: 1
# ...
```

### Example 7: Template String Replacement
```python
def fill_template(template, **kwargs):
    """Replace placeholders in template"""
    for key, value in kwargs.items():
        placeholder = f"{{{key}}}"
        template = template.replace(placeholder, str(value))
    return template

# Test
email_template = """
Dear {name},

Your order #{order_id} has been confirmed.
Total: ${total:.2f}

Thank you for your purchase!
"""

message = fill_template(
    email_template,
    name="Alice",
    order_id=12345,
    total=99.99
)
print(message)
```

---

## 🎓 Advanced String Techniques

### String Alignment and Padding
```python
# Left align
print("Python".ljust(10, '-'))  # Python----

# Right align
print("Python".rjust(10, '-'))  # ----Python

# Center
print("Python".center(10, '-')) # --Python--

# Zero padding for numbers
number = 42
print(f"{number:05d}")  # 00042
```

### String Translation
```python
# Create translation table
translation = str.maketrans("aeiou", "12345")
text = "hello world"
print(text.translate(translation))  # h2ll4 w4rld

# Remove characters
remove_digits = str.maketrans("", "", "0123456789")
text = "Hello123World456"
print(text.translate(remove_digits))  # HelloWorld
```

### Partition and Rpartition
```python
# Partition splits into 3 parts: before, sep, after
text = "username@example.com"
before, sep, after = text.partition('@')
print(f"Username: {before}, Domain: {after}")

# Rpartition (from right)
filename = "document.backup.txt"
name, sep, ext = filename.rpartition('.')
print(f"Name: {name}, Extension: {ext}")
```

---

## ⚠️ Common Pitfalls

### Mistake 1: Strings are Immutable
```python
text = "Hello"

# ❌ Can't modify string
# text[0] = 'h'  # TypeError!

# ✅ Create new string
text = 'h' + text[1:]
print(text)  # 'hello'
```

### Mistake 2: Using + for Many Concatenations
```python
# ❌ Inefficient (creates new string each time)
result = ""
for word in ["Hello", "World", "Python"]:
    result = result + " " + word

# ✅ Use join (much faster)
words = ["Hello", "World", "Python"]
result = " ".join(words)
```

### Mistake 3: Forgetting strip() on User Input
```python
# User enters "  yes  " (with spaces)
answer = input("Continue? (yes/no): ")

# ❌ Won't match
if answer == "yes":
    print("Continuing...")

# ✅ Strip whitespace
if answer.strip().lower() == "yes":
    print("Continuing...")
```

### Mistake 4: Wrong String Comparison
```python
# ❌ Case-sensitive comparison
password = "Password123"
if password == "password123":
    print("Match")  # Won't print

# ✅ Case-insensitive comparison
if password.lower() == "password123":
    print("Match")  # Prints
```

---

## ✅ Key Takeaways

1. ✅ Strings are immutable sequences of characters
2. ✅ Use f-strings for modern string formatting
3. ✅ Master slicing: `[start:end:step]`
4. ✅ Use `join()` for efficient concatenation
5. ✅ `strip()` removes whitespace
6. ✅ `split()` breaks strings into lists
7. ✅ `replace()` substitutes substrings
8. ✅ String methods return new strings (immutable)
9. ✅ Use `in` for substring checking
10. ✅ Always normalize user input (strip, lower)

---

**Practice**: Complete Lab 08 - String Manipulation

**Next Section**: 12_regex_basics.md

**கற்க கசடற** - Learn Flawlessly

