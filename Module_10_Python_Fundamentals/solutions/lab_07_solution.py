"""
Module 10 - Lab 07 Solution: Strings and Regular Expressions
=============================================================
Complete solutions with explanations.

கற்க கசடற - Learn Flawlessly

Estimated Time: 60 minutes
Concepts: String methods, formatting, slicing, regex patterns
"""

import re

# Part 1: String Basics (10 minutes)
print("Part 1: String Basics")
print("-" * 40)

# String creation
single = 'Hello'
double = "World"
triple = """This is a
multi-line string"""

print(f"Single quotes: {single}")
print(f"Double quotes: {double}")
print(f"Triple quotes:\n{triple}")

# String concatenation
full_name = "John" + " " + "Doe"
print(f"\nConcatenation: {full_name}")

# String repetition
separator = "-" * 40
print(f"\nRepetition:\n{separator}")

# String indexing and slicing
text = "Python Programming"
print(f"\nOriginal: {text}")
print(f"First char: {text[0]}")
print(f"Last char: {text[-1]}")
print(f"First 6: {text[:6]}")
print(f"Last 11: {text[-11:]}")
print(f"Every 2nd: {text[::2]}")
print(f"Reversed: {text[::-1]}")

print()

# Part 2: String Methods (15 minutes)
print("Part 2: String Methods")
print("-" * 40)

text = "  Hello, World!  "
print(f"Original: '{text}'")
print(f"Upper: '{text.upper()}'")
print(f"Lower: '{text.lower()}'")
print(f"Title: '{text.title()}'")
print(f"Strip: '{text.strip()}'")
print(f"Replace: '{text.replace('World', 'Python')}'")

# Checking methods
email = "user@example.com"
print(f"\nEmail: {email}")
print(f"Starts with 'user': {email.startswith('user')}")
print(f"Ends with '.com': {email.endswith('.com')}")
print(f"Contains '@': {'@' in email}")

# Split and join
sentence = "Python is awesome"
words = sentence.split()
print(f"\nSentence: {sentence}")
print(f"Words: {words}")
print(f"Joined with '-': {'-'.join(words)}")

# Find and count
text = "Python is fun. Python is powerful."
print(f"\nText: {text}")
print(f"'Python' count: {text.count('Python')}")
print(f"First 'Python' at: {text.find('Python')}")
print(f"Last 'Python' at: {text.rfind('Python')}")

print()

# Part 3: String Formatting (10 minutes)
print("Part 3: String Formatting")
print("-" * 40)

name = "Alice"
age = 30
salary = 75000.50

# f-strings (Python 3.6+)
print(f"Name: {name}, Age: {age}")
print(f"Salary: ${salary:,.2f}")
print(f"Calculation: {5 + 3} = 8")

# Format method
print("\n{} is {} years old".format(name, age))
print("Salary: ${:,.2f}".format(salary))
print("{name} earns ${salary:,.2f}".format(name=name, salary=salary))

# Alignment and padding
print(f"\n{'Left':<10}|")
print(f"{'Center':^10}|")
print(f"{'Right':>10}|")

# Number formatting
number = 1234.56789
print(f"\nOriginal: {number}")
print(f"2 decimals: {number:.2f}")
print(f"Percentage: {0.856:.1%}")
print(f"Scientific: {number:.2e}")

print()

# Part 4: Regular Expressions Basics (15 minutes)
print("Part 4: Regular Expressions Basics")
print("-" * 40)

# Simple pattern matching
text = "The price is $99.99"
pattern = r'\$\d+\.\d+'
match = re.search(pattern, text)
if match:
    print(f"Found: {match.group()}")

# Find all matches
text = "Call me at 123-456-7890 or 987-654-3210"
pattern = r'\d{3}-\d{3}-\d{4}'
phones = re.findall(pattern, text)
print(f"\nPhone numbers found: {phones}")

# Splitting with regex
text = "apple,banana;cherry:date"
fruits = re.split(r'[,;:]', text)
print(f"\nFruits: {fruits}")

# Substitution
text = "Visit example.com or test.example.com"
censored = re.sub(r'\w+\.com', '[REDACTED]', text)
print(f"\nCensored: {censored}")

# Character classes
text = "abc123XYZ"
print(f"\nText: {text}")
print(f"Digits: {re.findall(r'\d', text)}")
print(f"Letters: {re.findall(r'[a-zA-Z]', text)}")
print(f"Lowercase: {re.findall(r'[a-z]', text)}")
print(f"Uppercase: {re.findall(r'[A-Z]', text)}")

print()

# Part 5: Email Validation (10 minutes)
print("Part 5: Email Validation")
print("-" * 40)

def validate_email(email: str) -> bool:
    """
    Validate email address using regex.
    Pattern: local@domain.extension
    """
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))

