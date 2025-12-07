# File Operations in Python

## 🎯 Learning Objectives
- Open, read, and write files
- Understand file modes and context managers
- Work with CSV, JSON, and text files
- Handle file paths with pathlib
- Manage file operations safely
- Process large files efficiently

---

## 📁 Opening and Closing Files

### Basic File Operations
```python
# Open file
file = open('data.txt', 'r')  # 'r' = read mode

# Read content
content = file.read()
print(content)

# Close file (IMPORTANT!)
file.close()
```

### File Modes

| Mode | Description | Creates if Missing |
|------|-------------|-------------------|
| `'r'` | Read (default) | ❌ Error |
| `'w'` | Write (overwrites) | ✅ Yes |
| `'a'` | Append | ✅ Yes |
| `'x'` | Exclusive create | ✅ Error if exists |
| `'r+'` | Read and write | ❌ Error |
| `'w+'` | Write and read | ✅ Yes |
| `'a+'` | Append and read | ✅ Yes |
| `'b'` | Binary mode | Add to above |

```python
# Read mode
file = open('data.txt', 'r')

# Write mode (creates or overwrites)
file = open('output.txt', 'w')

# Append mode (adds to end)
file = open('log.txt', 'a')

# Binary mode (for images, etc.)
file = open('image.png', 'rb')
```

---

## 🔒 Context Managers (with statement)

**Always use `with` statement** - automatically closes file!

### Basic Usage
```python
# ✅ Best practice - automatic cleanup
with open('data.txt', 'r') as file:
    content = file.read()
    print(content)
# File automatically closed here!

# ❌ Manual close (can forget or skip if error occurs)
file = open('data.txt', 'r')
content = file.read()
file.close()  # Might not run if error occurs above
```

### Multiple Files
```python
# Open multiple files
with open('input.txt', 'r') as infile, open('output.txt', 'w') as outfile:
    content = infile.read()
    outfile.write(content.upper())
```

---

## 📖 Reading Files

### read() - Read Entire File
```python
with open('data.txt', 'r') as file:
    content = file.read()  # Returns entire file as string
    print(content)

# Read specific number of characters
with open('data.txt', 'r') as file:
    chunk = file.read(100)  # Read first 100 characters
    print(chunk)
```

### readline() - Read One Line
```python
with open('data.txt', 'r') as file:
    line1 = file.readline()  # First line
    line2 = file.readline()  # Second line
    print(line1)
    print(line2)
```

### readlines() - Read All Lines as List
```python
with open('data.txt', 'r') as file:
    lines = file.readlines()  # Returns list of lines
    for line in lines:
        print(line.strip())  # strip() removes \n
```

### Iterate Over File (Best for Large Files)
```python
# Memory efficient - reads one line at a time
with open('large_file.txt', 'r') as file:
    for line in file:
        print(line.strip())
```

---

## ✍️ Writing Files

### write() - Write String
```python
with open('output.txt', 'w') as file:
    file.write("Hello World\n")
    file.write("Second line\n")

# Note: write() doesn't add newline automatically!
```

### writelines() - Write List of Strings
```python
lines = ["Line 1\n", "Line 2\n", "Line 3\n"]

with open('output.txt', 'w') as file:
    file.writelines(lines)
```

### Append Mode
```python
# Append to existing file
with open('log.txt', 'a') as file:
    file.write("New log entry\n")
```

---

## 📊 Working with CSV Files

### Reading CSV
```python
import csv

# Read CSV file
with open('data.csv', 'r') as file:
    csv_reader = csv.reader(file)
    
    # Skip header
    header = next(csv_reader)
    print(f"Columns: {header}")
    
    # Read rows
    for row in csv_reader:
        print(row)  # Each row is a list
```

### Reading CSV as Dictionary
```python
import csv

with open('data.csv', 'r') as file:
    csv_reader = csv.DictReader(file)
    
    for row in csv_reader:
        print(row)  # Each row is a dictionary
        print(f"Name: {row['name']}, Age: {row['age']}")
```

