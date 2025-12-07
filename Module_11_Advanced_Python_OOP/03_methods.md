# Section 03: Methods Deep Dive

**கற்க கசடற - Learn Flawlessly**

## Types of Methods in Python

Python classes support three types of methods:
1. **Instance Methods** - Operate on instance data (use `self`)
2. **Class Methods** - Operate on class data (use `@classmethod` and `cls`)
3. **Static Methods** - Utility functions (use `@staticmethod`, no self or cls)

## Instance Methods

**Instance methods** are the most common type. They:
- Take `self` as the first parameter
- Can access and modify instance attributes
- Can access class attributes
- Are called on instances

```python
class Rectangle:
    def __init__(self, width, height):
        self.width = width
        self.height = height
    
    def get_area(self):  # Instance method
        """Calculate and return the area."""
        return self.width * self.height
    
    def get_perimeter(self):  # Instance method
        """Calculate and return the perimeter."""
        return 2 * (self.width + self.height)
    
    def resize(self, width, height):  # Instance method modifies state
        """Resize the rectangle."""
        self.width = width
        self.height = height

rect = Rectangle(10, 5)
print(rect.get_area())        # 50
print(rect.get_perimeter())   # 30
rect.resize(20, 10)
print(rect.get_area())        # 200
```

## Class Methods (`@classmethod`)

**Class methods**:
- Take `cls` as the first parameter (refers to the class itself)
- Can access and modify class attributes
- Cannot access instance attributes
- Are often used as alternative constructors
- Are called on the class or instances

```python
class Employee:
    company_name = "TechCorp"
    employee_count = 0
    
    def __init__(self, name, salary):
        self.name = name
        self.salary = salary
        Employee.employee_count += 1
    
    @classmethod
    def from_string(cls, emp_string):
        """Alternative constructor from 'Name,Salary' string."""
        name, salary = emp_string.split(',')
        return cls(name, int(salary))
    
    @classmethod
    def change_company_name(cls, new_name):
        """Change the company name for all employees."""
        cls.company_name = new_name
    
    @classmethod
    def get_employee_count(cls):
        """Return total number of employees."""
        return cls.employee_count

# Regular constructor
emp1 = Employee("Alice", 50000)

# Alternative constructor (class method)
emp2 = Employee.from_string("Bob,60000")

print(Employee.get_employee_count())  # 2
Employee.change_company_name("NewTech Inc.")
print(emp1.company_name)  # NewTech Inc.
print(emp2.company_name)  # NewTech Inc.
```

### Common Use Cases for Class Methods:

1. **Alternative Constructors**:
```python
class Date:
    def __init__(self, year, month, day):
        self.year = year
        self.month = month
        self.day = day
    
    @classmethod
    def from_string(cls, date_string):
        """Create Date from 'YYYY-MM-DD' string."""
        year, month, day = map(int, date_string.split('-'))
        return cls(year, month, day)
    
    @classmethod
    def today(cls):
        """Create Date for today."""
        import datetime
        today = datetime.date.today()
        return cls(today.year, today.month, today.day)

date1 = Date(2024, 12, 7)
date2 = Date.from_string("2024-12-07")
date3 = Date.today()
```

2. **Factory Methods**:
```python
class Pizza:
    def __init__(self, ingredients):
        self.ingredients = ingredients
    
    @classmethod
    def margherita(cls):
        """Create a Margherita pizza."""
        return cls(['mozzarella', 'tomatoes', 'basil'])
    
    @classmethod
    def pepperoni(cls):
        """Create a Pepperoni pizza."""
        return cls(['mozzarella', 'tomatoes', 'pepperoni'])
    
    def __repr__(self):
        return f"Pizza({', '.join(self.ingredients)})"

pizza1 = Pizza.margherita()
pizza2 = Pizza.pepperoni()
print(pizza1)  # Pizza(mozzarella, tomatoes, basil)
print(pizza2)  # Pizza(mozzarella, tomatoes, pepperoni)
```

## Static Methods (`@staticmethod`)

**Static methods**:
- Don't take `self` or `cls` as first parameter
- Cannot access instance or class attributes directly
- Are utility functions related to the class
- Are called on the class or instances

