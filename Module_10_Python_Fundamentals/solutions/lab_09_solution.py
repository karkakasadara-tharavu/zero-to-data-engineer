"""
Module 10 - Lab 09 Solution: Error Handling
============================================
Complete solutions with explanations.

கற்க கசடற - Learn Flawlessly

Estimated Time: 60 minutes
Concepts: try/except, exception types, custom exceptions, error handling patterns
"""

# Part 1: Basic Exception Handling (10 minutes)
print("Part 1: Basic Exception Handling")
print("-" * 40)

# Division by zero
def safe_divide(a, b):
    """Safely divide two numbers."""
    try:
        result = a / b
        return result
    except ZeroDivisionError:
        print(f"Error: Cannot divide {a} by zero")
        return None

print(f"10 / 2 = {safe_divide(10, 2)}")
print(f"10 / 0 = {safe_divide(10, 0)}")

# Type errors
def safe_add(a, b):
    """Safely add two values."""
    try:
        return a + b
    except TypeError as e:
        print(f"Error: Cannot add {type(a).__name__} and {type(b).__name__}")
        return None

print(f"\n5 + 3 = {safe_add(5, 3)}")
print(f"5 + '3' = {safe_add(5, '3')}")

# Index errors
def safe_get_item(lst, index):
    """Safely get item from list."""
    try:
        return lst[index]
    except IndexError:
        print(f"Error: Index {index} out of range for list of length {len(lst)}")
        return None

my_list = [1, 2, 3]
print(f"\nList: {my_list}")
print(f"Index 1: {safe_get_item(my_list, 1)}")
print(f"Index 10: {safe_get_item(my_list, 10)}")

print()

# Part 2: Multiple Exception Handling (10 minutes)
print("Part 2: Multiple Exception Handling")
print("-" * 40)

def safe_calculate(numbers, operation):
    """
    Perform calculation on list of numbers.
    Operations: 'sum', 'average', 'max', 'min'
    """
    try:
        if not numbers:
            raise ValueError("List cannot be empty")
        
        if operation == 'sum':
            return sum(numbers)
        elif operation == 'average':
            return sum(numbers) / len(numbers)
        elif operation == 'max':
            return max(numbers)
        elif operation == 'min':
            return min(numbers)
        else:
            raise ValueError(f"Unknown operation: {operation}")
    
    except ValueError as e:
        print(f"ValueError: {e}")
        return None
    except TypeError as e:
        print(f"TypeError: Invalid data type - {e}")
        return None
    except Exception as e:
        print(f"Unexpected error: {e}")
        return None

# Test with valid data
numbers = [10, 20, 30, 40, 50]
print(f"Numbers: {numbers}")
print(f"Sum: {safe_calculate(numbers, 'sum')}")
print(f"Average: {safe_calculate(numbers, 'average')}")

# Test with invalid data
print(f"\nEmpty list sum: {safe_calculate([], 'sum')}")
print(f"Invalid operation: {safe_calculate(numbers, 'median')}")

print()

# Part 3: Finally Clause (10 minutes)
print("Part 3: Finally Clause")
print("-" * 40)

def read_file_with_finally(filename):
    """Read file with proper cleanup."""
    file = None
    try:
        print(f"Opening {filename}...")
        file = open(filename, 'r')
        content = file.read()
        print(f"Read {len(content)} characters")
        return content
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found")
        return None
    except IOError as e:
        print(f"IO Error: {e}")
        return None
    finally:
        if file:
            file.close()
            print("File closed")
        else:
            print("No file to close")

# Test with non-existent file
read_file_with_finally("nonexistent.txt")

# Create and read actual file
from pathlib import Path
test_file = Path("test_finally.txt")
test_file.write_text("Test content for finally clause")
print()
content = read_file_with_finally(str(test_file))
test_file.unlink()

print()

# Part 4: Raising Exceptions (15 minutes)
print("Part 4: Raising Exceptions")
print("-" * 40)

def validate_age(age):
    """Validate age input."""
    if not isinstance(age, int):
        raise TypeError("Age must be an integer")
    if age < 0:
        raise ValueError("Age cannot be negative")
    if age > 150:
        raise ValueError("Age seems unrealistic")
    return True

