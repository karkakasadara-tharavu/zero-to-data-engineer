# Special Methods (Magic Methods / Dunder Methods)

**கற்க கசடற - Learn Flawlessly**

## Introduction

Special methods, also known as **magic methods** or **dunder methods** (double underscore methods), are special functions in Python that start and end with double underscores (e.g., `__init__`, `__str__`, `__add__`). They allow you to define how objects of your class behave with Python's built-in operations and functions.

These methods enable operator overloading, context managers, iteration, and much more, making your custom objects behave like built-in types.

## Why Special Methods?

Special methods allow your objects to:
- ✅ Work with built-in functions like `len()`, `str()`, `repr()`
- ✅ Support arithmetic operators (`+`, `-`, `*`, `/`)
- ✅ Support comparison operators (`==`, `<`, `>`, `<=`, `>=`)
- ✅ Be iterable (used in `for` loops)
- ✅ Be used as context managers (`with` statement)
- ✅ Support indexing and slicing (`obj[key]`)
- ✅ Be callable like functions

## Object Initialization and Representation

### `__init__`: Constructor
Already familiar - initializes new objects.

```python
class Person:
    def __init__(self, name, age):
        self.name = name
        self.age = age
```

### `__str__`: String Representation (User-Friendly)
Called by `str()` and `print()` - should return a human-readable string.

```python
class Person:
    def __init__(self, name, age):
        self.name = name
        self.age = age
    
    def __str__(self):
        return f"{self.name}, {self.age} years old"

person = Person("Alice", 30)
print(person)          # Calls __str__: Alice, 30 years old
print(str(person))     # Alice, 30 years old
```

### `__repr__`: Official Representation (Developer-Friendly)
Called by `repr()` - should return an unambiguous representation, ideally valid Python code.

```python
class Person:
    def __init__(self, name, age):
        self.name = name
        self.age = age
    
    def __str__(self):
        return f"{self.name}, {self.age} years old"
    
    def __repr__(self):
        return f"Person('{self.name}', {self.age})"

person = Person("Alice", 30)
print(str(person))     # Alice, 30 years old
print(repr(person))    # Person('Alice', 30)

# repr() is used in interactive shell and debuggers
# >>> person
# Person('Alice', 30)
```

### Best Practice: Always Define Both `__str__` and `__repr__`

```python
class Book:
    def __init__(self, title, author, year):
        self.title = title
        self.author = author
        self.year = year
    
    def __str__(self):
        # User-friendly
        return f'"{self.title}" by {self.author} ({self.year})'
    
    def __repr__(self):
        # Developer-friendly, recreatable
        return f"Book('{self.title}', '{self.author}', {self.year})"

book = Book("1984", "George Orwell", 1949)
print(str(book))    # "1984" by George Orwell (1949)
print(repr(book))   # Book('1984', 'George Orwell', 1949)

# In lists, repr() is used
books = [book]
print(books)        # [Book('1984', 'George Orwell', 1949)]
```

## Comparison Operators

### Rich Comparison Methods

| Method | Operator | Description |
|--------|----------|-------------|
| `__eq__` | `==` | Equal to |
| `__ne__` | `!=` | Not equal to |
| `__lt__` | `<` | Less than |
| `__le__` | `<=` | Less than or equal to |
| `__gt__` | `>` | Greater than |
| `__ge__` | `>=` | Greater than or equal to |

```python
class Student:
    def __init__(self, name, grade):
        self.name = name
        self.grade = grade
    
    def __eq__(self, other):
        """Equal if same grade"""
        if isinstance(other, Student):
            return self.grade == other.grade
        return False
    
    def __lt__(self, other):
        """Less than if lower grade"""
        if isinstance(other, Student):
            return self.grade < other.grade
        return NotImplemented
    
    def __le__(self, other):
        """Less than or equal"""
        return self == other or self < other
    
    def __gt__(self, other):
        """Greater than if higher grade"""
        if isinstance(other, Student):
            return self.grade > other.grade
        return NotImplemented
    
    def __ge__(self, other):
        """Greater than or equal"""
        return self == other or self > other
    
    def __repr__(self):
        return f"Student('{self.name}', {self.grade})"

# Usage
alice = Student("Alice", 95)
bob = Student("Bob", 87)
carol = Student("Carol", 95)

print(alice == carol)   # True (same grade)
print(alice > bob)      # True (95 > 87)
print(bob < alice)      # True (87 < 95)
print(alice >= carol)   # True (equal)

# Works with sorting!
students = [bob, alice, carol]
students.sort()
print(students)  # [Student('Bob', 87), Student('Alice', 95), Student('Carol', 95)]
```

### Using `functools.total_ordering`

