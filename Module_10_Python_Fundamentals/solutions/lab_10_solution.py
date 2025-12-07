"""
Module 10 - Lab 10 Solution: Comprehensive Review
==================================================
Complete solutions integrating all Module 10 concepts.

கற்க கசடற - Learn Flawlessly

Estimated Time: 90 minutes
Concepts: All Module 10 topics integrated
"""

import re
import csv
import json
from pathlib import Path
from datetime import datetime

# Part 1: Data Structures Review (15 minutes)
print("Part 1: Data Structures Review")
print("-" * 60)

# Create sample student data
students = [
    {"id": 1, "name": "Alice Smith", "grades": [85, 90, 88], "major": "CS"},
    {"id": 2, "name": "Bob Johnson", "grades": [78, 82, 80], "major": "Math"},
    {"id": 3, "name": "Charlie Brown", "grades": [92, 95, 90], "major": "CS"},
    {"id": 4, "name": "Diana Prince", "grades": [88, 85, 90], "major": "Physics"},
    {"id": 5, "name": "Eve Davis", "grades": [75, 78, 80], "major": "Math"},
]

# Calculate averages
for student in students:
    avg = sum(student['grades']) / len(student['grades'])
    student['average'] = round(avg, 2)

# Sort by average (descending)
students_sorted = sorted(students, key=lambda s: s['average'], reverse=True)

print("Students by Average Grade:")
for i, student in enumerate(students_sorted, 1):
    print(f"  {i}. {student['name']:<20} {student['major']:<10} Avg: {student['average']}")

# Group by major
by_major = {}
for student in students:
    major = student['major']
    if major not in by_major:
        by_major[major] = []
    by_major[major].append(student)

print(f"\nStudents by Major:")
for major, students_list in sorted(by_major.items()):
    print(f"  {major}: {len(students_list)} students")
    for student in students_list:
        print(f"    - {student['name']} (Avg: {student['average']})")

# Find top student per major
print(f"\nTop Student per Major:")
for major, students_list in sorted(by_major.items()):
    top_student = max(students_list, key=lambda s: s['average'])
    print(f"  {major}: {top_student['name']} ({top_student['average']})")

print()

# Part 2: Functions and Lambda Review (15 minutes)
print("Part 2: Functions and Lambda Review")
print("-" * 60)