### Writing CSV
```python
import csv

data = [
    ['Name', 'Age', 'City'],
    ['Alice', 25, 'NYC'],
    ['Bob', 30, 'LA'],
    ['Carol', 28, 'Chicago']
]

with open('output.csv', 'w', newline='') as file:
    csv_writer = csv.writer(file)
    csv_writer.writerows(data)
```

### Writing CSV from Dictionaries
```python
import csv

data = [
    {'name': 'Alice', 'age': 25, 'city': 'NYC'},
    {'name': 'Bob', 'age': 30, 'city': 'LA'},
    {'name': 'Carol', 'age': 28, 'city': 'Chicago'}
]

with open('output.csv', 'w', newline='') as file:
    fieldnames = ['name', 'age', 'city']
    csv_writer = csv.DictWriter(file, fieldnames=fieldnames)
    
    csv_writer.writeheader()
    csv_writer.writerows(data)
```

---

## 🗂️ Working with JSON Files

### Reading JSON
```python
import json

# Read JSON file
with open('data.json', 'r') as file:
    data = json.load(file)
    print(data)  # Python dictionary/list

# Parse JSON string
json_string = '{"name": "Alice", "age": 25}'
data = json.loads(json_string)
print(data)  # {'name': 'Alice', 'age': 25}
```

### Writing JSON
```python
import json

data = {
    'name': 'Alice',
    'age': 25,
    'city': 'NYC',
    'skills': ['Python', 'SQL', 'Java']
}

# Write to file
with open('output.json', 'w') as file:
    json.dump(data, file, indent=2)  # indent for pretty printing

# Convert to JSON string
json_string = json.dumps(data, indent=2)
print(json_string)
```

### Pretty Print JSON
```python
import json

data = {'name': 'Alice', 'age': 25, 'skills': ['Python', 'SQL']}

# Pretty print with indentation
print(json.dumps(data, indent=2))

# Output:
# {
#   "name": "Alice",
#   "age": 25,
#   "skills": [
#     "Python",
#     "SQL"
#   ]
# }
```

---

## 🛤️ File Paths with pathlib

Modern way to handle file paths.

### Basic Usage
```python
from pathlib import Path

# Create path object
file_path = Path('data/input.txt')

# Check if exists
if file_path.exists():
    print("File exists!")

# Check if file or directory
print(file_path.is_file())  # True
print(file_path.is_dir())   # False

# Get file info
print(file_path.name)       # 'input.txt'
print(file_path.stem)       # 'input' (without extension)
print(file_path.suffix)     # '.txt'
print(file_path.parent)     # 'data'
```

### Path Operations
```python
from pathlib import Path

# Join paths (works on any OS)
base_dir = Path('data')
file_path = base_dir / 'subfolder' / 'file.txt'
print(file_path)  # data/subfolder/file.txt

# Get absolute path
absolute = file_path.resolve()
print(absolute)

# Get current directory
current = Path.cwd()
print(current)

# Get home directory
home = Path.home()
print(home)
```

### Reading/Writing with pathlib
```python
from pathlib import Path

file_path = Path('data.txt')

# Read text
content = file_path.read_text()

# Write text
file_path.write_text("Hello World")

# Read bytes
binary_data = file_path.read_bytes()

# Write bytes
file_path.write_bytes(b'Binary data')
```

### Listing Directory Contents
```python
from pathlib import Path

# List all files in directory
data_dir = Path('data')

# All items
for item in data_dir.iterdir():
    print(item)

# Only files
files = [f for f in data_dir.iterdir() if f.is_file()]
print(files)

# Only directories
dirs = [d for d in data_dir.iterdir() if d.is_dir()]
print(dirs)

# Glob patterns
txt_files = list(data_dir.glob('*.txt'))
all_py_files = list(data_dir.rglob('*.py'))  # Recursive
```