Simplify comparison implementation by defining only `__eq__` and one other comparison:

```python
from functools import total_ordering

@total_ordering
class Student:
    def __init__(self, name, grade):
        self.name = name
        self.grade = grade
    
    def __eq__(self, other):
        if isinstance(other, Student):
            return self.grade == other.grade
        return NotImplemented
    
    def __lt__(self, other):
        if isinstance(other, Student):
            return self.grade < other.grade
        return NotImplemented
    
    def __repr__(self):
        return f"Student('{self.name}', {self.grade})"

# @total_ordering automatically generates __le__, __gt__, __ge__
alice = Student("Alice", 95)
bob = Student("Bob", 87)

print(alice <= bob)  # False (auto-generated)
print(alice >= bob)  # True (auto-generated)
```

## Arithmetic Operators

### Basic Arithmetic Methods

| Method | Operator | Description |
|--------|----------|-------------|
| `__add__` | `+` | Addition |
| `__sub__` | `-` | Subtraction |
| `__mul__` | `*` | Multiplication |
| `__truediv__` | `/` | Division |
| `__floordiv__` | `//` | Floor division |
| `__mod__` | `%` | Modulo |
| `__pow__` | `**` | Exponentiation |

```python
class Vector:
    def __init__(self, x, y):
        self.x = x
        self.y = y
    
    def __add__(self, other):
        """Vector addition"""
        if isinstance(other, Vector):
            return Vector(self.x + other.x, self.y + other.y)
        return NotImplemented
    
    def __sub__(self, other):
        """Vector subtraction"""
        if isinstance(other, Vector):
            return Vector(self.x - other.x, self.y - other.y)
        return NotImplemented
    
    def __mul__(self, scalar):
        """Scalar multiplication"""
        if isinstance(scalar, (int, float)):
            return Vector(self.x * scalar, self.y * scalar)
        return NotImplemented
    
    def __truediv__(self, scalar):
        """Scalar division"""
        if isinstance(scalar, (int, float)):
            if scalar == 0:
                raise ValueError("Cannot divide by zero")
            return Vector(self.x / scalar, self.y / scalar)
        return NotImplemented
    
    def __eq__(self, other):
        """Equality comparison"""
        if isinstance(other, Vector):
            return self.x == other.x and self.y == other.y
        return False
    
    def __repr__(self):
        return f"Vector({self.x}, {self.y})"
    
    def __str__(self):
        return f"({self.x}, {self.y})"

# Usage
v1 = Vector(3, 4)
v2 = Vector(1, 2)

print(v1 + v2)      # Vector(4, 6)
print(v1 - v2)      # Vector(2, 2)
print(v1 * 3)       # Vector(9, 12)
print(v1 / 2)       # Vector(1.5, 2.0)
print(v1 == Vector(3, 4))  # True
```

### In-Place Operators

| Method | Operator | Description |
|--------|----------|-------------|
| `__iadd__` | `+=` | In-place addition |
| `__isub__` | `-=` | In-place subtraction |
| `__imul__` | `*=` | In-place multiplication |
| `__itruediv__` | `/=` | In-place division |

```python
class Counter:
    def __init__(self, value=0):
        self.value = value
    
    def __add__(self, other):
        """Regular addition - returns new object"""
        if isinstance(other, (int, Counter)):
            other_value = other if isinstance(other, int) else other.value
            return Counter(self.value + other_value)
        return NotImplemented
    
    def __iadd__(self, other):
        """In-place addition - modifies self"""
        if isinstance(other, (int, Counter)):
            other_value = other if isinstance(other, int) else other.value
            self.value += other_value
            return self  # Must return self!
        return NotImplemented
    
    def __repr__(self):
        return f"Counter({self.value})"

# Usage
c1 = Counter(10)
c2 = c1 + 5         # Creates new Counter(15), c1 unchanged
print(c1, c2)       # Counter(10) Counter(15)

c1 += 5             # Modifies c1 in-place
print(c1)           # Counter(15)
```

## Container and Sequence Methods

### `__len__`: Length
```python
class Playlist:
    def __init__(self, name):
        self.name = name
        self.songs = []
    
    def add_song(self, song):
        self.songs.append(song)
    
    def __len__(self):
        """Enable len() function"""
        return len(self.songs)
    
    def __repr__(self):
        return f"Playlist('{self.name}', {len(self)} songs)"

playlist = Playlist("My Favorites")
playlist.add_song("Song 1")
playlist.add_song("Song 2")

print(len(playlist))  # 2 (calls __len__)
print(playlist)       # Playlist('My Favorites', 2 songs)
```

### `__getitem__` and `__setitem__`: Indexing

