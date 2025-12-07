# Error Handling and Exceptions in Python

## 🎯 Learning Objectives
- Understand exceptions and error handling
- Use try-except blocks effectively
- Handle multiple exception types
- Work with finally and else clauses
- Raise custom exceptions
- Create exception handling best practices

---

## 📝 What are Exceptions?

**Exceptions** are errors that occur during program execution. Instead of crashing, Python allows you to catch and handle these errors gracefully.

### Common Built-in Exceptions

| Exception | Description | Example |
|-----------|-------------|---------|
| `ZeroDivisionError` | Division by zero | `5 / 0` |
| `ValueError` | Invalid value | `int("abc")` |
| `TypeError` | Wrong type | `"5" + 5` |
| `FileNotFoundError` | File doesn't exist | `open('missing.txt')` |
| `IndexError` | Invalid index | `[1, 2][5]` |
| `KeyError` | Invalid dict key | `{'a': 1}['b']` |
| `AttributeError` | Invalid attribute | `"text".undefined()` |
| `ImportError` | Import fails | `import nonexistent` |
| `NameError` | Undefined variable | `print(undefined_var)` |

```python
# Examples of exceptions
print(5 / 0)               # ZeroDivisionError
print(int("abc"))          # ValueError
print("5" + 5)             # TypeError
print([1, 2, 3][10])      # IndexError
print({"a": 1}["b"])      # KeyError
```

---

## 🛡️ try-except Block

Catch and handle exceptions.

### Basic Syntax
```python
try:
    # Code that might raise an exception
    result = 10 / 0
except:
    # Handle any exception
    print("An error occurred!")
```

### Specific Exception Type
```python
try:
    result = 10 / 0
except ZeroDivisionError:
    print("Cannot divide by zero!")
```

### Capture Exception Message
```python
try:
    result = int("abc")
except ValueError as e:
    print(f"Error: {e}")
    # Output: Error: invalid literal for int() with base 10: 'abc'
```

---

## 🎯 Multiple Exception Handling

### Multiple except Clauses
```python
try:
    x = int(input("Enter number: "))
    result = 10 / x
    print(f"Result: {result}")
except ValueError:
    print("Invalid input! Please enter a number.")
except ZeroDivisionError:
    print("Cannot divide by zero!")
```

### Handle Multiple Exceptions in One Block
```python
try:
    x = int(input("Enter number: "))
    result = 10 / x
except (ValueError, ZeroDivisionError) as e:
    print(f"Error occurred: {e}")
```

### Generic Exception Handler
```python
try:
    # Some code
    result = risky_operation()
except ValueError:
    print("ValueError occurred")
except ZeroDivisionError:
    print("ZeroDivisionError occurred")
except Exception as e:
    # Catch all other exceptions
    print(f"Unexpected error: {e}")
```

---

## 🔄 else and finally Clauses

### else Clause - Runs if No Exception
```python
try:
    x = int(input("Enter number: "))
    result = 10 / x
except ValueError:
    print("Invalid input!")
except ZeroDivisionError:
    print("Cannot divide by zero!")
else:
    # Only runs if no exception occurred
    print(f"Result: {result}")
```

### finally Clause - Always Runs
```python
try:
    file = open('data.txt', 'r')
    content = file.read()
    print(content)
except FileNotFoundError:
    print("File not found!")
finally:
    # Always executes (cleanup code)
    print("Cleanup: Closing file if opened")
    try:
        file.close()
    except:
        pass
```

### Complete Structure
```python
try:
    # Code that might raise exception
    result = risky_operation()
except SpecificError as e:
    # Handle specific exception
    print(f"Specific error: {e}")
except Exception as e:
    # Handle other exceptions
    print(f"General error: {e}")
else:
    # Runs if no exception
    print("Success!")
finally:
    # Always runs (cleanup)
    print("Cleanup completed")
```

---

## 🚀 Raising Exceptions