---

## 📚 Practical File Examples

### Example 1: Copy File
```python
from pathlib import Path

def copy_file(source, destination):
    """Copy file from source to destination"""
    source_path = Path(source)
    dest_path = Path(destination)
    
    if not source_path.exists():
        print(f"Error: {source} does not exist")
        return
    
    # Read and write
    content = source_path.read_text()
    dest_path.write_text(content)
    print(f"Copied {source} to {destination}")

# Usage
copy_file('input.txt', 'output.txt')
```

### Example 2: Count Lines, Words, Characters
```python
from pathlib import Path

def file_stats(filename):
    """Count lines, words, and characters in file"""
    file_path = Path(filename)
    
    if not file_path.exists():
        return None
    
    content = file_path.read_text()
    lines = content.splitlines()
    words = content.split()
    chars = len(content)
    
    return {
        'lines': len(lines),
        'words': len(words),
        'characters': chars
    }

# Usage
stats = file_stats('data.txt')
if stats:
    print(f"Lines: {stats['lines']}")
    print(f"Words: {stats['words']}")
    print(f"Characters: {stats['characters']}")
```

### Example 3: Search in File
```python
from pathlib import Path

def search_in_file(filename, search_term):
    """Find lines containing search term"""
    file_path = Path(filename)
    matches = []
    
    with file_path.open('r') as file:
        for line_num, line in enumerate(file, 1):
            if search_term.lower() in line.lower():
                matches.append((line_num, line.strip()))
    
    return matches

# Usage
results = search_in_file('log.txt', 'error')
for line_num, line in results:
    print(f"Line {line_num}: {line}")
```

### Example 4: Merge CSV Files
```python
import csv
from pathlib import Path

def merge_csv_files(input_files, output_file):
    """Merge multiple CSV files into one"""
    all_rows = []
    header = None
    
    for input_file in input_files:
        with open(input_file, 'r') as file:
            reader = csv.reader(file)
            file_header = next(reader)
            
            if header is None:
                header = file_header
            
            for row in reader:
                all_rows.append(row)
    
    # Write merged file
    with open(output_file, 'w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(header)
        writer.writerows(all_rows)
    
    print(f"Merged {len(input_files)} files into {output_file}")

# Usage
merge_csv_files(['data1.csv', 'data2.csv'], 'merged.csv')
```

### Example 5: Filter and Transform CSV
```python
import csv

def filter_csv(input_file, output_file, condition_func):
    """Filter CSV rows based on condition function"""
    with open(input_file, 'r') as infile, \
         open(output_file, 'w', newline='') as outfile:
        
        reader = csv.DictReader(infile)
        writer = csv.DictWriter(outfile, fieldnames=reader.fieldnames)
        
        writer.writeheader()
        
        for row in reader:
            if condition_func(row):
                writer.writerow(row)

# Usage: Filter employees with salary > 50000
def high_salary(row):
    return int(row['salary']) > 50000

filter_csv('employees.csv', 'high_earners.csv', high_salary)
```

### Example 6: Process Large File Line by Line
```python
from pathlib import Path

def process_large_file(input_file, output_file, transform_func):
    """Process large file line by line (memory efficient)"""
    with open(input_file, 'r') as infile, \
         open(output_file, 'w') as outfile:
        
        for line in infile:
            transformed = transform_func(line)
            outfile.write(transformed)

# Usage: Convert to uppercase
def to_upper(line):
    return line.upper()

process_large_file('large_input.txt', 'large_output.txt', to_upper)
```