def create_user(name, age):
    """Create user with validation."""
    try:
        if not name or not name.strip():
            raise ValueError("Name cannot be empty")
        
        validate_age(age)
        
        user = {"name": name, "age": age}
        print(f"✓ User created: {user}")
        return user
    
    except (ValueError, TypeError) as e:
        print(f"✗ Validation error: {e}")
        return None

# Test valid user
create_user("Alice", 30)

# Test invalid users
print()
create_user("", 25)
create_user("Bob", -5)
create_user("Charlie", "thirty")
create_user("Diana", 200)

print()

# Part 5: Custom Exceptions (15 minutes)
print("Part 5: Custom Exceptions")
print("-" * 40)

class InsufficientFundsError(Exception):
    """Raised when account has insufficient funds."""
    pass

class InvalidAmountError(Exception):
    """Raised when amount is invalid."""
    pass

class BankAccount:
    """Simple bank account with error handling."""
    
    def __init__(self, account_number, balance=0):
        self.account_number = account_number
        self.balance = balance
        self.transactions = []
    
    def deposit(self, amount):
        """Deposit money."""
        if amount <= 0:
            raise InvalidAmountError(f"Deposit amount must be positive, got {amount}")
        
        self.balance += amount
        self.transactions.append(f"Deposit: +${amount:.2f}")
        print(f"✓ Deposited ${amount:.2f}. New balance: ${self.balance:.2f}")
    
    def withdraw(self, amount):
        """Withdraw money."""
        if amount <= 0:
            raise InvalidAmountError(f"Withdrawal amount must be positive, got {amount}")
        
        if amount > self.balance:
            raise InsufficientFundsError(
                f"Cannot withdraw ${amount:.2f}. Current balance: ${self.balance:.2f}"
            )
        
        self.balance -= amount
        self.transactions.append(f"Withdrawal: -${amount:.2f}")
        print(f"✓ Withdrew ${amount:.2f}. New balance: ${self.balance:.2f}")
    
    def get_balance(self):
        """Get current balance."""
        return self.balance
    
    def get_statement(self):
        """Get account statement."""
        print(f"\n{'='*50}")
        print(f"Account: {self.account_number}")
        print(f"Balance: ${self.balance:.2f}")
        print(f"\nRecent Transactions:")
        for transaction in self.transactions[-5:]:
            print(f"  {transaction}")
        print(f"{'='*50}")

# Test bank account
account = BankAccount("ACC-12345", 1000)

try:
    account.deposit(500)
    account.withdraw(200)
    account.withdraw(100)
    
    # This will raise InsufficientFundsError
    account.withdraw(2000)
    
except InsufficientFundsError as e:
    print(f"✗ Transaction failed: {e}")

try:
    # This will raise InvalidAmountError
    account.deposit(-50)
except InvalidAmountError as e:
    print(f"✗ Invalid operation: {e}")

account.get_statement()

print()

# Part 6: Context Managers (10 minutes)
print("Part 6: Context Managers")
print("-" * 40)