### raise Statement
```python
def divide(a, b):
    """Divide a by b"""
    if b == 0:
        raise ValueError("Cannot divide by zero!")
    return a / b

try:
    result = divide(10, 0)
except ValueError as e:
    print(f"Error: {e}")
```

### Re-raising Exceptions
```python
def process_data(data):
    try:
        # Process data
        result = risky_operation(data)
        return result
    except Exception as e:
        print(f"Error in process_data: {e}")
        raise  # Re-raise the same exception
```

### Raising Different Exception
```python
def get_user(user_id):
    try:
        # Database operation
        user = database.find(user_id)
    except DatabaseError as e:
        # Convert to application-specific exception
        raise UserNotFoundError(f"User {user_id} not found") from e
```

---

## 🎨 Custom Exceptions

Create your own exception classes.

### Basic Custom Exception
```python
class InvalidAgeError(Exception):
    """Raised when age is invalid"""
    pass

def set_age(age):
    if age < 0:
        raise InvalidAgeError("Age cannot be negative!")
    if age > 150:
        raise InvalidAgeError("Age seems unrealistic!")
    return age

try:
    user_age = set_age(-5)
except InvalidAgeError as e:
    print(f"Error: {e}")
```

### Custom Exception with Attributes
```python
class InsufficientFundsError(Exception):
    """Raised when account has insufficient funds"""
    def __init__(self, balance, amount):
        self.balance = balance
        self.amount = amount
        self.shortage = amount - balance
        message = f"Insufficient funds: need ${amount}, have ${balance}"
        super().__init__(message)

def withdraw(balance, amount):
    if amount > balance:
        raise InsufficientFundsError(balance, amount)
    return balance - amount

try:
    new_balance = withdraw(100, 150)
except InsufficientFundsError as e:
    print(e)
    print(f"Short by: ${e.shortage}")
```

### Exception Hierarchy
```python
class DatabaseError(Exception):
    """Base exception for database errors"""
    pass

class ConnectionError(DatabaseError):
    """Database connection failed"""
    pass

class QueryError(DatabaseError):
    """Database query failed"""
    pass

try:
    # Some database operation
    execute_query()
except ConnectionError:
    print("Failed to connect to database")
except QueryError:
    print("Query execution failed")
except DatabaseError:
    print("General database error")
```

---

## 📊 Practical Exception Handling

### Example 1: Safe Number Input
```python
def get_integer_input(prompt, min_val=None, max_val=None):
    """Get integer input with validation"""
    while True:
        try:
            value = int(input(prompt))
            
            if min_val is not None and value < min_val:
                print(f"Value must be at least {min_val}")
                continue
            
            if max_val is not None and value > max_val:
                print(f"Value must be at most {max_val}")
                continue
            
            return value
            
        except ValueError:
            print("Invalid input! Please enter a number.")
        except KeyboardInterrupt:
            print("\nOperation cancelled")
            return None

# Usage
age = get_integer_input("Enter your age: ", min_val=0, max_val=120)
```

### Example 2: Safe File Reading
```python
def read_file_safely(filename):
    """Read file with comprehensive error handling"""
    try:
        with open(filename, 'r', encoding='utf-8') as file:
            return file.read()
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found")
        return None
    except PermissionError:
        print(f"Error: No permission to read '{filename}'")
        return None
    except UnicodeDecodeError:
        print(f"Error: Cannot decode '{filename}' as UTF-8")
        return None
    except Exception as e:
        print(f"Unexpected error reading '{filename}': {e}")
        return None

# Usage
content = read_file_safely('data.txt')
if content:
    print(content)
```

### Example 3: Safe Division Calculator
```python
def safe_divide(a, b):
    """Perform division with error handling"""
    try:
        result = a / b
        return result, None
    except ZeroDivisionError:
        return None, "Cannot divide by zero"
    except TypeError:
        return None, "Both arguments must be numbers"
    except Exception as e:
        return None, f"Unexpected error: {e}"

# Usage
result, error = safe_divide(10, 2)
if error:
    print(f"Error: {error}")
else:
    print(f"Result: {result}")
```