def calculate_statistics(numbers):
    """Calculate comprehensive statistics."""
    if not numbers:
        return None
    
    return {
        'count': len(numbers),
        'sum': sum(numbers),
        'mean': sum(numbers) / len(numbers),
        'min': min(numbers),
        'max': max(numbers),
        'range': max(numbers) - min(numbers),
        'median': sorted(numbers)[len(numbers) // 2]
    }

def format_currency(amount, symbol='$'):
    """Format number as currency."""
    return f"{symbol}{amount:,.2f}"

def apply_discount(price, discount_pct):
    """Apply percentage discount."""
    discount = price * (discount_pct / 100)
    final_price = price - discount
    return {
        'original': price,
        'discount_pct': discount_pct,
        'discount_amount': round(discount, 2),
        'final_price': round(final_price, 2)
    }

# Test statistics
grades = [85, 90, 78, 92, 88, 95, 82]
stats = calculate_statistics(grades)

print("Grade Statistics:")
for key, value in stats.items():
    if isinstance(value, float):
        print(f"  {key.capitalize()}: {value:.2f}")
    else:
        print(f"  {key.capitalize()}: {value}")

# Test discount calculator
prices = [100, 250, 500, 1000]
discount = 20

print(f"\n{discount}% Discount on Items:")
for price in prices:
    result = apply_discount(price, discount)
    print(f"  {format_currency(result['original'])} → " +
          f"{format_currency(result['final_price'])} " +
          f"(Save {format_currency(result['discount_amount'])})")

# Lambda examples
numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

squares = list(map(lambda x: x**2, numbers))
evens = list(filter(lambda x: x % 2 == 0, numbers))
sum_all = sum(map(lambda x: x, numbers))

print(f"\nLambda Operations:")
print(f"  Original: {numbers}")
print(f"  Squares: {squares}")
print(f"  Evens: {evens}")
print(f"  Sum: {sum_all}")

print()

# Part 3: String Processing Review (15 minutes)
print("Part 3: String Processing Review")
print("-" * 60)

def parse_email(email):
    """Parse email into components."""
    pattern = r'^([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+)\.([a-zA-Z]{2,})$'
    match = re.match(pattern, email)
    
    if match:
        return {
            'valid': True,
            'local': match.group(1),
            'domain': match.group(2),
            'tld': match.group(3),
            'full': email
        }
    return {'valid': False, 'full': email}

def extract_phone_numbers(text):
    """Extract all phone numbers from text."""
    # Pattern for formats: 123-456-7890, (123) 456-7890, 123.456.7890
    patterns = [
        r'\d{3}-\d{3}-\d{4}',
        r'\(\d{3}\)\s*\d{3}-\d{4}',
        r'\d{3}\.\d{3}\.\d{4}'
    ]
    
    phones = []
    for pattern in patterns:
        phones.extend(re.findall(pattern, text))
    
    return phones

def clean_text(text):
    """Clean and normalize text."""
    # Remove extra whitespace
    text = ' '.join(text.split())
    # Remove special characters except spaces and basic punctuation
    text = re.sub(r'[^a-zA-Z0-9\s.,!?-]', '', text)
    return text.strip()

# Test email parsing
test_emails = [
    "user@example.com",
    "john.doe@company.co.uk",
    "invalid@email",
    "test.user+tag@domain.com"
]

print("Email Parsing:")
for email in test_emails:
    result = parse_email(email)
    if result['valid']:
        print(f"  ✓ {email}")
        print(f"    Local: {result['local']}, Domain: {result['domain']}, TLD: {result['tld']}")
    else:
        print(f"  ✗ {email} - Invalid")

# Test phone extraction
contact_text = """
Contact us at 123-456-7890 or (555) 123-4567.
Alternative: 987.654.3210
"""

phones = extract_phone_numbers(contact_text)
print(f"\nExtracted Phone Numbers:")
for phone in phones:
    print(f"  - {phone}")

# Test text cleaning
dirty_text = "  Hello!!!   This  is  a   test@#$%^   message!!!  "
clean = clean_text(dirty_text)
print(f"\nText Cleaning:")
print(f"  Original: '{dirty_text}'")
print(f"  Cleaned:  '{clean}'")

print()

# Part 4: File Operations Review (15 minutes)
print("Part 4: File Operations Review")
print("-" * 60)

def save_data_as_json(data, filename):
    """Save data as JSON file."""
    try:
        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)
        return True
    except Exception as e:
        print(f"Error saving JSON: {e}")
        return False

def load_data_from_json(filename):
    """Load data from JSON file."""
    try:
        with open(filename, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"File not found: {filename}")
        return None
    except json.JSONDecodeError:
        print(f"Invalid JSON in file: {filename}")
        return None

