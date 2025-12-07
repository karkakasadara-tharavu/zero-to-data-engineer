"""
Module 10 - Lab 08 Solution: File Operations
=============================================
Complete solutions with explanations.

கற்க கசடற - Learn Flawlessly

Estimated Time: 60 minutes
Concepts: File I/O, CSV processing, JSON handling, pathlib
"""

import csv
import json
from pathlib import Path
import os

# Part 1: Basic File Operations (10 minutes)
print("Part 1: Basic File Operations")
print("-" * 40)

# Create a sample text file
sample_content = """Line 1: Python is awesome
Line 2: File operations are easy
Line 3: Practice makes perfect"""

file_path = Path("sample_output.txt")
file_path.write_text(sample_content)
print(f"Created: {file_path}")

# Reading entire file
content = file_path.read_text()
print(f"\nFull content:\n{content}")

# Reading line by line
print(f"\nReading line by line:")
with open(file_path, 'r') as f:
    for line_num, line in enumerate(f, 1):
        print(f"  Line {line_num}: {line.strip()}")

# Appending to file
with open(file_path, 'a') as f:
    f.write("\nLine 4: Appended content")

print(f"\nAfter appending:")
print(file_path.read_text())

# Clean up
file_path.unlink()
print(f"\nDeleted: {file_path}")

print()

# Part 2: Working with CSV Files (15 minutes)
print("Part 2: Working with CSV Files")
print("-" * 40)

# Create sample CSV
csv_file = Path("employees.csv")
employees = [
    {"name": "Alice Smith", "department": "Engineering", "salary": 95000},
    {"name": "Bob Johnson", "department": "Marketing", "salary": 75000},
    {"name": "Charlie Brown", "department": "Engineering", "salary": 88000},
    {"name": "Diana Prince", "department": "Sales", "salary": 82000},
    {"name": "Eve Davis", "department": "HR", "salary": 70000},
]

# Write CSV
with open(csv_file, 'w', newline='') as f:
    fieldnames = ["name", "department", "salary"]
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(employees)

print(f"Created: {csv_file}")