### Example 4: API Request Handler
```python
import requests  # Example with external library

def fetch_data(url, max_retries=3):
    """Fetch data from API with retry logic"""
    for attempt in range(max_retries):
        try:
            response = requests.get(url, timeout=5)
            response.raise_for_status()  # Raise exception for bad status
            return response.json(), None
            
        except requests.ConnectionError:
            error = f"Connection failed (attempt {attempt + 1}/{max_retries})"
            print(error)
            if attempt == max_retries - 1:
                return None, "Connection failed after all retries"
                
        except requests.Timeout:
            error = f"Request timeout (attempt {attempt + 1}/{max_retries})"
            print(error)
            if attempt == max_retries - 1:
                return None, "Request timeout after all retries"
                
        except requests.HTTPError as e:
            return None, f"HTTP error: {e}"
            
        except ValueError:
            return None, "Invalid JSON response"
            
    return None, "Failed after all retries"
```

### Example 5: Database Transaction
```python
class Database:
    """Simulated database with transactions"""
    
    def begin_transaction(self):
        """Start transaction"""
        print("Transaction started")
    
    def commit(self):
        """Commit transaction"""
        print("Transaction committed")
    
    def rollback(self):
        """Rollback transaction"""
        print("Transaction rolled back")
    
    def execute(self, query):
        """Execute query"""
        print(f"Executing: {query}")

def safe_database_operation(db, queries):
    """Execute queries with transaction management"""
    try:
        db.begin_transaction()
        
        for query in queries:
            db.execute(query)
        
        db.commit()
        return True, "All queries executed successfully"
        
    except Exception as e:
        db.rollback()
        return False, f"Transaction failed: {e}"

# Usage
db = Database()
queries = ["INSERT...", "UPDATE...", "DELETE..."]
success, message = safe_database_operation(db, queries)
print(message)
```

### Example 6: Context Manager for Resources
```python
class DatabaseConnection:
    """Context manager for database connections"""
    
    def __init__(self, host, port):
        self.host = host
        self.port = port
        self.connection = None
    
    def __enter__(self):
        """Open connection"""
        try:
            print(f"Connecting to {self.host}:{self.port}...")
            self.connection = self._connect()
            return self.connection
        except Exception as e:
            raise ConnectionError(f"Failed to connect: {e}")
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Close connection (always runs)"""
        if self.connection:
            print("Closing connection...")
            self.connection.close()
        
        # Return False to propagate exception, True to suppress
        return False
    
    def _connect(self):
        """Simulate connection"""
        return {"connected": True}

# Usage
try:
    with DatabaseConnection('localhost', 5432) as conn:
        print("Performing database operations...")
        # Do work with connection
except ConnectionError as e:
    print(f"Connection error: {e}")
```

### Example 7: Retry Decorator
```python
import time
from functools import wraps

def retry(max_attempts=3, delay=1, exceptions=(Exception,)):
    """Retry decorator for functions"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except exceptions as e:
                    if attempt == max_attempts - 1:
                        raise
                    print(f"Attempt {attempt + 1} failed: {e}")
                    print(f"Retrying in {delay} seconds...")
                    time.sleep(delay)
        return wrapper
    return decorator

# Usage
@retry(max_attempts=3, delay=2, exceptions=(ConnectionError,))
def fetch_data():
    """Function that might fail"""
    import random
    if random.random() < 0.7:  # 70% chance of failure
        raise ConnectionError("Connection failed")
    return "Data fetched successfully"

try:
    result = fetch_data()
    print(result)
except ConnectionError:
    print("Failed after all retries")
```

---

## 🎓 Exception Handling Best Practices

### ✅ DO: Be Specific
```python
# ✅ Good - catch specific exceptions
try:
    value = int(user_input)
except ValueError:
    print("Invalid number format")

# ❌ Bad - catch all exceptions
try:
    value = int(user_input)
except:
    print("Something went wrong")
```

