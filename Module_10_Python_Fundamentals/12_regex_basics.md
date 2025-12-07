# Regular Expressions (Regex) Basics

## 🎯 Learning Objectives
- Understand what regular expressions are
- Use the `re` module in Python
- Master basic regex patterns
- Apply regex for data validation and extraction
- Use regex methods: search, match, findall, sub
- Understand regex metacharacters and quantifiers

---

## 📝 What are Regular Expressions?

**Regular expressions (regex)** are patterns used to match character combinations in strings. They're powerful tools for:
- ✅ Data validation (emails, phones, URLs)
- ✅ Text searching and extraction
- ✅ String manipulation and replacement
- ✅ Data cleaning and parsing

```python
import re

# Simple example: find all numbers in text
text = "I have 3 apples and 5 oranges"
numbers = re.findall(r'\d+', text)
print(numbers)  # ['3', '5']
```

---

## 🔧 The re Module

Python's built-in module for regex operations.

```python
import re

# Main functions
re.search()   # Find first match
re.match()    # Match at beginning
re.findall()  # Find all matches
re.sub()      # Replace matches
re.split()    # Split by pattern
re.compile()  # Compile pattern for reuse
```

---

## 🎯 Basic Patterns

### Literal Characters
```python
import re

text = "The quick brown fox"

# Exact match
match = re.search(r'quick', text)
if match:
    print(f"Found '{match.group()}' at position {match.start()}")
    # Output: Found 'quick' at position 4
```

### Metacharacters

| Character | Description | Example |
|-----------|-------------|---------|
| `.` | Any character (except newline) | `a.c` matches 'abc', 'a1c' |
| `^` | Start of string | `^Hello` matches 'Hello world' |
| `$` | End of string | `world$` matches 'Hello world' |
| `*` | 0 or more times | `ab*` matches 'a', 'ab', 'abb' |
| `+` | 1 or more times | `ab+` matches 'ab', 'abb' |
| `?` | 0 or 1 time | `ab?` matches 'a', 'ab' |
| `\` | Escape special character | `\.` matches literal dot |

```python
import re

# Dot (any character)
print(re.findall(r'c.t', 'cat cut cot c1t'))  # ['cat', 'cut', 'cot', 'c1t']

# Start of string
print(re.search(r'^Hello', 'Hello world'))    # Match
print(re.search(r'^world', 'Hello world'))    # None

# End of string
print(re.search(r'world$', 'Hello world'))    # Match
print(re.search(r'Hello$', 'Hello world'))    # None
```

---

## 🔢 Character Classes

Match specific sets of characters.

### Built-in Classes

| Pattern | Description | Equivalent |
|---------|-------------|------------|
| `\d` | Digit | `[0-9]` |
| `\D` | Non-digit | `[^0-9]` |
| `\w` | Word character | `[a-zA-Z0-9_]` |
| `\W` | Non-word character | `[^a-zA-Z0-9_]` |
| `\s` | Whitespace | `[ \t\n\r\f\v]` |
| `\S` | Non-whitespace | `[^ \t\n\r\f\v]` |

```python
import re

text = "Call me at 555-1234 or email test@example.com"

# Find digits
digits = re.findall(r'\d', text)
print(digits)  # ['5', '5', '5', '1', '2', '3', '4']

# Find words
words = re.findall(r'\w+', text)
print(words)  # ['Call', 'me', 'at', '555', '1234', 'or', 'email', 'test', 'example', 'com']

# Find whitespace
spaces = re.findall(r'\s', text)
print(len(spaces))  # 7 spaces
```

### Custom Character Classes
```python
import re

# [abc] - matches a, b, or c
print(re.findall(r'[aeiou]', 'hello'))  # ['e', 'o']

# [a-z] - range a to z
print(re.findall(r'[a-z]+', 'Hello123'))  # ['ello']

# [^abc] - NOT a, b, or c
print(re.findall(r'[^0-9]', '123abc'))  # ['a', 'b', 'c']

# Multiple ranges
print(re.findall(r'[a-zA-Z0-9]', 'Hello123!'))  # ['H','e','l','l','o','1','2','3']
```

---

## 🔄 Quantifiers

Specify how many times a pattern should match.

| Quantifier | Meaning | Example |
|------------|---------|---------|
| `*` | 0 or more | `a*` matches '', 'a', 'aa' |
| `+` | 1 or more | `a+` matches 'a', 'aa' (not '') |
| `?` | 0 or 1 | `a?` matches '', 'a' |
| `{n}` | Exactly n times | `a{3}` matches 'aaa' |
| `{n,}` | n or more times | `a{2,}` matches 'aa', 'aaa' |
| `{n,m}` | n to m times | `a{2,4}` matches 'aa', 'aaa', 'aaaa' |

```python
import re