class FileHandler:
    """Custom context manager for file operations."""
    
    def __init__(self, filename, mode='r'):
        self.filename = filename
        self.mode = mode
        self.file = None
    
    def __enter__(self):
        """Open file when entering context."""
        print(f"Opening {self.filename} in mode '{self.mode}'")
        self.file = open(self.filename, self.mode)
        return self.file
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Close file when exiting context."""
        if self.file:
            self.file.close()
            print(f"Closed {self.filename}")
        
        if exc_type:
            print(f"Exception occurred: {exc_type.__name__}: {exc_val}")
            return False  # Re-raise exception
        
        return True

# Use custom context manager
test_file = Path("context_test.txt")
test_file.write_text("Context manager test")

print("Using custom context manager:")
with FileHandler(str(test_file), 'r') as f:
    content = f.read()
    print(f"Content: {content}")

test_file.unlink()

# Standard context manager
test_file = Path("standard_test.txt")
print("\nUsing standard context manager:")
with open(test_file, 'w') as f:
    f.write("Standard context manager")
print("File automatically closed")

with open(test_file, 'r') as f:
    print(f"Content: {f.read()}")

test_file.unlink()

print()

# Part 7: Practical Challenge - Robust Data Processor (15 minutes)
print("Part 7: Practical Challenge - Robust Data Processor")
print("-" * 40)

class DataValidationError(Exception):
    """Custom exception for data validation errors."""
    pass

class DataProcessor:
    """Process data with comprehensive error handling."""
    
    def __init__(self):
        self.processed_count = 0
        self.error_count = 0
        self.errors = []
    
    def validate_record(self, record):
        """Validate a data record."""
        if not isinstance(record, dict):
            raise DataValidationError("Record must be a dictionary")
        
        required_fields = ['id', 'name', 'value']
        for field in required_fields:
            if field not in record:
                raise DataValidationError(f"Missing required field: {field}")
        
        if not isinstance(record['id'], int):
            raise DataValidationError("ID must be an integer")
        
        if not isinstance(record['name'], str) or not record['name'].strip():
            raise DataValidationError("Name must be a non-empty string")
        
        if not isinstance(record['value'], (int, float)):
            raise DataValidationError("Value must be a number")
        
        if record['value'] < 0:
            raise DataValidationError("Value cannot be negative")
        
        return True
    
    def process_record(self, record):
        """Process a single record."""
        try:
            self.validate_record(record)
            
            # Simulate processing
            processed = {
                'id': record['id'],
                'name': record['name'].upper(),
                'value': record['value'] * 1.1,  # 10% increase
                'status': 'processed'
            }
            
            self.processed_count += 1
            return processed
        
        except DataValidationError as e:
            self.error_count += 1
            self.errors.append({
                'record': record,
                'error': str(e)
            })
            return None
        except Exception as e:
            self.error_count += 1
            self.errors.append({
                'record': record,
                'error': f"Unexpected error: {str(e)}"
            })
            return None
    
    def process_batch(self, records):
        """Process multiple records."""
        results = []
        
        print(f"Processing {len(records)} records...")
        
        for i, record in enumerate(records, 1):
            try:
                result = self.process_record(record)
                if result:
                    results.append(result)
                    print(f"  ✓ Record {i}: Processed successfully")
                else:
                    print(f"  ✗ Record {i}: Validation failed")
            except Exception as e:
                print(f"  ✗ Record {i}: Unexpected error - {e}")
                self.error_count += 1
        
        return results
    
    def get_summary(self):
        """Get processing summary."""
        total = self.processed_count + self.error_count
        success_rate = (self.processed_count / total * 100) if total > 0 else 0
        
        print(f"\n{'='*60}")
        print("PROCESSING SUMMARY")
        print(f"{'='*60}")
        print(f"Total Records: {total}")
        print(f"Processed: {self.processed_count}")
        print(f"Errors: {self.error_count}")
        print(f"Success Rate: {success_rate:.1f}%")
        
        if self.errors:
            print(f"\nError Details:")
            for i, error_info in enumerate(self.errors, 1):
                print(f"  {i}. {error_info['error']}")
                print(f"     Record: {error_info['record']}")
        
        print(f"{'='*60}")

# Test data with various errors
test_data = [
    {'id': 1, 'name': 'Alice', 'value': 100},      # Valid
    {'id': 2, 'name': 'Bob', 'value': 200},        # Valid
    {'id': '3', 'name': 'Charlie', 'value': 300},  # Invalid ID type
    {'id': 4, 'name': '', 'value': 400},           # Invalid name
    {'id': 5, 'name': 'Eve', 'value': -50},        # Invalid value
    {'id': 6, 'value': 600},                       # Missing name
    {'id': 7, 'name': 'Frank', 'value': 700},      # Valid
    "Not a dictionary",                             # Invalid type
]

# Process data
processor = DataProcessor()
results = processor.process_batch(test_data)

# Show results
print(f"\nProcessed Results:")
for result in results:
    print(f"  {result}")

# Show summary
processor.get_summary()

print()

# ============================================================================
# Verification Code
# ============================================================================

def verify_lab_09():
    """Verify that all lab exercises are completed correctly."""
    print("\n" + "="*60)
    print("Lab 09 Verification")
    print("="*60)
    
    passed = 0
    total = 7
    
    # Test basic exception handling
    try:
        assert safe_divide(10, 2) == 5, "Safe divide wrong"
        assert safe_divide(10, 0) is None, "Division by zero not handled"
        
        print("✅ Basic exception handling - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Basic exception handling - FAILED: {e}")
    
    # Test multiple exceptions
    try:
        assert safe_calculate([1, 2, 3], 'sum') == 6, "Sum wrong"
        assert safe_calculate([], 'sum') is None, "Empty list not handled"
        
        print("✅ Multiple exception handling - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Multiple exception handling - FAILED: {e}")
    
    # Test raising exceptions
    try:
        # Should succeed
        user = create_user("Test", 25)
        assert user is not None, "Valid user creation failed"
        
        # Should fail
        invalid = create_user("", 25)
        assert invalid is None, "Invalid user not rejected"
        
        print("✅ Raising exceptions - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Raising exceptions - FAILED: {e}")
    
    # Test custom exceptions
    try:
        test_account = BankAccount("TEST-001", 100)
        test_account.deposit(50)
        assert test_account.get_balance() == 150, "Deposit wrong"
        
        test_account.withdraw(30)
        assert test_account.get_balance() == 120, "Withdrawal wrong"
        
        # Should raise InsufficientFundsError
        try:
            test_account.withdraw(200)
            assert False, "Should have raised InsufficientFundsError"
        except InsufficientFundsError:
            pass  # Expected
        
        print("✅ Custom exceptions - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Custom exceptions - FAILED: {e}")
    
    # Test context managers
    try:
        test_file = Path("verify_context.txt")
        test_file.write_text("test")
        
        with open(test_file, 'r') as f:
            content = f.read()
            assert content == "test", "Context manager read wrong"
        
        assert f.closed, "File not closed after context"
        
        test_file.unlink()
        
        print("✅ Context managers - PASSED")
        passed += 1
    except (AssertionError, Exception) as e:
        print(f"❌ Context managers - FAILED: {e}")
    
    # Test validation
    try:
        validate_age(25)  # Should succeed
        
        try:
            validate_age(-5)
            assert False, "Negative age should raise error"
        except ValueError:
            pass  # Expected
        
        try:
            validate_age("twenty")
            assert False, "String age should raise error"
        except TypeError:
            pass  # Expected
        
        print("✅ Validation - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Validation - FAILED: {e}")
    
    # Test data processor
    try:
        test_processor = DataProcessor()
        
        valid_record = {'id': 1, 'name': 'Test', 'value': 100}
        result = test_processor.process_record(valid_record)
        
        assert result is not None, "Valid record processing failed"
        assert result['name'] == 'TEST', "Name processing wrong"
        assert test_processor.processed_count == 1, "Count wrong"
        
        invalid_record = {'id': 'bad', 'name': 'Test', 'value': 100}
        result = test_processor.process_record(invalid_record)
        
        assert result is None, "Invalid record should fail"
        assert test_processor.error_count == 1, "Error count wrong"
        
        print("✅ Data processor - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Data processor - FAILED: {e}")
    
    print("="*60)
    print(f"Score: {passed}/{total} ({passed/total*100:.0f}%)")
    print("="*60)
    
    if passed == total:
        print("🎉 Congratulations! All tests passed!")
        print("\n📚 Key Learnings:")
        print("  1. try/except for error handling")
        print("  2. Multiple exception types")
        print("  3. finally clause for cleanup")
        print("  4. Raising exceptions")
        print("  5. Custom exception classes")
        print("  6. Context managers with 'with'")
        print("  7. Robust data validation")
        print("\n🚀 Next Steps:")
        print("  - Try Lab 10: Comprehensive Review")
        print("  - Review Section 14: Error Handling")
        print("  - Practice defensive programming")
    else:
        print("📝 Keep practicing! Review the sections and try again.")

# Run verification
verify_lab_09()