```python
class Playlist:
    def __init__(self, name):
        self.name = name
        self.songs = []
    
    def add_song(self, song):
        self.songs.append(song)
    
    def __len__(self):
        return len(self.songs)
    
    def __getitem__(self, index):
        """Enable indexing: playlist[0]"""
        return self.songs[index]
    
    def __setitem__(self, index, value):
        """Enable item assignment: playlist[0] = 'New Song'"""
        self.songs[index] = value
    
    def __delitem__(self, index):
        """Enable item deletion: del playlist[0]"""
        del self.songs[index]
    
    def __contains__(self, item):
        """Enable 'in' operator: 'Song 1' in playlist"""
        return item in self.songs
    
    def __iter__(self):
        """Enable iteration: for song in playlist"""
        return iter(self.songs)

# Usage
playlist = Playlist("Rock Classics")
playlist.add_song("Bohemian Rhapsody")
playlist.add_song("Stairway to Heaven")
playlist.add_song("Hotel California")

# Indexing
print(playlist[0])           # Bohemian Rhapsody
print(playlist[-1])          # Hotel California

# Slicing (works automatically with __getitem__)
print(playlist[0:2])         # ['Bohemian Rhapsody', 'Stairway to Heaven']

# Assignment
playlist[0] = "We Will Rock You"
print(playlist[0])           # We Will Rock You

# Membership testing
print("Hotel California" in playlist)  # True

# Iteration
for song in playlist:
    print(f"♪ {song}")

# Deletion
del playlist[0]
print(len(playlist))         # 2
```

## Callable Objects

### `__call__`: Making Objects Callable

```python
class Multiplier:
    """Callable class that multiplies by a factor"""
    
    def __init__(self, factor):
        self.factor = factor
    
    def __call__(self, value):
        """Called when object is used like a function"""
        return value * self.factor
    
    def __repr__(self):
        return f"Multiplier({self.factor})"

# Usage
double = Multiplier(2)
triple = Multiplier(3)

# Call objects like functions
print(double(5))      # 10
print(triple(5))      # 15
print(double(10))     # 20

# Useful for closures and functors
times_five = Multiplier(5)
numbers = [1, 2, 3, 4, 5]
result = list(map(times_five, numbers))
print(result)         # [5, 10, 15, 20, 25]
```

### Practical Example: Logger

```python
from datetime import datetime

class Logger:
    """Callable logger with timestamp"""
    
    def __init__(self, prefix="LOG"):
        self.prefix = prefix
        self.logs = []
    
    def __call__(self, message):
        """Log a message when called"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{self.prefix}] {timestamp}: {message}"
        self.logs.append(log_entry)
        print(log_entry)
        return log_entry
    
    def get_logs(self):
        return self.logs

# Usage
error_log = Logger("ERROR")
info_log = Logger("INFO")

error_log("Database connection failed")
error_log("Retry attempt 1")
info_log("Application started successfully")

print("\nAll errors:")
for log in error_log.get_logs():
    print(log)
```

## Context Managers

### `__enter__` and `__exit__`: Support `with` Statement

```python
class FileHandler:
    """Custom context manager for file operations"""
    
    def __init__(self, filename, mode='r'):
        self.filename = filename
        self.mode = mode
        self.file = None
    
    def __enter__(self):
        """Called when entering 'with' block"""
        print(f"Opening {self.filename}")
        self.file = open(self.filename, self.mode)
        return self.file
    
    def __exit__(self, exc_type, exc_value, traceback):
        """Called when exiting 'with' block"""
        print(f"Closing {self.filename}")
        if self.file:
            self.file.close()
        
        # Return False to propagate exceptions, True to suppress
        if exc_type is not None:
            print(f"Exception occurred: {exc_type.__name__}: {exc_value}")
        return False  # Don't suppress exceptions

# Usage
with FileHandler('test.txt', 'w') as f:
    f.write("Hello, World!")
# __exit__ is called automatically, even if exception occurs
```

### Practical Example: Database Connection

```python
class DatabaseConnection:
    """Context manager for database connections"""
    
    def __init__(self, connection_string):
        self.connection_string = connection_string
        self.connection = None
    
    def __enter__(self):
        """Establish connection"""
        print(f"Connecting to database: {self.connection_string}")
        # Simulate connection
        self.connection = f"Connection<{self.connection_string}>"
        return self
    
    def __exit__(self, exc_type, exc_value, traceback):
        """Close connection"""
        print("Closing database connection")
        self.connection = None
        return False
    
    def execute(self, query):
        """Execute query"""
        if not self.connection:
            raise RuntimeError("No active connection")
        return f"Executed: {query}"

# Usage
with DatabaseConnection("server=localhost;db=mydb") as db:
    result = db.execute("SELECT * FROM users")
    print(result)
# Connection closed automatically
```