# * (zero or more)
print(re.findall(r'ab*', 'a ab abb abbb'))  # ['a', 'ab', 'abb', 'abbb']

# + (one or more)
print(re.findall(r'ab+', 'a ab abb abbb'))  # ['ab', 'abb', 'abbb']

# ? (zero or one)
print(re.findall(r'ab?', 'a ab abb'))       # ['a', 'ab', 'ab']

# {n} (exactly n)
print(re.findall(r'a{3}', 'a aa aaa aaaa')) # ['aaa', 'aaa']

# {n,m} (n to m)
print(re.findall(r'a{2,3}', 'a aa aaa aaaa'))  # ['aa', 'aaa', 'aaa']
```

---

## 🔍 Common re Methods

### re.search() - Find First Match
```python
import re

text = "The price is $19.99"

# Find first match
match = re.search(r'\$\d+\.\d+', text)
if match:
    print(f"Found: {match.group()}")     # Found: $19.99
    print(f"Start: {match.start()}")     # Start: 13
    print(f"End: {match.end()}")         # End: 19
```

### re.match() - Match at Beginning
```python
import re

text = "Hello World"

# match() only checks start of string
match = re.match(r'Hello', text)
print(match.group() if match else "No match")  # Hello

match = re.match(r'World', text)
print(match.group() if match else "No match")  # No match
```

### re.findall() - Find All Matches
```python
import re

text = "Contact: john@email.com or alice@example.org"

# Find all email addresses
emails = re.findall(r'\w+@\w+\.\w+', text)
print(emails)  # ['john@email.com', 'alice@example.org']

# Find all numbers
text = "I have 3 apples, 5 oranges, and 10 bananas"
numbers = re.findall(r'\d+', text)
print(numbers)  # ['3', '5', '10']
```

### re.finditer() - Find All with Details
```python
import re

text = "Call 555-1234 or 555-5678"

# Get match objects for each match
for match in re.finditer(r'\d{3}-\d{4}', text):
    print(f"Found '{match.group()}' at position {match.start()}")

# Output:
# Found '555-1234' at position 5
# Found '555-5678' at position 17
```

### re.sub() - Replace Matches
```python
import re

text = "My phone is 555-1234"

# Replace phone number
new_text = re.sub(r'\d{3}-\d{4}', 'XXX-XXXX', text)
print(new_text)  # My phone is XXX-XXXX

# Replace with function
def mask_number(match):
    return 'X' * len(match.group())

text = "Credit card: 1234-5678-9012-3456"
masked = re.sub(r'\d{4}', mask_number, text)
print(masked)  # Credit card: XXXX-XXXX-XXXX-XXXX
```

### re.split() - Split by Pattern
```python
import re

# Split on comma, semicolon, or pipe
text = "apple,banana;cherry|date"
items = re.split(r'[,;|]', text)
print(items)  # ['apple', 'banana', 'cherry', 'date']

# Split on whitespace
text = "Hello    World   Python"  # Multiple spaces
words = re.split(r'\s+', text)
print(words)  # ['Hello', 'World', 'Python']
```

### re.compile() - Precompile Pattern
```python
import re

# Compile pattern for reuse (faster)
email_pattern = re.compile(r'\w+@\w+\.\w+')

# Use compiled pattern
text1 = "Contact: john@email.com"
text2 = "Email alice@example.org"

print(email_pattern.findall(text1))  # ['john@email.com']
print(email_pattern.findall(text2))  # ['alice@example.org']
```

---

## 📊 Practical Regex Examples

### Example 1: Validate Email
```python
import re

def is_valid_email(email):
    """Validate email format"""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None

# Test
emails = [
    "john@example.com",
    "alice.smith@company.co.uk",
    "invalid.email",
    "@example.com",
    "test@.com"
]

for email in emails:
    print(f"{email:30} {'✓' if is_valid_email(email) else '✗'}")
```

### Example 2: Validate Phone Number
```python
import re