```python
class MathOperations:
    @staticmethod
    def add(x, y):
        """Add two numbers."""
        return x + y
    
    @staticmethod
    def multiply(x, y):
        """Multiply two numbers."""
        return x * y
    
    @staticmethod
    def is_even(number):
        """Check if number is even."""
        return number % 2 == 0

# Call without creating instance
print(MathOperations.add(5, 3))        # 8
print(MathOperations.multiply(4, 7))   # 28
print(MathOperations.is_even(10))      # True

# Can also call on instances (but why would you?)
math = MathOperations()
print(math.add(2, 2))  # 4
```

### When to Use Static Methods:

1. **Utility Functions**:
```python
class StringHelper:
    @staticmethod
    def reverse(text):
        """Reverse a string."""
        return text[::-1]
    
    @staticmethod
    def capitalize_words(text):
        """Capitalize each word."""
        return ' '.join(word.capitalize() for word in text.split())
    
    @staticmethod
    def remove_spaces(text):
        """Remove all spaces from string."""
        return text.replace(' ', '')

print(StringHelper.reverse("hello"))  # olleh
print(StringHelper.capitalize_words("hello world"))  # Hello World
```

2. **Validation Functions**:
```python
class User:
    def __init__(self, username, email):
        if not User.is_valid_email(email):
            raise ValueError("Invalid email format!")
        self.username = username
        self.email = email
    
    @staticmethod
    def is_valid_email(email):
        """Check if email format is valid."""
        import re
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return re.match(pattern, email) is not None
    
    @staticmethod
    def is_strong_password(password):
        """Check if password is strong enough."""
        return (len(password) >= 8 and
                any(c.isupper() for c in password) and
                any(c.islower() for c in password) and
                any(c.isdigit() for c in password))

# Use static methods before creating instance
email = "user@example.com"
if User.is_valid_email(email):
    user = User("john_doe", email)
```

## Comparing All Three Types

```python
class Employee:
    # Class attribute
    company = "TechCorp"
    raise_percentage = 1.05
    
    def __init__(self, name, salary):
        self.name = name
        self.salary = salary
    
    # Instance method - works with instance data
    def give_raise(self):
        """Give raise to this employee."""
        self.salary = int(self.salary * Employee.raise_percentage)
    
    # Class method - works with class data
    @classmethod
    def set_raise_percentage(cls, percentage):
        """Change raise percentage for all employees."""
        cls.raise_percentage = percentage
    
    # Class method - alternative constructor
    @classmethod
    def from_string(cls, emp_str):
        """Create employee from 'Name,Salary' string."""
        name, salary = emp_str.split(',')
        return cls(name, int(salary))
    
    # Static method - utility function
    @staticmethod
    def is_valid_salary(salary):
        """Check if salary is valid."""
        return salary >= 0 and salary <= 1000000
    
    def __repr__(self):
        return f"Employee('{self.name}', {self.salary})"

# Instance method usage
emp1 = Employee("Alice", 50000)
emp1.give_raise()
print(emp1)  # Employee('Alice', 52500)

# Class method usage
Employee.set_raise_percentage(1.10)  # 10% raise
emp1.give_raise()
print(emp1)  # Employee('Alice', 57750)

# Class method as constructor
emp2 = Employee.from_string("Bob,60000")
print(emp2)  # Employee('Bob', 60000)

# Static method usage
print(Employee.is_valid_salary(75000))  # True
print(Employee.is_valid_salary(-1000))  # False
```

## Practical Example: Bank Account System

