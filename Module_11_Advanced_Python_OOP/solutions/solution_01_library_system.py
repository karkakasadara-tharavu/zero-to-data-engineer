# Lab 01 Solution: Library Management System

"""
Complete solution for the Library Management System lab.
Demonstrates: Classes, Objects, Instance/Class attributes, Methods

Author: Data Engineering Curriculum
Module: 11 - Advanced Python & OOP
"""

class Book:
    """Represents a book in the library system"""
    
    # Class attribute to track total books in the system
    total_books = 0
    
    def __init__(self, isbn, title, author, total_copies):
        """
        Initialize a new book.
        
        Args:
            isbn (str): International Standard Book Number
            title (str): Book title
            author (str): Book author
            total_copies (int): Total number of copies available
        """
        self.isbn = isbn
        self.title = title
        self.author = author
        self.total_copies = total_copies
        self.available_copies = total_copies  # Start with all copies available
        
        # Increment class variable for total books
        Book.total_books += 1
    
    def borrow(self):
        """
        Borrow a copy of this book.
        
        Returns:
            bool: True if successful, False if no copies available
        """
        if self.available_copies > 0:
            self.available_copies -= 1
            return True
        return False
    
    def return_book(self):
        """Return a borrowed copy of this book"""
        if self.available_copies < self.total_copies:
            self.available_copies += 1
            return True
        return False
    
    def is_available(self):
        """
        Check if book is available for borrowing.
        
        Returns:
            bool: True if at least one copy is available
        """
        return self.available_copies > 0
    
    def get_availability_status(self):
        """
        Get detailed availability information.
        
        Returns:
            str: Formatted availability status
        """
        return f"{self.available_copies}/{self.total_copies} copies available"
    
    def __str__(self):
        """String representation for display"""
        return f"'{self.title}' by {self.author} (ISBN: {self.isbn}) - {self.get_availability_status()}"
    
    def __repr__(self):
        """Official string representation"""
        return f"Book(isbn='{self.isbn}', title='{self.title}')"


class Member:
    """Represents a library member"""
    
    # Class attributes
    total_members = 0
    _next_id = 1000
    
    def __init__(self, name, email, max_books=3):
        """
        Initialize a new library member.
        
        Args:
            name (str): Member name
            email (str): Member email address
            max_books (int): Maximum books member can borrow
        """
        self.member_id = Member._generate_member_id()
        self.name = name
        self.email = email
        self.max_books = max_books
        self.borrowed_books = []  # List of ISBNs of borrowed books
        
        # Increment total members
        Member.total_members += 1
    
    @classmethod
    def _generate_member_id(cls):
        """
        Generate unique member ID.
        
        Returns:
            str: Formatted member ID (e.g., 'M1000')
        """
        member_id = f"M{cls._next_id}"
        cls._next_id += 1
        return member_id
    
    @staticmethod
    def validate_email(email):
        """
        Validate email format.
        
        Args:
            email (str): Email address to validate
            
        Returns:
            bool: True if valid format
        """
        return '@' in email and '.' in email.split('@')[1]
    
    def can_borrow(self):
        """
        Check if member can borrow more books.
        
        Returns:
            bool: True if under borrow limit
        """
        return len(self.borrowed_books) < self.max_books
    
    def borrow_book(self, book):
        """
        Borrow a book from the library.
        
        Args:
            book (Book): Book to borrow
            
        Returns:
            bool: True if successful, False otherwise
        """
        if not self.can_borrow():
            print(f"✗ {self.name} has reached borrowing limit ({self.max_books} books)")
            return False
        
        if not book.is_available():
            print(f"✗ '{book.title}' is not available")
            return False
        
        if book.borrow():
            self.borrowed_books.append(book.isbn)
            print(f"✓ {self.name} borrowed '{book.title}'")
            return True
        
        return False
    
    def return_book(self, book):
        """
        Return a borrowed book.
        
        Args:
            book (Book): Book to return
            
        Returns:
            bool: True if successful, False otherwise
        """
        if book.isbn in self.borrowed_books:
            book.return_book()
            self.borrowed_books.remove(book.isbn)
            print(f"✓ {self.name} returned '{book.title}'")
            return True
        else:
            print(f"✗ {self.name} didn't borrow '{book.title}'")
            return False
    
    def get_borrowed_count(self):
        """
        Get number of currently borrowed books.
        
        Returns:
            int: Number of borrowed books
        """
        return len(self.borrowed_books)
    
    def __str__(self):
        """String representation for display"""
        return f"{self.name} (ID: {self.member_id}) - {self.get_borrowed_count()}/{self.max_books} books borrowed"
    
    def __repr__(self):
        """Official string representation"""
        return f"Member(id='{self.member_id}', name='{self.name}')"