def validate_phone(phone):
    """Validate US phone number formats"""
    patterns = [
        r'^\d{3}-\d{3}-\d{4}$',          # 555-123-4567
        r'^\(\d{3}\) \d{3}-\d{4}$',      # (555) 123-4567
        r'^\d{10}$'                       # 5551234567
    ]
    
    return any(re.match(pattern, phone) for pattern in patterns)

# Test
phones = ["555-123-4567", "(555) 123-4567", "5551234567", "123-45-67"]
for phone in phones:
    print(f"{phone:20} {'✓' if validate_phone(phone) else '✗'}")
```

### Example 3: Extract Data from Text
```python
import re

log_entry = "2024-12-07 14:30:45 [ERROR] Failed login attempt from 192.168.1.100"

# Extract components
date_pattern = r'\d{4}-\d{2}-\d{2}'
time_pattern = r'\d{2}:\d{2}:\d{2}'
level_pattern = r'\[(.*?)\]'
ip_pattern = r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'

date = re.search(date_pattern, log_entry).group()
time = re.search(time_pattern, log_entry).group()
level = re.search(level_pattern, log_entry).group(1)
ip = re.search(ip_pattern, log_entry).group()

print(f"Date: {date}")
print(f"Time: {time}")
print(f"Level: {level}")
print(f"IP: {ip}")
```

### Example 4: Clean and Normalize Text
```python
import re

def clean_text(text):
    """Remove special characters and normalize whitespace"""
    # Remove special characters except spaces
    text = re.sub(r'[^a-zA-Z0-9\s]', '', text)
    # Replace multiple spaces with single space
    text = re.sub(r'\s+', ' ', text)
    # Trim
    return text.strip()

# Test
messy_text = "Hello!!!   World???   Python   123"
clean = clean_text(messy_text)
print(clean)  # Hello World Python 123
```

### Example 5: Extract URLs from Text
```python
import re

def extract_urls(text):
    """Extract all URLs from text"""
    pattern = r'https?://[^\s]+'
    return re.findall(pattern, text)

text = """
Visit our website at https://example.com or 
check out http://blog.example.com/post/123
"""

urls = extract_urls(text)
for url in urls:
    print(url)
```

### Example 6: Parse CSV-like Data
```python
import re

def parse_csv_line(line):
    """Parse CSV handling quoted fields with commas"""
    # Pattern: Match quoted strings or non-comma sequences
    pattern = r'"([^"]*)"|([^,]+)'
    matches = re.findall(pattern, line)
    # Flatten tuples and strip whitespace
    return [m[0] or m[1] for m in matches]

csv_line = 'Alice,25,"New York, NY",Engineer'
fields = [f.strip() for f in parse_csv_line(csv_line)]
print(fields)
# ['Alice', '25', 'New York, NY', 'Engineer']
```

### Example 7: Password Strength Validator
```python
import re

def check_password_strength(password):
    """Check password strength with regex"""
    checks = {
        'length': len(password) >= 8,
        'uppercase': bool(re.search(r'[A-Z]', password)),
        'lowercase': bool(re.search(r'[a-z]', password)),
        'digit': bool(re.search(r'\d', password)),
        'special': bool(re.search(r'[!@#$%^&*(),.?":{}|<>]', password))
    }
    
    score = sum(checks.values())
    
    if score == 5:
        return "Strong"
    elif score >= 3:
        return "Medium"
    else:
        return "Weak"

# Test
passwords = ["pass", "Password1", "P@ssw0rd!", "MyP@ssw0rd2024!"]
for pwd in passwords:
    strength = check_password_strength(pwd)
    print(f"{pwd:20} → {strength}")
```

---

## 🎨 Groups and Capturing

### Basic Grouping
```python
import re

# Parentheses create groups
text = "John Doe (john@email.com)"
match = re.search(r'(\w+)\s(\w+)\s\(([^)]+)\)', text)

if match:
    print(match.group(0))  # Full match: John Doe (john@email.com)
    print(match.group(1))  # Group 1: John
    print(match.group(2))  # Group 2: Doe
    print(match.group(3))  # Group 3: john@email.com
```

### Named Groups
```python
import re

text = "2024-12-07"
pattern = r'(?P<year>\d{4})-(?P<month>\d{2})-(?P<day>\d{2})'
match = re.search(pattern, text)

if match:
    print(match.group('year'))   # 2024
    print(match.group('month'))  # 12
    print(match.group('day'))    # 07
    print(match.groupdict())     # {'year': '2024', 'month': '12', 'day': '07'}