# Test cases
test_emails = [
    "user@example.com",      # Valid
    "test.user@example.co.uk",  # Valid
    "invalid.email",         # Invalid - no @
    "@example.com",          # Invalid - no local part
    "user@",                 # Invalid - no domain
    "user @example.com",     # Invalid - space
    "user@example",          # Invalid - no extension
]

for email in test_emails:
    result = "✓ Valid" if validate_email(email) else "✗ Invalid"
    print(f"{email:30} {result}")

print()

# Part 6: Password Strength Checker (10 minutes)
print("Part 6: Password Strength Checker")
print("-" * 40)

def check_password_strength(password: str) -> dict:
    """
    Check password strength.
    Requirements:
    - At least 8 characters
    - Contains uppercase letter
    - Contains lowercase letter
    - Contains digit
    - Contains special character
    """
    checks = {
        'length': len(password) >= 8,
        'uppercase': bool(re.search(r'[A-Z]', password)),
        'lowercase': bool(re.search(r'[a-z]', password)),
        'digit': bool(re.search(r'\d', password)),
        'special': bool(re.search(r'[!@#$%^&*(),.?":{}|<>]', password)),
    }
    
    passed = sum(checks.values())
    
    if passed == 5:
        strength = "Strong"
    elif passed >= 3:
        strength = "Medium"
    else:
        strength = "Weak"
    
    return {
        'strength': strength,
        'checks': checks,
        'score': passed
    }

# Test passwords
test_passwords = [
    "password",           # Weak
    "Password123",        # Medium
    "P@ssw0rd!",         # Strong
    "12345678",          # Weak
    "MySecureP@ss123",   # Strong
]

for pwd in test_passwords:
    result = check_password_strength(pwd)
    print(f"\nPassword: {'*' * len(pwd)} ({pwd})")
    print(f"Strength: {result['strength']} ({result['score']}/5)")
    print(f"  Length ≥8: {'✓' if result['checks']['length'] else '✗'}")
    print(f"  Uppercase: {'✓' if result['checks']['uppercase'] else '✗'}")
    print(f"  Lowercase: {'✓' if result['checks']['lowercase'] else '✗'}")
    print(f"  Digit: {'✓' if result['checks']['digit'] else '✗'}")
    print(f"  Special: {'✓' if result['checks']['special'] else '✗'}")

print()

# Part 7: Practical Challenge - Log Parser (15 minutes)
print("Part 7: Practical Challenge - Log Parser")
print("-" * 40)

def parse_log_entry(log_line: str) -> dict:
    """
    Parse log entry in format:
    [TIMESTAMP] LEVEL: Message
    Example: [2024-01-15 10:30:45] ERROR: Connection failed
    """
    pattern = r'\[([^\]]+)\]\s+(\w+):\s+(.+)'
    match = re.match(pattern, log_line)
    
    if match:
        return {
            'timestamp': match.group(1),
            'level': match.group(2),
            'message': match.group(3)
        }
    return None

def analyze_logs(log_lines: list) -> dict:
    """Analyze log file and generate statistics."""
    stats = {
        'total': len(log_lines),
        'by_level': {},
        'errors': [],
        'warnings': []
    }
    
    for line in log_lines:
        entry = parse_log_entry(line)
        if entry:
            level = entry['level']
            
            # Count by level
            stats['by_level'][level] = stats['by_level'].get(level, 0) + 1
            
            # Collect errors and warnings
            if level == 'ERROR':
                stats['errors'].append(entry)
            elif level == 'WARNING':
                stats['warnings'].append(entry)
    
    return stats

# Sample log data
log_data = [
    "[2024-01-15 10:30:45] INFO: Application started",
    "[2024-01-15 10:30:50] DEBUG: Loading configuration",
    "[2024-01-15 10:31:00] ERROR: Connection to database failed",
    "[2024-01-15 10:31:05] WARNING: Retrying connection",
    "[2024-01-15 10:31:10] INFO: Connection established",
    "[2024-01-15 10:31:15] DEBUG: Processing request",
    "[2024-01-15 10:31:20] ERROR: Invalid user credentials",
    "[2024-01-15 10:31:25] WARNING: High memory usage detected",
    "[2024-01-15 10:31:30] INFO: Request completed",
]

print("Log Analysis:")
print("-" * 60)

# Parse and display logs
for line in log_data:
    entry = parse_log_entry(line)
    if entry:
        level_format = {
            'ERROR': '\033[91m',    # Red
            'WARNING': '\033[93m',  # Yellow
            'INFO': '\033[92m',     # Green
            'DEBUG': '\033[94m',    # Blue
        }
        color = level_format.get(entry['level'], '')
        reset = '\033[0m'
        print(f"{entry['timestamp']} | {color}{entry['level']:<7}{reset} | {entry['message']}")

# Generate statistics
stats = analyze_logs(log_data)