### ✅ DO: Provide Helpful Error Messages
```python
# ✅ Good - informative message
try:
    file = open(filename, 'r')
except FileNotFoundError:
    print(f"Error: Cannot find file '{filename}'")
    print("Please check the filename and try again")

# ❌ Bad - generic message
try:
    file = open(filename, 'r')
except FileNotFoundError:
    print("Error")
```

### ✅ DO: Clean Up Resources
```python
# ✅ Good - use context manager
with open('file.txt', 'r') as file:
    content = file.read()

# ✅ Good - use finally
file = None
try:
    file = open('file.txt', 'r')
    content = file.read()
finally:
    if file:
        file.close()
```

### ❌ DON'T: Use Bare except
```python
# ❌ Bad - catches everything including KeyboardInterrupt
try:
    risky_operation()
except:
    pass

# ✅ Good - catch specific or Exception
try:
    risky_operation()
except Exception as e:
    print(f"Error: {e}")
```

### ❌ DON'T: Silently Ignore Errors
```python
# ❌ Bad - swallows error
try:
    critical_operation()
except Exception:
    pass  # Silent failure!

# ✅ Good - log or report error
try:
    critical_operation()
except Exception as e:
    logger.error(f"Critical operation failed: {e}")
    raise  # Re-raise if critical
```

### ✅ DO: Return Error Status
```python
# ✅ Good - return status and error
def process_data(data):
    try:
        result = transform(data)
        return result, None
    except ValueError as e:
        return None, str(e)

# Usage
result, error = process_data(my_data)
if error:
    print(f"Error: {error}")
else:
    use_result(result)
```

---

## 🔍 Debugging with Exceptions

### Print Stack Trace
```python
import traceback

try:
    risky_operation()
except Exception as e:
    print(f"Error: {e}")
    print("\nFull traceback:")
    traceback.print_exc()
```

### Get Exception Details
```python
import sys

try:
    result = 10 / 0
except Exception as e:
    exc_type, exc_value, exc_traceback = sys.exc_info()
    print(f"Type: {exc_type.__name__}")
    print(f"Message: {exc_value}")
    print(f"Line: {exc_traceback.tb_lineno}")
```

---

## ⚠️ Common Pitfalls

### Mistake 1: Catching Too Broad
```python
# ❌ Wrong - catches KeyboardInterrupt too
try:
    process_data()
except:
    print("Error occurred")

# ✅ Correct - catch Exception, not BaseException
try:
    process_data()
except Exception as e:
    print(f"Error occurred: {e}")
```

### Mistake 2: Not Re-raising When Needed
```python
# ❌ Wrong - swallows important error
def critical_function():
    try:
        important_operation()
    except Exception as e:
        print(f"Error: {e}")
        return None  # Caller doesn't know it failed!

# ✅ Correct - re-raise after logging
def critical_function():
    try:
        important_operation()
    except Exception as e:
        logger.error(f"Critical error: {e}")
        raise  # Let caller handle it
```

### Mistake 3: Exception in except Block
```python
# ❌ Wrong - exception in handler masks original error
try:
    risky_operation()
except Exception as e:
    undefined_function()  # NameError masks original exception!

# ✅ Correct - handle exceptions in handler too
try:
    risky_operation()
except Exception as e:
    try:
        log_error(e)
    except:
        pass  # Don't let logging error mask original
    raise
```

---

## ✅ Key Takeaways

1. ✅ Use try-except to handle exceptions gracefully
2. ✅ Catch specific exceptions, not bare except
3. ✅ Use finally for cleanup code (always runs)
4. ✅ Use else for code that runs if no exception
5. ✅ Create custom exceptions for domain-specific errors
6. ✅ Provide helpful error messages
7. ✅ Don't silently ignore errors
8. ✅ Use context managers for resource management
9. ✅ Re-raise exceptions when appropriate
10. ✅ Log exceptions for debugging

---

**Practice**: Complete Lab 11 - Error Handling and Exceptions

**Next**: Review Module 10 and complete quizzes!

**கற்க கசடற** - Learn Flawlessly