## Comprehensive Example: Matrix Class

```python
class Matrix:
    """2D Matrix with full operator support"""
    
    def __init__(self, rows):
        """Initialize with list of lists"""
        self.rows = rows
        self.num_rows = len(rows)
        self.num_cols = len(rows[0]) if rows else 0
    
    def __str__(self):
        """User-friendly string representation"""
        return '\n'.join([' '.join(map(str, row)) for row in self.rows])
    
    def __repr__(self):
        """Developer-friendly representation"""
        return f"Matrix({self.rows})"
    
    def __getitem__(self, index):
        """Enable indexing: matrix[0][1]"""
        return self.rows[index]
    
    def __setitem__(self, index, value):
        """Enable assignment: matrix[0] = [1, 2, 3]"""
        if len(value) != self.num_cols:
            raise ValueError("Row must have same number of columns")
        self.rows[index] = value
    
    def __len__(self):
        """Return number of rows"""
        return self.num_rows
    
    def __eq__(self, other):
        """Matrix equality"""
        if not isinstance(other, Matrix):
            return False
        return self.rows == other.rows
    
    def __add__(self, other):
        """Matrix addition"""
        if not isinstance(other, Matrix):
            return NotImplemented
        if self.num_rows != other.num_rows or self.num_cols != other.num_cols:
            raise ValueError("Matrices must have same dimensions")
        
        result = []
        for i in range(self.num_rows):
            row = []
            for j in range(self.num_cols):
                row.append(self.rows[i][j] + other.rows[i][j])
            result.append(row)
        return Matrix(result)
    
    def __mul__(self, scalar):
        """Scalar multiplication"""
        if not isinstance(scalar, (int, float)):
            return NotImplemented
        
        result = []
        for row in self.rows:
            result.append([element * scalar for element in row])
        return Matrix(result)
    
    def __iter__(self):
        """Iterate over rows"""
        return iter(self.rows)
    
    def __contains__(self, value):
        """Check if value exists in matrix"""
        for row in self.rows:
            if value in row:
                return True
        return False

# Usage
m1 = Matrix([[1, 2], [3, 4]])
m2 = Matrix([[5, 6], [7, 8]])

print("Matrix 1:")
print(m1)
print("\nMatrix 2:")
print(m2)

# Addition
m3 = m1 + m2
print("\nMatrix 1 + Matrix 2:")
print(m3)

# Scalar multiplication
m4 = m1 * 2
print("\nMatrix 1 * 2:")
print(m4)

# Indexing
print(f"\nElement [0][1]: {m1[0][1]}")  # 2

# Membership
print(f"\n4 in Matrix 1: {4 in m1}")    # True

# Iteration
print("\nIterating over Matrix 1:")
for row in m1:
    print(row)
```

## Summary of Important Special Methods

### Object Lifecycle
- `__init__(self, ...)`: Constructor
- `__del__(self)`: Destructor (rarely needed)

### String Representation
- `__str__(self)`: User-friendly string (`str()`, `print()`)
- `__repr__(self)`: Developer-friendly string (`repr()`)
- `__format__(self, format_spec)`: Custom formatting

### Comparison
- `__eq__(self, other)`: `==`
- `__ne__(self, other)`: `!=`
- `__lt__(self, other)`: `<`
- `__le__(self, other)`: `<=`
- `__gt__(self, other)`: `>`
- `__ge__(self, other)`: `>=`

### Arithmetic
- `__add__(self, other)`: `+`
- `__sub__(self, other)`: `-`
- `__mul__(self, other)`: `*`
- `__truediv__(self, other)`: `/`
- `__floordiv__(self, other)`: `//`
- `__mod__(self, other)`: `%`
- `__pow__(self, other)`: `**`

### Container/Sequence
- `__len__(self)`: `len()`
- `__getitem__(self, key)`: `obj[key]`
- `__setitem__(self, key, value)`: `obj[key] = value`
- `__delitem__(self, key)`: `del obj[key]`
- `__contains__(self, item)`: `item in obj`
- `__iter__(self)`: `for item in obj`

### Callable
- `__call__(self, ...)`: `obj(...)`

### Context Manager
- `__enter__(self)`: Setup for `with` statement
- `__exit__(self, exc_type, exc_value, traceback)`: Cleanup

## Best Practices

1. **Always return `NotImplemented` for unsupported operations**
2. **Define both `__str__` and `__repr__`**
3. **Use `@functools.total_ordering` for comparison methods**
4. **Check types in operator overloading methods**
5. **Return `self` from in-place operators (`__iadd__`, etc.)**
6. **Make context managers exception-safe**

---

**கற்க கசடற** - Master special methods and make your objects behave like built-in types!