### Example 7: Create Directory Structure
```python
from pathlib import Path

def create_project_structure(project_name):
    """Create project directory structure"""
    base = Path(project_name)
    
    # Create directories
    (base / 'src').mkdir(parents=True, exist_ok=True)
    (base / 'tests').mkdir(exist_ok=True)
    (base / 'data' / 'raw').mkdir(parents=True, exist_ok=True)
    (base / 'data' / 'processed').mkdir(exist_ok=True)
    (base / 'docs').mkdir(exist_ok=True)
    
    # Create files
    (base / 'README.md').write_text(f"# {project_name}\n\nProject description here.")
    (base / 'requirements.txt').write_text("# Python dependencies\n")
    (base / '.gitignore').write_text("__pycache__/\n*.pyc\n.env\n")
    
    print(f"Created project structure: {project_name}/")

# Usage
create_project_structure('my_data_project')
```

---

## 🔐 Safe File Operations

### Check Before Opening
```python
from pathlib import Path

def safe_read_file(filename):
    """Safely read file with error handling"""
    file_path = Path(filename)
    
    if not file_path.exists():
        print(f"Error: {filename} does not exist")
        return None
    
    if not file_path.is_file():
        print(f"Error: {filename} is not a file")
        return None
    
    try:
        return file_path.read_text()
    except PermissionError:
        print(f"Error: No permission to read {filename}")
        return None
    except Exception as e:
        print(f"Error reading {filename}: {e}")
        return None
```

### Backup Before Modifying
```python
from pathlib import Path
import shutil

def safe_modify_file(filename, new_content):
    """Modify file with automatic backup"""
    file_path = Path(filename)
    backup_path = file_path.with_suffix(file_path.suffix + '.bak')
    
    try:
        # Create backup
        if file_path.exists():
            shutil.copy2(file_path, backup_path)
        
        # Write new content
        file_path.write_text(new_content)
        print(f"File modified. Backup: {backup_path}")
        
    except Exception as e:
        print(f"Error: {e}")
        # Restore backup if modification failed
        if backup_path.exists():
            shutil.copy2(backup_path, file_path)
            print("Restored from backup")
```

---

## ⚠️ Common Pitfalls

### Mistake 1: Forgetting to Close File
```python
# ❌ Wrong - file might not close
file = open('data.txt', 'r')
content = file.read()
# file.close()  # Might forget this!

# ✅ Correct - automatic close
with open('data.txt', 'r') as file:
    content = file.read()
```

### Mistake 2: Wrong File Mode
```python
# ❌ Wrong - 'r' mode can't write
try:
    with open('data.txt', 'r') as file:
        file.write("Hello")  # Error!
except io.UnsupportedOperation:
    print("Can't write in read mode")

# ✅ Correct - use 'w' or 'a' mode
with open('data.txt', 'w') as file:
    file.write("Hello")
```

### Mistake 3: Overwriting File Accidentally
```python
# ❌ Dangerous - 'w' mode overwrites!
with open('important.txt', 'w') as file:
    file.write("New content")  # Old content gone!

# ✅ Safe - check first or use 'a' mode
from pathlib import Path

file_path = Path('important.txt')
if file_path.exists():
    print("File exists! Use 'a' mode or different name")
else:
    file_path.write_text("New content")
```

### Mistake 4: Not Handling Encoding
```python
# ❌ May fail with special characters
with open('data.txt', 'r') as file:
    content = file.read()

# ✅ Specify encoding
with open('data.txt', 'r', encoding='utf-8') as file:
    content = file.read()
```

---

## ✅ Key Takeaways

1. ✅ Always use `with` statement for file operations
2. ✅ 'r' read, 'w' write (overwrites), 'a' append
3. ✅ `read()` entire file, iterate for large files
4. ✅ Use `pathlib.Path` for modern path handling
5. ✅ CSV module for structured data
6. ✅ JSON for hierarchical data
7. ✅ Check file exists before opening
8. ✅ Specify encoding='utf-8' for text files
9. ✅ Create backups before modifying important files
10. ✅ Handle exceptions when working with files

---

**Practice**: Complete Lab 10 - File Operations

**Next Section**: 14_error_handling.md

**கற்க கசடற** - Learn Flawlessly