# Read CSV
print(f"\nReading CSV:")
with open(csv_file, 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        print(f"  {row['name']:<20} {row['department']:<15} ${int(row['salary']):>8,}")

# Calculate average salary by department
dept_salaries = {}
with open(csv_file, 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        dept = row['department']
        salary = int(row['salary'])
        if dept not in dept_salaries:
            dept_salaries[dept] = []
        dept_salaries[dept].append(salary)

print(f"\nAverage salary by department:")
for dept, salaries in sorted(dept_salaries.items()):
    avg = sum(salaries) / len(salaries)
    print(f"  {dept:<15} ${avg:>10,.2f}")

# Filter high earners (>$80,000)
high_earners_file = Path("high_earners.csv")
with open(csv_file, 'r') as infile, open(high_earners_file, 'w', newline='') as outfile:
    reader = csv.DictReader(infile)
    writer = csv.DictWriter(outfile, fieldnames=["name", "department", "salary"])
    writer.writeheader()
    
    for row in reader:
        if int(row['salary']) > 80000:
            writer.writerow(row)

print(f"\nFiltered high earners to: {high_earners_file}")
with open(high_earners_file, 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        print(f"  {row['name']:<20} ${int(row['salary']):>8,}")

# Clean up
csv_file.unlink()
high_earners_file.unlink()

print()

# Part 3: Working with JSON Files (15 minutes)
print("Part 3: Working with JSON Files")
print("-" * 40)

# Create sample JSON data
products = {
    "products": [
        {
            "id": 1,
            "name": "Laptop",
            "price": 1299.99,
            "in_stock": True,
            "specs": {"ram": "16GB", "storage": "512GB SSD"}
        },
        {
            "id": 2,
            "name": "Mouse",
            "price": 29.99,
            "in_stock": True,
            "specs": {"type": "Wireless", "dpi": 1600}
        },
        {
            "id": 3,
            "name": "Keyboard",
            "price": 89.99,
            "in_stock": False,
            "specs": {"type": "Mechanical", "switches": "Cherry MX"}
        }
    ]
}

# Write JSON
json_file = Path("products.json")
with open(json_file, 'w') as f:
    json.dump(products, f, indent=2)

print(f"Created: {json_file}")

# Read JSON
with open(json_file, 'r') as f:
    data = json.load(f)

print(f"\nProducts in stock:")
for product in data['products']:
    if product['in_stock']:
        print(f"  {product['name']:<15} ${product['price']:>8.2f}")

# Calculate total inventory value
total_value = sum(p['price'] for p in data['products'] if p['in_stock'])
print(f"\nTotal inventory value: ${total_value:,.2f}")

# Add new product
new_product = {
    "id": 4,
    "name": "Monitor",
    "price": 349.99,
    "in_stock": True,
    "specs": {"size": "27 inch", "resolution": "2560x1440"}
}
data['products'].append(new_product)

# Save updated JSON
with open(json_file, 'w') as f:
    json.dump(data, f, indent=2)

print(f"\nAdded new product. Updated {json_file}")

# Pretty print JSON structure
print(f"\nJSON structure:")
print(json.dumps(data, indent=2))

# Clean up
json_file.unlink()

print()

# Part 4: Using pathlib (10 minutes)
print("Part 4: Using pathlib")
print("-" * 40)

# Create directory structure
base_dir = Path("test_project")
base_dir.mkdir(exist_ok=True)

subdirs = ["src", "tests", "docs", "data"]
for subdir in subdirs:
    (base_dir / subdir).mkdir(exist_ok=True)

print(f"Created directory structure:")
for item in sorted(base_dir.rglob("*")):
    if item.is_dir():
        print(f"  📁 {item.relative_to(base_dir.parent)}")

# Create files
(base_dir / "README.md").write_text("# Test Project\n\nThis is a test.")
(base_dir / "src" / "main.py").write_text("print('Hello, World!')")
(base_dir / "tests" / "test_main.py").write_text("def test_example(): pass")

print(f"\nCreated files:")
for item in sorted(base_dir.rglob("*")):
    if item.is_file():
        size = item.stat().st_size
        print(f"  📄 {item.relative_to(base_dir.parent)} ({size} bytes)")

# File operations with pathlib
readme = base_dir / "README.md"
print(f"\nFile info for {readme.name}:")
print(f"  Exists: {readme.exists()}")
print(f"  Is file: {readme.is_file()}")
print(f"  Absolute path: {readme.absolute()}")
print(f"  Parent: {readme.parent}")
print(f"  Stem: {readme.stem}")
print(f"  Suffix: {readme.suffix}")

# List Python files
print(f"\nPython files:")
for py_file in base_dir.rglob("*.py"):
    print(f"  {py_file.relative_to(base_dir)}")

# Clean up
import shutil
shutil.rmtree(base_dir)
print(f"\nCleaned up: {base_dir}")

print()

# Part 5: Error Handling with Files (10 minutes)
print("Part 5: Error Handling with Files")
print("-" * 40)

def safe_read_file(filepath: Path) -> str:
    """Safely read file with error handling."""
    try:
        return filepath.read_text()
    except FileNotFoundError:
        return f"Error: File not found: {filepath}"
    except PermissionError:
        return f"Error: Permission denied: {filepath}"
    except Exception as e:
        return f"Error: {str(e)}"

# Test with non-existent file
print(safe_read_file(Path("nonexistent.txt")))

# Create and read valid file
test_file = Path("test.txt")
test_file.write_text("Test content")
print(f"\n{test_file}: {safe_read_file(test_file)}")
test_file.unlink()

# Safe write function
def safe_write_file(filepath: Path, content: str) -> bool:
    """Safely write file with error handling."""
    try:
        filepath.write_text(content)
        return True
    except Exception as e:
        print(f"Error writing file: {e}")
        return False

test_file = Path("output.txt")
if safe_write_file(test_file, "Safe write test"):
    print(f"\nSuccessfully wrote to {test_file}")
    test_file.unlink()

print()

# Part 6: Practical Challenge - Log File Analyzer (15 minutes)
print("Part 6: Practical Challenge - Log File Analyzer")
print("-" * 40)

def create_sample_log():
    """Create sample log file."""
    log_entries = [
        "2024-01-15 10:00:00 INFO Server started",
        "2024-01-15 10:00:05 DEBUG Loading configuration",
        "2024-01-15 10:00:10 INFO Connected to database",
        "2024-01-15 10:00:15 WARNING High memory usage: 85%",
        "2024-01-15 10:00:20 ERROR Failed to connect to API",
        "2024-01-15 10:00:25 ERROR Database connection lost",
        "2024-01-15 10:00:30 INFO Retrying connection",
        "2024-01-15 10:00:35 INFO Connection restored",
        "2024-01-15 10:00:40 WARNING Slow query detected (2.5s)",
        "2024-01-15 10:00:45 DEBUG Processing request",
    ]
    
    log_file = Path("application.log")
    log_file.write_text("\n".join(log_entries))
    return log_file

def analyze_log_file(log_file: Path) -> dict:
    """
    Analyze log file and return statistics.
    
    Returns:
        dict with counts, errors, warnings, and summary
    """
    stats = {
        'total_lines': 0,
        'by_level': {'INFO': 0, 'DEBUG': 0, 'WARNING': 0, 'ERROR': 0},
        'errors': [],
        'warnings': []
    }
    
    try:
        with open(log_file, 'r') as f:
            for line in f:
                stats['total_lines'] += 1
                
                # Parse level
                for level in stats['by_level'].keys():
                    if level in line:
                        stats['by_level'][level] += 1
                        
                        if level == 'ERROR':
                            stats['errors'].append(line.strip())
                        elif level == 'WARNING':
                            stats['warnings'].append(line.strip())
                        break
        
        return stats
    
    except Exception as e:
        print(f"Error analyzing log: {e}")
        return stats

def generate_report(stats: dict, output_file: Path):
    """Generate analysis report."""
    report_lines = [
        "="*60,
        "LOG ANALYSIS REPORT",
        "="*60,
        f"\nTotal Entries: {stats['total_lines']}",
        "\nBreakdown by Level:",
    ]
    
    for level, count in sorted(stats['by_level'].items(), key=lambda x: x[1], reverse=True):
        percentage = (count / stats['total_lines'] * 100) if stats['total_lines'] > 0 else 0
        report_lines.append(f"  {level:<10} {count:>4} ({percentage:>5.1f}%)")
    
    report_lines.extend([
        f"\nErrors Found: {len(stats['errors'])}",
    ])
    
    for error in stats['errors']:
        report_lines.append(f"  - {error}")
    
    report_lines.extend([
        f"\nWarnings Found: {len(stats['warnings'])}",
    ])
    
    for warning in stats['warnings']:
        report_lines.append(f"  - {warning}")
    
    report_lines.append("\n" + "="*60)
    
    report_content = "\n".join(report_lines)
    output_file.write_text(report_content)
    return report_content

# Create and analyze log
log_file = create_sample_log()
print(f"Created: {log_file}")

stats = analyze_log_file(log_file)
print(f"\nAnalyzed {stats['total_lines']} log entries")

# Generate report
report_file = Path("log_analysis_report.txt")
report = generate_report(stats, report_file)
print(f"\n{report}")

print(f"\nReport saved to: {report_file}")

# Clean up
log_file.unlink()
report_file.unlink()

print()

# ============================================================================
# Verification Code
# ============================================================================

def verify_lab_08():
    """Verify that all lab exercises are completed correctly."""
    print("\n" + "="*60)
    print("Lab 08 Verification")
    print("="*60)
    
    passed = 0
    total = 6
    
    # Test basic file operations
    try:
        test_file = Path("verify_test.txt")
        content = "Test content"
        test_file.write_text(content)
        
        assert test_file.exists(), "File not created"
        assert test_file.read_text() == content, "Content wrong"
        
        test_file.unlink()
        assert not test_file.exists(), "File not deleted"
        
        print("✅ Basic file operations - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Basic file operations - FAILED: {e}")
    
    # Test CSV operations
    try:
        csv_test = Path("test.csv")
        data = [
            {"name": "Test", "value": "100"}
        ]
        
        with open(csv_test, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=["name", "value"])
            writer.writeheader()
            writer.writerows(data)
        
        with open(csv_test, 'r') as f:
            reader = csv.DictReader(f)
            rows = list(reader)
        
        assert len(rows) == 1, "CSV row count wrong"
        assert rows[0]['name'] == "Test", "CSV data wrong"
        
        csv_test.unlink()
        
        print("✅ CSV operations - PASSED")
        passed += 1
    except (AssertionError, Exception) as e:
        print(f"❌ CSV operations - FAILED: {e}")
    
    # Test JSON operations
    try:
        json_test = Path("test.json")
        data = {"key": "value", "number": 42}
        
        with open(json_test, 'w') as f:
            json.dump(data, f)
        
        with open(json_test, 'r') as f:
            loaded = json.load(f)
        
        assert loaded == data, "JSON data wrong"
        
        json_test.unlink()
        
        print("✅ JSON operations - PASSED")
        passed += 1
    except (AssertionError, Exception) as e:
        print(f"❌ JSON operations - FAILED: {e}")
    
    # Test pathlib
    try:
        test_dir = Path("test_dir")
        test_dir.mkdir(exist_ok=True)
        
        assert test_dir.exists(), "Directory not created"
        assert test_dir.is_dir(), "Not a directory"
        
        test_file = test_dir / "file.txt"
        test_file.write_text("content")
        
        assert test_file.exists(), "File in dir not created"
        assert test_file.parent == test_dir, "Parent wrong"
        
        import shutil
        shutil.rmtree(test_dir)
        
        print("✅ Pathlib operations - PASSED")
        passed += 1
    except (AssertionError, Exception) as e:
        print(f"❌ Pathlib operations - FAILED: {e}")
    
    # Test error handling
    try:
        result = safe_read_file(Path("nonexistent_file.txt"))
        assert "Error" in result or "not found" in result.lower(), "Error handling wrong"
        
        print("✅ Error handling - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Error handling - FAILED: {e}")
    
    # Test log analyzer
    try:
        # Create test log
        test_log = Path("test.log")
        test_log.write_text("INFO Test\nERROR Failed\nWARNING Warning")
        
        stats = analyze_log_file(test_log)
        
        assert stats['total_lines'] == 3, f"Line count wrong: {stats['total_lines']}"
        assert stats['by_level']['INFO'] >= 1, "INFO count wrong"
        assert stats['by_level']['ERROR'] >= 1, "ERROR count wrong"
        assert len(stats['errors']) >= 1, "Errors not captured"
        
        test_log.unlink()
        
        print("✅ Log analyzer - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Log analyzer - FAILED: {e}")
    
    print("="*60)
    print(f"Score: {passed}/{total} ({passed/total*100:.0f}%)")
    print("="*60)
    
    if passed == total:
        print("🎉 Congratulations! All tests passed!")
        print("\n📚 Key Learnings:")
        print("  1. Basic file read/write operations")
        print("  2. CSV processing with DictReader/Writer")
        print("  3. JSON serialization and deserialization")
        print("  4. pathlib for modern file operations")
        print("  5. Error handling with try/except")
        print("  6. Log file analysis and reporting")
        print("\n🚀 Next Steps:")
        print("  - Try Lab 09: Error Handling")
        print("  - Review Section 13: File Operations")
        print("  - Practice with larger datasets")
    else:
        print("📝 Keep practicing! Review the sections and try again.")

# Run verification
verify_lab_08()