print(f"\n{'='*60}")
print("Statistics:")
print(f"{'='*60}")
print(f"Total Entries: {stats['total']}")
print(f"\nBreakdown by Level:")
for level, count in sorted(stats['by_level'].items()):
    percentage = (count / stats['total']) * 100
    print(f"  {level:<10} {count:>3} ({percentage:>5.1f}%)")

print(f"\nErrors ({len(stats['errors'])}):")
for error in stats['errors']:
    print(f"  [{error['timestamp']}] {error['message']}")

print(f"\nWarnings ({len(stats['warnings'])}):")
for warning in stats['warnings']:
    print(f"  [{warning['timestamp']}] {warning['message']}")

print()

# ============================================================================
# Verification Code
# ============================================================================

def verify_lab_07():
    """Verify that all lab exercises are completed correctly."""
    print("\n" + "="*60)
    print("Lab 07 Verification")
    print("="*60)
    
    passed = 0
    total = 7
    
    # Test string operations
    try:
        text = "Python"
        assert text.upper() == "PYTHON", "Upper wrong"
        assert text.lower() == "python", "Lower wrong"
        assert "Hello World".split() == ["Hello", "World"], "Split wrong"
        assert "-".join(["a", "b"]) == "a-b", "Join wrong"
        
        print("✅ String operations - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ String operations - FAILED: {e}")
    
    # Test string formatting
    try:
        name = "Test"
        age = 25
        assert f"{name} is {age}" == "Test is 25", "f-string wrong"
        assert f"{3.14159:.2f}" == "3.14", "Formatting wrong"
        
        print("✅ String formatting - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ String formatting - FAILED: {e}")
    
    # Test regex basics
    try:
        text = "Price: $99.99"
        matches = re.findall(r'\d+\.\d+', text)
        assert len(matches) == 1, "Regex find wrong"
        assert matches[0] == "99.99", "Regex value wrong"
        
        # Phone number
        phones = re.findall(r'\d{3}-\d{3}-\d{4}', "Call 123-456-7890")
        assert len(phones) == 1, "Phone regex wrong"
        
        print("✅ Regex basics - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Regex basics - FAILED: {e}")
    
    # Test email validation
    try:
        assert validate_email("user@example.com") == True, "Valid email failed"
        assert validate_email("invalid.email") == False, "Invalid email passed"
        assert validate_email("@example.com") == False, "No local part passed"
        assert validate_email("user@example") == False, "No extension passed"
        
        print("✅ Email validation - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Email validation - FAILED: {e}")
    
    # Test password strength
    try:
        weak = check_password_strength("password")
        assert weak['strength'] == "Weak", "Weak password wrong"
        
        strong = check_password_strength("P@ssw0rd!")
        assert strong['strength'] == "Strong", "Strong password wrong"
        assert strong['score'] == 5, "Strong score wrong"
        
        print("✅ Password strength - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Password strength - FAILED: {e}")
    
    # Test log parsing
    try:
        log = "[2024-01-15 10:30:45] ERROR: Test message"
        entry = parse_log_entry(log)
        
        assert entry is not None, "Parse returned None"
        assert entry['timestamp'] == "2024-01-15 10:30:45", "Timestamp wrong"
        assert entry['level'] == "ERROR", "Level wrong"
        assert entry['message'] == "Test message", "Message wrong"
        
        print("✅ Log parsing - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Log parsing - FAILED: {e}")
    
    # Test log analysis
    try:
        logs = [
            "[2024-01-15 10:30:45] ERROR: Error 1",
            "[2024-01-15 10:30:50] WARNING: Warning 1",
            "[2024-01-15 10:30:55] INFO: Info 1",
        ]
        
        stats = analyze_logs(logs)
        
        assert stats['total'] == 3, f"Total wrong: {stats['total']}"
        assert stats['by_level']['ERROR'] == 1, "Error count wrong"
        assert len(stats['errors']) == 1, "Errors list wrong"
        assert len(stats['warnings']) == 1, "Warnings list wrong"
        
        print("✅ Log analysis - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Log analysis - FAILED: {e}")
    
    print("="*60)
    print(f"Score: {passed}/{total} ({passed/total*100:.0f}%)")
    print("="*60)
    
    if passed == total:
        print("🎉 Congratulations! All tests passed!")
        print("\n📚 Key Learnings:")
        print("  1. String methods for manipulation")
        print("  2. f-strings for formatting")
        print("  3. Regular expressions for pattern matching")
        print("  4. Email validation with regex")
        print("  5. Password strength checking")
        print("  6. Log parsing with patterns")
        print("  7. Text processing and analysis")
        print("\n🚀 Next Steps:")
        print("  - Try Lab 08: File Operations")
        print("  - Review Sections 11-12: Strings and Regex")
        print("  - Practice more complex regex patterns")
    else:
        print("📝 Keep practicing! Review the sections and try again.")

# Run verification
verify_lab_07()