def export_to_csv(data, filename, fieldnames):
    """Export data to CSV file."""
    try:
        with open(filename, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(data)
        return True
    except Exception as e:
        print(f"Error exporting CSV: {e}")
        return False

# Save student data as JSON
json_file = Path("students.json")
if save_data_as_json(students, json_file):
    print(f"✓ Saved data to {json_file}")

# Load and verify
loaded_students = load_data_from_json(json_file)
if loaded_students:
    print(f"✓ Loaded {len(loaded_students)} students from JSON")

# Export to CSV
csv_file = Path("students.csv")
fieldnames = ['id', 'name', 'major', 'average']
csv_data = [
    {
        'id': s['id'],
        'name': s['name'],
        'major': s['major'],
        'average': s['average']
    }
    for s in students
]

if export_to_csv(csv_data, csv_file, fieldnames):
    print(f"✓ Exported data to {csv_file}")

# Read and display CSV
print(f"\nCSV Contents:")
with open(csv_file, 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        print(f"  {row['id']}: {row['name']:<20} {row['major']:<10} {row['average']}")

# Cleanup
json_file.unlink()
csv_file.unlink()

print()

# Part 5: Error Handling Review (15 minutes)
print("Part 5: Error Handling Review")
print("-" * 60)

class ValidationError(Exception):
    """Custom validation exception."""
    pass

def validate_user_input(data):
    """Validate user input with comprehensive checks."""
    errors = []
    
    # Check name
    if 'name' not in data or not data['name'].strip():
        errors.append("Name is required")
    elif len(data['name']) < 2:
        errors.append("Name must be at least 2 characters")
    
    # Check email
    if 'email' not in data:
        errors.append("Email is required")
    else:
        email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(email_pattern, data['email']):
            errors.append("Invalid email format")
    
    # Check age
    if 'age' not in data:
        errors.append("Age is required")
    elif not isinstance(data['age'], int):
        errors.append("Age must be an integer")
    elif data['age'] < 0 or data['age'] > 150:
        errors.append("Age must be between 0 and 150")
    
    if errors:
        raise ValidationError(f"Validation failed: {', '.join(errors)}")
    
    return True

def safe_process_user(user_data):
    """Safely process user data with error handling."""
    try:
        validate_user_input(user_data)
        
        # Process data
        processed = {
            'name': user_data['name'].strip().title(),
            'email': user_data['email'].lower(),
            'age': user_data['age'],
            'status': 'active',
            'created_at': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }
        
        print(f"  ✓ Processed user: {processed['name']}")
        return processed
    
    except ValidationError as e:
        print(f"  ✗ Validation error: {e}")
        return None
    except Exception as e:
        print(f"  ✗ Unexpected error: {e}")
        return None

# Test with various inputs
test_users = [
    {'name': 'Alice Smith', 'email': 'alice@example.com', 'age': 30},  # Valid
    {'name': 'A', 'email': 'bob@example.com', 'age': 25},              # Invalid name
    {'name': 'Charlie', 'email': 'invalid-email', 'age': 35},          # Invalid email
    {'name': 'Diana', 'email': 'diana@example.com', 'age': -5},        # Invalid age
    {'email': 'eve@example.com', 'age': 28},                           # Missing name
]

print("Processing User Data:")
for user in test_users:
    safe_process_user(user)

print()

# Part 6: Integrated Challenge - Student Management System (30 minutes)
print("Part 6: Integrated Challenge - Student Management System")
print("-" * 60)

class StudentManagementSystem:
    """Complete student management system."""
    
    def __init__(self):
        self.students = []
        self.next_id = 1
    
    def add_student(self, name, major, grades=None):
        """Add new student with validation."""
        try:
            # Validate inputs
            if not name or not name.strip():
                raise ValueError("Name cannot be empty")
            
            if not major or not major.strip():
                raise ValueError("Major cannot be empty")
            
            if grades is None:
                grades = []
            
            if not isinstance(grades, list):
                raise TypeError("Grades must be a list")
            
            if grades and not all(isinstance(g, (int, float)) and 0 <= g <= 100 for g in grades):
                raise ValueError("Grades must be numbers between 0 and 100")
            
            # Create student
            student = {
                'id': self.next_id,
                'name': name.strip().title(),
                'major': major.strip().upper(),
                'grades': grades,
                'average': sum(grades) / len(grades) if grades else 0,
                'status': 'active'
            }
            
            self.students.append(student)
            self.next_id += 1
            
            print(f"  ✓ Added student: {student['name']} (ID: {student['id']})")
            return student['id']
        
        except (ValueError, TypeError) as e:
            print(f"  ✗ Error adding student: {e}")
            return None
    
    def get_student(self, student_id):
        """Get student by ID."""
        for student in self.students:
            if student['id'] == student_id:
                return student
        return None
    
    def update_grades(self, student_id, new_grades):
        """Update student grades."""
        student = self.get_student(student_id)
        if not student:
            print(f"  ✗ Student ID {student_id} not found")
            return False
        
        try:
            if not all(isinstance(g, (int, float)) and 0 <= g <= 100 for g in new_grades):
                raise ValueError("Invalid grades")
            
            student['grades'] = new_grades
            student['average'] = sum(new_grades) / len(new_grades) if new_grades else 0
            
            print(f"  ✓ Updated grades for {student['name']}")
            return True
        
        except ValueError as e:
            print(f"  ✗ Error updating grades: {e}")
            return False
    
    def get_top_students(self, n=5):
        """Get top N students by average."""
        sorted_students = sorted(
            [s for s in self.students if s['grades']],
            key=lambda s: s['average'],
            reverse=True
        )
        return sorted_students[:n]
    
    def get_students_by_major(self, major):
        """Get all students in a major."""
        return [s for s in self.students if s['major'] == major.upper()]
    
    def generate_report(self):
        """Generate comprehensive report."""
        print(f"\n{'='*70}")
        print("STUDENT MANAGEMENT SYSTEM REPORT")
        print(f"{'='*70}")
        print(f"Total Students: {len(self.students)}")
        
        if not self.students:
            print("No students in system.")
            print(f"{'='*70}")
            return
        
        # Statistics
        students_with_grades = [s for s in self.students if s['grades']]
        if students_with_grades:
            overall_avg = sum(s['average'] for s in students_with_grades) / len(students_with_grades)
            print(f"Overall Average: {overall_avg:.2f}")
        
        # By major
        majors = set(s['major'] for s in self.students)
        print(f"\nBy Major:")
        for major in sorted(majors):
            major_students = self.get_students_by_major(major)
            avg = sum(s['average'] for s in major_students if s['grades']) / len([s for s in major_students if s['grades']]) if any(s['grades'] for s in major_students) else 0
            print(f"  {major}: {len(major_students)} students (Avg: {avg:.2f})")
        
        # Top students
        print(f"\nTop 5 Students:")
        for i, student in enumerate(self.get_top_students(5), 1):
            print(f"  {i}. {student['name']:<25} {student['major']:<8} Avg: {student['average']:.2f}")
        
        print(f"{'='*70}")
    
    def export_data(self, filename):
        """Export all data to JSON."""
        try:
            data = {
                'students': self.students,
                'total_count': len(self.students),
                'export_date': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            }
            
            with open(filename, 'w') as f:
                json.dump(data, f, indent=2)
            
            print(f"  ✓ Exported data to {filename}")
            return True
        except Exception as e:
            print(f"  ✗ Export failed: {e}")
            return False

# Test the system
print("\n1. Creating Student Management System")
sms = StudentManagementSystem()

print("\n2. Adding Students")
sms.add_student("Alice Smith", "Computer Science", [85, 90, 88, 92])
sms.add_student("Bob Johnson", "Mathematics", [78, 82, 80, 85])
sms.add_student("Charlie Brown", "Computer Science", [92, 95, 90, 93])
sms.add_student("Diana Prince", "Physics", [88, 85, 90, 87])
sms.add_student("Eve Davis", "Mathematics", [75, 78, 80, 82])
sms.add_student("Frank Miller", "Computer Science", [95, 98, 92, 96])

# Try invalid additions
sms.add_student("", "CS", [80])  # Empty name
sms.add_student("Test", "CS", [150])  # Invalid grade

print("\n3. Updating Grades")
sms.update_grades(1, [90, 92, 89, 94])

print("\n4. Querying Students")
cs_students = sms.get_students_by_major("Computer Science")
print(f"\nComputer Science Students: {len(cs_students)}")
for student in cs_students:
    print(f"  - {student['name']} (Avg: {student['average']:.2f})")

print("\n5. Generating Report")
sms.generate_report()

print("\n6. Exporting Data")
export_file = Path("sms_export.json")
sms.export_data(export_file)

# Cleanup
if export_file.exists():
    export_file.unlink()

print()

# ============================================================================
# Verification Code
# ============================================================================

def verify_lab_10():
    """Verify comprehensive review exercises."""
    print("\n" + "="*60)
    print("Lab 10 Comprehensive Review Verification")
    print("="*60)
    
    passed = 0
    total = 6
    
    # Test statistics function
    try:
        stats = calculate_statistics([10, 20, 30])
        assert stats['mean'] == 20, "Mean wrong"
        assert stats['min'] == 10, "Min wrong"
        assert stats['max'] == 30, "Max wrong"
        
        print("✅ Statistics functions - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Statistics functions - FAILED: {e}")
    
    # Test string processing
    try:
        email = parse_email("test@example.com")
        assert email['valid'] == True, "Email validation wrong"
        assert email['local'] == "test", "Local part wrong"
        
        print("✅ String processing - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ String processing - FAILED: {e}")
    
    # Test file operations
    try:
        test_data = {'test': 'value'}
        test_file = Path("test_verify.json")
        
        assert save_data_as_json(test_data, test_file), "Save failed"
        loaded = load_data_from_json(test_file)
        assert loaded == test_data, "Load failed"
        
        test_file.unlink()
        
        print("✅ File operations - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ File operations - FAILED: {e}")
    
    # Test validation
    try:
        valid_user = {
            'name': 'Test User',
            'email': 'test@example.com',
            'age': 25
        }
        
        assert validate_user_input(valid_user), "Valid user rejected"
        
        invalid_user = {'name': '', 'email': 'invalid', 'age': -5}
        try:
            validate_user_input(invalid_user)
            assert False, "Invalid user accepted"
        except ValidationError:
            pass  # Expected
        
        print("✅ Input validation - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Input validation - FAILED: {e}")
    
    # Test StudentManagementSystem
    try:
        test_sms = StudentManagementSystem()
        
        id1 = test_sms.add_student("Test Student", "CS", [85, 90])
        assert id1 is not None, "Add student failed"
        
        student = test_sms.get_student(id1)
        assert student is not None, "Get student failed"
        assert student['name'] == "Test Student", "Name wrong"
        
        assert test_sms.update_grades(id1, [95, 90]), "Update grades failed"
        student = test_sms.get_student(id1)
        assert student['average'] == 92.5, "Average wrong"
        
        print("✅ Student Management System - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Student Management System - FAILED: {e}")
    
    # Test integration
    try:
        # Create data
        test_sms = StudentManagementSystem()
        test_sms.add_student("Alice", "CS", [85, 90, 88])
        test_sms.add_student("Bob", "Math", [78, 82, 80])
        
        # Export
        export_file = Path("test_export.json")
        assert test_sms.export_data(export_file), "Export failed"
        
        # Verify export
        with open(export_file, 'r') as f:
            data = json.load(f)
        
        assert 'students' in data, "Export format wrong"
        assert len(data['students']) == 2, "Student count wrong"
        
        export_file.unlink()
        
        print("✅ Integration test - PASSED")
        passed += 1
    except (AssertionError, NameError, Exception) as e:
        print(f"❌ Integration test - FAILED: {e}")
    
    print("="*60)
    print(f"Score: {passed}/{total} ({passed/total*100:.0f}%)")
    print("="*60)
    
    if passed == total:
        print("🎉 Outstanding! All comprehensive tests passed!")
        print("\n📚 Skills Mastered:")
        print("  ✓ Data structures and manipulation")
        print("  ✓ Functions and lambda expressions")
        print("  ✓ String processing and regex")
        print("  ✓ File I/O with CSV and JSON")
        print("  ✓ Error handling and validation")
        print("  ✓ Object-oriented design patterns")
        print("  ✓ System integration")
        print("\n🚀 Next Steps:")
        print("  - Try Lab 11: Capstone Project")
        print("  - Review any challenging concepts")
        print("  - Prepare for Module 11: Advanced Python & OOP")
    else:
        print("📝 Good progress! Review challenging areas and try again.")

# Run verification
verify_lab_10()
