# Lab 1: Building a Library Management System

**கற்க கசடற - Learn Flawlessly**

**Estimated Time:** 60-90 minutes  
**Difficulty:** Intermediate  
**Topics:** Classes, Objects, Instance/Class Attributes, Methods

## Objectives

By completing this lab, you will:
- ✅ Create classes with proper constructors
- ✅ Use instance and class attributes appropriately
- ✅ Implement instance methods, class methods, and static methods
- ✅ Work with multiple interacting objects
- ✅ Apply OOP principles to a real-world scenario

## Scenario

You're building a Library Management System that tracks books, members, and borrowing transactions. The system needs to:
- Manage a collection of books
- Track library members
- Handle book borrowing and returns
- Generate statistics and reports

## Requirements

### Part 1: Book Class (15 minutes)

Create a `Book` class with the following specifications:

**Attributes:**
- `isbn` (str): Unique ISBN number
- `title` (str): Book title
- `author` (str): Author name
- `year` (int): Publication year
- `copies_total` (int): Total copies owned by library
- `copies_available` (int): Currently available copies
- Class attribute `total_books` to track all books in the system

**Methods:**
- `__init__(isbn, title, author, year, copies)`: Constructor
- `__str__()`: User-friendly string representation
- `__repr__()`: Developer-friendly representation
- `is_available()`: Returns True if copies are available
- `borrow()`: Decreases available copies by 1 (if available)
- `return_book()`: Increases available copies by 1
- `get_info()`: Returns formatted book information

### Part 2: Member Class (15 minutes)

Create a `Member` class with the following specifications:

**Attributes:**
- `member_id` (str): Unique member ID
- `name` (str): Member name
- `email` (str): Email address
- `borrowed_books` (list): List of borrowed book ISBNs
- `max_books` (int): Maximum books allowed (default 3)
- Class attribute `total_members` to track all members
- Class attribute `member_counter` for auto-generating IDs

**Methods:**
- `__init__(name, email, max_books=3)`: Constructor (auto-generate ID)
- `__str__()`: User-friendly representation
- `can_borrow()`: Returns True if under the borrowing limit
- `borrow_book(isbn)`: Adds ISBN to borrowed books
- `return_book(isbn)`: Removes ISBN from borrowed books
- `get_borrowed_count()`: Returns number of books currently borrowed
- Class method `get_next_id()`: Generates next member ID
- Static method `validate_email(email)`: Validates email format

### Part 3: Library Class (20 minutes)

Create a `Library` class that manages books and members:

**Attributes:**
- `name` (str): Library name
- `books` (dict): Dictionary mapping ISBN to Book objects
- `members` (dict): Dictionary mapping member_id to Member objects
- `transactions` (list): List of transaction records

**Methods:**
- `__init__(name)`: Constructor
- `add_book(book)`: Adds a book to the library
- `add_member(member)`: Adds a member to the library
- `find_book_by_isbn(isbn)`: Finds and returns a book
- `find_book_by_title(title)`: Finds books by title (partial match)
- `find_member(member_id)`: Finds and returns a member
- `borrow_book(member_id, isbn)`: Handles borrowing transaction
- `return_book(member_id, isbn)`: Handles return transaction
- `get_available_books()`: Returns list of all available books
- `get_member_history(member_id)`: Returns borrowing history
- `generate_report()`: Generates library statistics

### Part 4: Testing and Validation (20-30 minutes)

Write code to test your implementation:

1. **Create a library** with at least 5 different books
2. **Add multiple copies** of some books
3. **Register** at least 3 members
4. **Simulate borrowing** transactions:
   - Successful borrows
   - Attempts to borrow when no copies available
   - Attempts to exceed member's borrowing limit
5. **Simulate returns**
6. **Generate reports** showing:
   - Total books and members
   - Available books
   - Member borrowing statistics
   - Transaction history

## Expected Output Format

```
=== Library System Initialized ===
Library: City Public Library
Books added: 5
Members registered: 3

=== Borrowing Transactions ===
✓ Alice (M001) borrowed "To Kill a Mockingbird" (ISBN: 978-0-06-112008-4)
✓ Bob (M002) borrowed "1984" (ISBN: 978-0-452-28423-4)
✗ Carol (M003) cannot borrow "1984" - No copies available
✓ Carol (M003) borrowed "The Great Gatsby" (ISBN: 978-0-7432-7356-5)

=== Return Transactions ===
✓ Alice (M001) returned "To Kill a Mockingbird" (ISBN: 978-0-06-112008-4)

=== Library Report ===
Library Name: City Public Library
Total Books: 5 titles
Total Copies: 12 books
Available Copies: 10 books
Total Members: 3
Active Borrows: 2

Most Popular Books:
1. "1984" by George Orwell - 2 borrows
2. "The Great Gatsby" by F. Scott Fitzgerald - 1 borrow

Member Statistics:
- Alice (M001): 0 books borrowed, 1 total borrows
- Bob (M002): 1 book borrowed, 1 total borrows
- Carol (M003): 1 book borrowed, 1 total borrows
```

## Hints

### Hint 1: Auto-generating Member IDs
```python
class Member:
    member_counter = 1000
    
    @classmethod
    def get_next_id(cls):
        cls.member_counter += 1
        return f"M{cls.member_counter:03d}"
```