```python
class BankAccount:
    """Bank account with multiple method types."""
    
    # Class attributes
    bank_name = "National Bank"
    interest_rate = 0.03
    account_count = 0
    
    def __init__(self, owner, initial_balance=0):
        """Create new account."""
        self.owner = owner
        self.balance = initial_balance
        self.account_number = BankAccount._generate_account_number()
        self.transactions = []
        BankAccount.account_count += 1
    
    # Instance methods
    def deposit(self, amount):
        """Deposit money into account."""
        if not BankAccount.is_valid_amount(amount):
            raise ValueError("Invalid deposit amount!")
        self.balance += amount
        self.transactions.append(f"Deposit: +${amount}")
        return self.balance
    
    def withdraw(self, amount):
        """Withdraw money from account."""
        if not BankAccount.is_valid_amount(amount):
            raise ValueError("Invalid withdrawal amount!")
        if amount > self.balance:
            raise ValueError("Insufficient funds!")
        self.balance -= amount
        self.transactions.append(f"Withdrawal: -${amount}")
        return self.balance
    
    def apply_interest(self):
        """Apply interest to account balance."""
        interest = self.balance * BankAccount.interest_rate
        self.balance += interest
        self.transactions.append(f"Interest: +${interest:.2f}")
    
    def get_statement(self):
        """Return account statement."""
        statement = f"\n{'='*50}\n"
        statement += f"{BankAccount.bank_name} - Account Statement\n"
        statement += f"{'='*50}\n"
        statement += f"Account: {self.account_number}\n"
        statement += f"Owner: {self.owner}\n"
        statement += f"Balance: ${self.balance:.2f}\n"
        statement += f"\nRecent Transactions:\n"
        for trans in self.transactions[-5:]:  # Last 5 transactions
            statement += f"  {trans}\n"
        statement += f"{'='*50}\n"
        return statement
    
    # Class methods
    @classmethod
    def set_interest_rate(cls, new_rate):
        """Change interest rate for all accounts."""
        cls.interest_rate = new_rate
    
    @classmethod
    def from_csv_row(cls, csv_row):
        """Create account from CSV row 'Owner,Balance'."""
        owner, balance = csv_row.split(',')
        return cls(owner, float(balance))
    
    @classmethod
    def get_total_accounts(cls):
        """Return total number of accounts."""
        return cls.account_count
    
    # Static methods
    @staticmethod
    def is_valid_amount(amount):
        """Check if amount is valid."""
        return amount > 0
    
    @staticmethod
    def _generate_account_number():
        """Generate random account number."""
        import random
        return f"ACC{random.randint(100000, 999999)}"
    
    @staticmethod
    def calculate_compound_interest(principal, rate, time):
        """Calculate compound interest."""
        return principal * ((1 + rate) ** time)
    
    def __repr__(self):
        return f"BankAccount('{self.owner}', {self.balance})"

# Usage examples
# Instance methods
account1 = BankAccount("Alice", 1000)
account1.deposit(500)
account1.withdraw(200)
account1.apply_interest()
print(account1.get_statement())

# Class methods
BankAccount.set_interest_rate(0.05)  # 5% interest
account2 = BankAccount.from_csv_row("Bob,2000")
print(f"Total accounts: {BankAccount.get_total_accounts()}")

# Static methods
print(f"Valid amount? {BankAccount.is_valid_amount(100)}")
future_value = BankAccount.calculate_compound_interest(1000, 0.05, 10)
print(f"Future value: ${future_value:.2f}")
```

## Decision Guide: Which Method Type to Use?

### Use **Instance Methods** when:
- ✅ You need to access or modify instance attributes
- ✅ The method represents an action the object performs
- ✅ Different instances need different behavior

**Examples**: `deposit()`, `withdraw()`, `get_age()`, `save_to_db()`

### Use **Class Methods** when:
- ✅ You need to access or modify class attributes
- ✅ You're creating alternative constructors
- ✅ The method affects all instances
- ✅ You need to use the class name in the method

**Examples**: `from_string()`, `set_tax_rate()`, `get_total_count()`

### Use **Static Methods** when:
- ✅ The function is related to the class but doesn't need class or instance data
- ✅ You're creating utility/helper functions
- ✅ The function could be standalone but belongs logically with the class

**Examples**: `validate_email()`, `calculate_tax()`, `is_leap_year()`

## Summary

- **Instance methods** use `self` and work with instance data
- **Class methods** use `@classmethod`, `cls` and work with class data
- **Static methods** use `@staticmethod`, no special first parameter
- Choose based on what data the method needs to access
- Instance methods are most common
- Class methods are great for alternative constructors
- Static methods are for utility functions

## Key Takeaways

✅ Instance methods: Most common, use `self`  
✅ Class methods: Use `@classmethod` and `cls`, alternative constructors  
✅ Static methods: Use `@staticmethod`, utility functions  
✅ `cls` refers to the class itself  
✅ Static methods don't access instance or class data  
✅ Use class methods for factory patterns  

## What's Next?

In the next section, we'll learn about:
- **Inheritance** - Creating class hierarchies
- **Method overriding** - Customizing inherited behavior
- **`super()`** - Accessing parent class methods
- **Multiple inheritance** and MRO

---

**Practice Time!** The labs will help you master these method types.

**கற்க கசடற** - Learn Flawlessly