```

### Non-Capturing Groups
```python
import re

# (?:...) creates non-capturing group
text = "https://example.com"
pattern = r'(?:https?://)(\w+\.\w+)'
match = re.search(pattern, text)

print(match.group(0))  # https://example.com
print(match.group(1))  # example.com (only capturing group)
```

---

## 🎯 Special Patterns

### Lookahead and Lookbehind
```python
import re

# Positive lookahead (?=...)
text = "I have $100 and €50"
dollars = re.findall(r'\d+(?=\$)', text)  # Numbers followed by $
print(dollars)  # ['100']

# Negative lookahead (?!...)
text = "test123 test456 test_789"
matches = re.findall(r'test(?!_)\w+', text)  # 'test' not followed by _
print(matches)  # ['test123', 'test456']

# Positive lookbehind (?<=...)
text = "$100 and €50"
amounts = re.findall(r'(?<=\$)\d+', text)  # Numbers after $
print(amounts)  # ['100']
```

### Word Boundaries
```python
import re

text = "The theater is the best theater in the city"

# \b matches word boundary
# Find complete word "the" (not in "theater")
matches = re.findall(r'\bthe\b', text, re.IGNORECASE)
print(matches)  # ['The', 'the', 'the']

# Find words starting with "the"
matches = re.findall(r'\bthe\w*', text, re.IGNORECASE)
print(matches)  # ['The', 'theater', 'the', 'theater', 'the']
```

---

## 🚩 Regex Flags

Modify regex behavior.

```python
import re

text = "Hello WORLD\nhello world"

# re.IGNORECASE (re.I) - case-insensitive
print(re.findall(r'hello', text, re.IGNORECASE))  # ['Hello', 'hello']

# re.MULTILINE (re.M) - ^ and $ match line beginnings/ends
pattern = r'^hello'
print(re.findall(pattern, text, re.MULTILINE | re.IGNORECASE))  # ['Hello', 'hello']

# re.DOTALL (re.S) - . matches newline too
text = "Hello\nWorld"
print(re.findall(r'Hello.World', text, re.DOTALL))  # ['Hello\nWorld']

# re.VERBOSE (re.X) - allow comments in pattern
pattern = r'''
    \d{3}    # Area code
    -        # Dash
    \d{4}    # Number
'''
print(re.findall(pattern, "Call 555-1234", re.VERBOSE))  # ['555-1234']
```

---

## ⚠️ Common Pitfalls

### Mistake 1: Forgetting to Escape Special Characters
```python
import re

# ❌ Wrong - . matches any character
text = "file.txt file1txt"
matches = re.findall(r'file.txt', text)
print(matches)  # ['file.txt', 'file1txt'] - BOTH match!

# ✅ Correct - escape the dot
matches = re.findall(r'file\.txt', text)
print(matches)  # ['file.txt'] - Only exact match
```

### Mistake 2: Greedy vs Non-Greedy
```python
import re

html = "<div>Hello</div><div>World</div>"

# ❌ Greedy (default) - matches as much as possible
match = re.search(r'<div>.*</div>', html)
print(match.group())  # <div>Hello</div><div>World</div>

# ✅ Non-greedy - add ? after quantifier
match = re.search(r'<div>.*?</div>', html)
print(match.group())  # <div>Hello</div>
```

### Mistake 3: Not Using Raw Strings
```python
import re

# ❌ Wrong - \d interpreted as escape sequence
pattern = "\d+"  # Python sees this as escape

# ✅ Correct - raw string
pattern = r"\d+"  # Regex sees \d+ literally
```

---

## ✅ Key Takeaways

1. ✅ Regex patterns match text based on rules
2. ✅ Use raw strings (r'...') for regex patterns
3. ✅ `\d` digit, `\w` word char, `\s` whitespace
4. ✅ `+` one or more, `*` zero or more, `?` zero or one
5. ✅ `search()` finds first, `findall()` finds all
6. ✅ `sub()` replaces matches
7. ✅ Groups capture parts of matches
8. ✅ Use `re.compile()` for repeated patterns
9. ✅ Test regex patterns before using in production
10. ✅ Consider alternatives for simple string operations

---

**Practice**: Complete Lab 09 - Working with Regular Expressions

**Next Section**: 13_file_operations.md

**கற்க கசடற** - Learn Flawlessly