class Library:
    """Main library system that manages books and members"""
    
    def __init__(self, name):
        """
        Initialize library system.
        
        Args:
            name (str): Library name
        """
        self.name = name
        self.books = {}  # Dictionary: ISBN -> Book object
        self.members = {}  # Dictionary: member_id -> Member object
        self.transactions = []  # List of transaction records
    
    def add_book(self, isbn, title, author, total_copies):
        """
        Add a new book to the library.
        
        Args:
            isbn (str): Book ISBN
            title (str): Book title
            author (str): Book author
            total_copies (int): Number of copies
            
        Returns:
            Book: The created book object
        """
        if isbn in self.books:
            print(f"✗ Book with ISBN {isbn} already exists")
            return None
        
        book = Book(isbn, title, author, total_copies)
        self.books[isbn] = book
        self._log_transaction(f"Added book: {title}")
        print(f"✓ Added '{title}' to library")
        return book
    
    def register_member(self, name, email, max_books=3):
        """
        Register a new library member.
        
        Args:
            name (str): Member name
            email (str): Member email
            max_books (int): Borrowing limit
            
        Returns:
            Member: The created member object
        """
        if not Member.validate_email(email):
            print(f"✗ Invalid email format: {email}")
            return None
        
        member = Member(name, email, max_books)
        self.members[member.member_id] = member
        self._log_transaction(f"Registered member: {name}")
        print(f"✓ Registered {name} (ID: {member.member_id})")
        return member
    
    def find_book(self, isbn):
        """
        Find book by ISBN.
        
        Args:
            isbn (str): Book ISBN
            
        Returns:
            Book or None: Book object if found
        """
        return self.books.get(isbn)
    
    def find_member(self, member_id):
        """
        Find member by ID.
        
        Args:
            member_id (str): Member ID
            
        Returns:
            Member or None: Member object if found
        """
        return self.members.get(member_id)
    
    def checkout_book(self, member_id, isbn):
        """
        Process book checkout transaction.
        
        Args:
            member_id (str): Member ID
            isbn (str): Book ISBN
            
        Returns:
            bool: True if successful
        """
        member = self.find_member(member_id)
        book = self.find_book(isbn)
        
        if not member:
            print(f"✗ Member {member_id} not found")
            return False
        
        if not book:
            print(f"✗ Book {isbn} not found")
            return False
        
        if member.borrow_book(book):
            self._log_transaction(f"{member.name} borrowed {book.title}")
            return True
        
        return False
    
    def return_book(self, member_id, isbn):
        """
        Process book return transaction.
        
        Args:
            member_id (str): Member ID
            isbn (str): Book ISBN
            
        Returns:
            bool: True if successful
        """
        member = self.find_member(member_id)
        book = self.find_book(isbn)
        
        if not member:
            print(f"✗ Member {member_id} not found")
            return False
        
        if not book:
            print(f"✗ Book {isbn} not found")
            return False
        
        if member.return_book(book):
            self._log_transaction(f"{member.name} returned {book.title}")
            return True
        
        return False
    
    def get_available_books(self):
        """
        Get list of all available books.
        
        Returns:
            list: List of available Book objects
        """
        return [book for book in self.books.values() if book.is_available()]
    
    def get_member_info(self, member_id):
        """
        Get detailed member information.
        
        Args:
            member_id (str): Member ID
            
        Returns:
            dict or None: Member info dictionary
        """
        member = self.find_member(member_id)
        if not member:
            return None
        
        borrowed_titles = []
        for isbn in member.borrowed_books:
            book = self.find_book(isbn)
            if book:
                borrowed_titles.append(book.title)
        
        return {
            'id': member.member_id,
            'name': member.name,
            'email': member.email,
            'books_borrowed': len(member.borrowed_books),
            'max_books': member.max_books,
            'borrowed_titles': borrowed_titles
        }
    
    def generate_report(self):
        """Generate comprehensive library report"""
        print(f"\n{'='*60}")
        print(f"{self.name.upper()} - LIBRARY REPORT")
        print(f"{'='*60}")
        
        # Book statistics
        print(f"\n📚 BOOK STATISTICS:")
        print(f"   Total Books: {Book.total_books}")
        print(f"   Total Copies: {sum(book.total_copies for book in self.books.values())}")
        available = sum(book.available_copies for book in self.books.values())
        borrowed = sum(book.total_copies - book.available_copies for book in self.books.values())
        print(f"   Available Copies: {available}")
        print(f"   Borrowed Copies: {borrowed}")
        
        # Member statistics
        print(f"\n👥 MEMBER STATISTICS:")
        print(f"   Total Members: {Member.total_members}")
        active_borrowers = sum(1 for member in self.members.values() if member.get_borrowed_count() > 0)
        print(f"   Active Borrowers: {active_borrowers}")
        
        # Available books
        print(f"\n📖 AVAILABLE BOOKS:")
        available_books = self.get_available_books()
        if available_books:
            for book in available_books:
                print(f"   • {book}")
        else:
            print("   No books available")
        
        print(f"\n{'='*60}\n")
    
    def _log_transaction(self, message):
        """
        Log a transaction (private helper method).
        
        Args:
            message (str): Transaction description
        """
        from datetime import datetime
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        self.transactions.append(f"[{timestamp}] {message}")
    
    def __str__(self):
        """String representation for display"""
        return f"{self.name} - {len(self.books)} books, {len(self.members)} members"