### Hint 2: Email Validation
```python
@staticmethod
def validate_email(email):
    return '@' in email and '.' in email
```

### Hint 3: Recording Transactions
```python
def _record_transaction(self, transaction_type, member_id, isbn):
    from datetime import datetime
    self.transactions.append({
        'type': transaction_type,
        'member_id': member_id,
        'isbn': isbn,
        'timestamp': datetime.now()
    })
```

### Hint 4: Finding Books by Title
```python
def find_book_by_title(self, title):
    results = []
    for book in self.books.values():
        if title.lower() in book.title.lower():
            results.append(book)
    return results
```

## Starter Code

```python
from datetime import datetime

class Book:
    total_books = 0
    
    def __init__(self, isbn, title, author, year, copies):
        # TODO: Implement constructor
        pass
    
    def __str__(self):
        # TODO: Return user-friendly string
        pass
    
    def __repr__(self):
        # TODO: Return developer-friendly string
        pass
    
    def is_available(self):
        # TODO: Check if copies are available
        pass
    
    def borrow(self):
        # TODO: Decrease available copies
        pass
    
    def return_book(self):
        # TODO: Increase available copies
        pass
    
    def get_info(self):
        # TODO: Return formatted information
        pass

class Member:
    total_members = 0
    member_counter = 1000
    
    def __init__(self, name, email, max_books=3):
        # TODO: Implement constructor
        pass
    
    def __str__(self):
        # TODO: Return user-friendly string
        pass
    
    def can_borrow(self):
        # TODO: Check if can borrow more books
        pass
    
    def borrow_book(self, isbn):
        # TODO: Add ISBN to borrowed books
        pass
    
    def return_book(self, isbn):
        # TODO: Remove ISBN from borrowed books
        pass
    
    def get_borrowed_count(self):
        # TODO: Return count of borrowed books
        pass
    
    @classmethod
    def get_next_id(cls):
        # TODO: Generate next member ID
        pass
    
    @staticmethod
    def validate_email(email):
        # TODO: Validate email format
        pass

class Library:
    def __init__(self, name):
        # TODO: Implement constructor
        pass
    
    def add_book(self, book):
        # TODO: Add book to library
        pass
    
    def add_member(self, member):
        # TODO: Add member to library
        pass
    
    def find_book_by_isbn(self, isbn):
        # TODO: Find book by ISBN
        pass
    
    def find_book_by_title(self, title):
        # TODO: Find books by title (partial match)
        pass
    
    def find_member(self, member_id):
        # TODO: Find member by ID
        pass
    
    def borrow_book(self, member_id, isbn):
        # TODO: Handle borrowing transaction
        pass
    
    def return_book(self, member_id, isbn):
        # TODO: Handle return transaction
        pass
    
    def get_available_books(self):
        # TODO: Return list of available books
        pass
    
    def get_member_history(self, member_id):
        # TODO: Return member's transaction history
        pass
    
    def generate_report(self):
        # TODO: Generate library statistics
        pass

# TODO: Test your implementation here
def main():
    # Create library
    library = Library("City Public Library")
    
    # Add books
    # TODO: Create and add books
    
    # Register members
    # TODO: Create and add members
    
    # Simulate transactions
    # TODO: Borrow and return books
    
    # Generate report
    # TODO: Call generate_report()

if __name__ == "__main__":
    main()
```

## Validation Checklist

Before submitting, ensure your code:
- [ ] All classes have proper constructors
- [ ] Class attributes are used correctly (total_books, total_members, etc.)
- [ ] Instance attributes are initialized properly
- [ ] All required methods are implemented
- [ ] `__str__()` and `__repr__()` provide meaningful output
- [ ] Borrow validation prevents overborrowing
- [ ] Copy availability is tracked correctly
- [ ] Email validation works
- [ ] Transaction history is recorded
- [ ] Report generation shows accurate statistics
- [ ] Code follows PEP 8 style guidelines
- [ ] Meaningful variable and method names
- [ ] No hardcoded values where unnecessary

## Extension Challenges (Optional)

If you finish early, try these enhancements:

1. **Due Dates**: Add due dates for borrowed books (14 days)
2. **Late Fees**: Calculate late fees for overdue books
3. **Search Filters**: Add ability to search by author or year
4. **Book Reservations**: Allow members to reserve books that are currently borrowed
5. **Member Types**: Implement different member types (Student, Faculty, Public) with different borrowing limits
6. **Export Report**: Export library report to a text file or CSV

## Learning Outcomes

After completing this lab, you should be able to:
- ✅ Design classes with appropriate attributes and methods
- ✅ Use instance methods for object-specific operations
- ✅ Use class methods for class-level operations
- ✅ Use static methods for utility functions
- ✅ Implement `__str__()` and `__repr__()` effectively
- ✅ Manage relationships between multiple classes
- ✅ Validate input and handle edge cases
- ✅ Track and report system statistics

## Need Help?

- Review theory sections: 01_classes_objects.md, 02_instance_class_attributes.md, 03_methods.md
- Check the solution file for reference: solutions/lab_01_solution.py
- Ask questions in the discussion forum

---

**கற்க கசடற** - Build robust object-oriented systems!

**Estimated completion time: 60-90 minutes**  
**Difficulty: ⭐⭐⭐ (Intermediate)**