# ==================== TESTING ====================

def main():
    """Test the complete library system"""
    
    print("="*60)
    print("LIBRARY MANAGEMENT SYSTEM - COMPLETE SOLUTION")
    print("="*60)
    
    # Create library
    library = Library("City Central Library")
    print(f"\n✓ Created: {library}\n")
    
    # Add books
    print("="*60)
    print("ADDING BOOKS")
    print("="*60)
    book1 = library.add_book("978-0134685991", "Effective Python", "Brett Slatkin", 3)
    book2 = library.add_book("978-1491946008", "Fluent Python", "Luciano Ramalho", 2)
    book3 = library.add_book("978-0596809485", "Python Cookbook", "David Beazley", 2)
    book4 = library.add_book("978-1449355739", "Learning Python", "Mark Lutz", 4)
    book5 = library.add_book("978-0132350884", "Clean Code", "Robert Martin", 2)
    
    # Register members
    print(f"\n{'='*60}")
    print("REGISTERING MEMBERS")
    print("="*60)
    member1 = library.register_member("Alice Johnson", "alice@email.com", max_books=3)
    member2 = library.register_member("Bob Smith", "bob@email.com", max_books=2)
    member3 = library.register_member("Charlie Davis", "charlie@email.com", max_books=3)
    
    # Test transactions
    print(f"\n{'='*60}")
    print("BOOK CHECKOUT TRANSACTIONS")
    print("="*60)
    
    # Alice borrows 2 books
    library.checkout_book(member1.member_id, "978-0134685991")
    library.checkout_book(member1.member_id, "978-1491946008")
    
    # Bob borrows 2 books (reaches his limit)
    library.checkout_book(member2.member_id, "978-0596809485")
    library.checkout_book(member2.member_id, "978-1449355739")
    
    # Try to borrow when at limit
    print("\nAttempting to exceed borrowing limit:")
    library.checkout_book(member2.member_id, "978-0132350884")
    
    # Charlie borrows a book
    library.checkout_book(member3.member_id, "978-0132350884")
    
    # Return books
    print(f"\n{'='*60}")
    print("BOOK RETURN TRANSACTIONS")
    print("="*60)
    library.return_book(member1.member_id, "978-0134685991")
    library.return_book(member2.member_id, "978-0596809485")
    
    # Try to return a book not borrowed
    print("\nAttempting to return a book not borrowed:")
    library.return_book(member3.member_id, "978-1491946008")
    
    # Member information
    print(f"\n{'='*60}")
    print("MEMBER INFORMATION")
    print("="*60)
    for member_id in [member1.member_id, member2.member_id, member3.member_id]:
        info = library.get_member_info(member_id)
        if info:
            print(f"\n{info['name']} ({info['id']}):")
            print(f"  Email: {info['email']}")
            print(f"  Books: {info['books_borrowed']}/{info['max_books']}")
            if info['borrowed_titles']:
                print(f"  Currently borrowed:")
                for title in info['borrowed_titles']:
                    print(f"    • {title}")
    
    # Generate report
    library.generate_report()
    
    # Display class-level statistics
    print("="*60)
    print("CLASS-LEVEL STATISTICS")
    print("="*60)
    print(f"Total Books in System: {Book.total_books}")
    print(f"Total Members in System: {Member.total_members}")
    print("="*60)


if __name__ == "__main__":
    main()
