# Lab 05: User Authentication System

**Difficulty**: ⭐⭐⭐⭐ (Intermediate-Advanced)  
**Estimated Time**: 50-60 minutes  
**Topics**: Encapsulation, Properties, Data Hiding, Validation

---

## 🎯 Objectives

By completing this lab, you will:
- Implement proper encapsulation with private attributes
- Use `@property` decorators for controlled access
- Implement password hashing for security
- Validate user input (email, password strength)
- Manage user sessions with timestamps
- Practice data hiding and access control

---

## 📋 Requirements

### Part 1: User Class

Create a `User` class with proper encapsulation:

**Private Attributes**:
- `__username` - unique username
- `__email` - validated email address
- `__password_hash` - hashed password (never store plain text)
- `__is_active` - account status
- `__created_at` - timestamp of creation
- `__last_login` - timestamp of last login

**Properties** (using `@property`):
- `username` - read-only, returns the username
- `email` - getter and setter with validation
- `is_active` - getter and setter
- `account_age` - read-only, returns days since creation

**Methods**:
- `__init__(username, email, password)` - initialize with validation
- `set_password(password)` - hash and store password
- `check_password(password)` - verify password against hash
- `activate()` - activate the account
- `deactivate()` - deactivate the account
- `login()` - update last_login timestamp
- `get_info()` - return public user information

### Part 2: Password Validator

Create a `PasswordValidator` class:

**Static Methods**:
- `is_valid(password)` - check if password meets requirements
- `get_strength(password)` - return strength (weak/medium/strong)

**Password Requirements**:
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one digit
- At least one special character (@$!%*?&)

### Part 3: UserManager System

Create a `UserManager` class to manage multiple users:

**Attributes**:
- `__users` - private dictionary of users (username -> User object)
- `__failed_login_attempts` - track failed login attempts

**Methods**:
- `register_user(username, email, password)` - create new user
- `authenticate(username, password)` - login user
- `get_user(username)` - retrieve user by username
- `delete_user(username)` - remove user
- `list_active_users()` - return list of active usernames
- `get_user_count()` - return total number of users
- `reset_password(username, old_password, new_password)` - change password

---

## 💻 Starter Code

```python
import hashlib
import re
from datetime import datetime

class PasswordValidator:
    """Validates password strength and requirements"""
    
    @staticmethod
    def is_valid(password):
        """Check if password meets minimum requirements"""
        # TODO: Implement validation
        # - At least 8 characters
        # - Contains uppercase, lowercase, digit, special char
        pass
    
    @staticmethod
    def get_strength(password):
        """Return password strength: weak, medium, or strong"""
        # TODO: Implement strength calculation
        # weak: minimum requirements only
        # medium: 10+ chars with variety
        # strong: 12+ chars with high variety
        pass

class User:
    """Represents a user with encapsulated data and authentication"""
    
    def __init__(self, username, email, password):
        """Initialize user with validation"""
        # TODO: Validate inputs
        # TODO: Initialize private attributes
        # TODO: Hash the password
        self.__username = username
        self.__email = None
        self.__password_hash = None
        self.__is_active = True
        self.__created_at = datetime.now()
        self.__last_login = None
        
        # Set email (triggers validation)
        self.email = email
        self.set_password(password)
    
    @property
    def username(self):
        """Read-only username property"""
        return self.__username
    
    @property
    def email(self):
        """Email getter"""
        return self.__email
    
    @email.setter
    def email(self, value):
        """Email setter with validation"""
        # TODO: Validate email format using regex
        # Pattern: name@domain.com
        pass
    
    @property
    def is_active(self):
        """Account status getter"""
        return self.__is_active
    
    @is_active.setter
    def is_active(self, value):
        """Account status setter"""
        # TODO: Set active status
        pass
    
    @property
    def account_age(self):
        """Calculate account age in days (read-only)"""
        # TODO: Return days since account creation
        pass
    
    def set_password(self, password):
        """Hash and store password"""
        # TODO: Validate password using PasswordValidator
        # TODO: Hash password using hashlib.sha256
        # TODO: Store hash in __password_hash
        pass
    
    def check_password(self, password):
        """Verify password against stored hash"""
        # TODO: Hash provided password and compare
        pass
    
    def activate(self):
        """Activate user account"""
        self.__is_active = True
    
    def deactivate(self):
        """Deactivate user account"""
        self.__is_active = False
    
    def login(self):
        """Update last login timestamp"""
        # TODO: Check if account is active
        # TODO: Update __last_login
        pass
    
    def get_info(self):
        """Return public user information"""
        # TODO: Return dictionary with public info
        # Don't expose password hash or other sensitive data
        pass

class UserManager:
    """Manages user registration and authentication"""
    
    def __init__(self):
        self.__users = {}
        self.__failed_login_attempts = {}
    
    def register_user(self, username, email, password):
        """Register a new user"""
        # TODO: Check if username already exists
        # TODO: Create new User object
        # TODO: Add to __users dictionary
        # TODO: Return success/failure message
        pass
    
    def authenticate(self, username, password):
        """Authenticate user and log them in"""
        # TODO: Check if user exists
        # TODO: Check if account is active
        # TODO: Verify password
        # TODO: Track failed attempts
        # TODO: Call user.login() on success
        pass
    
    def get_user(self, username):
        """Retrieve user by username"""
        # TODO: Return user or None
        pass
    
    def delete_user(self, username):
        """Remove user from system"""
        # TODO: Remove user from __users
        pass
    
    def list_active_users(self):
        """Return list of active usernames"""
        # TODO: Filter and return active users
        pass
    
    def get_user_count(self):
        """Return total number of registered users"""
        return len(self.__users)
    
    def reset_password(self, username, old_password, new_password):
        """Change user password"""
        # TODO: Verify old password
        # TODO: Set new password
        pass

# Test your implementation
if __name__ == "__main__":
    manager = UserManager()
    
    # Register users
    print("=== User Registration ===")
    manager.register_user("john_doe", "john@example.com", "SecurePass123!")
    manager.register_user("jane_smith", "jane@example.com", "MyP@ssw0rd")
    manager.register_user("bob_wilson", "bob@example.com", "Str0ng!Pass")
    
    # Test authentication
    print("\n=== Authentication ===")
    manager.authenticate("john_doe", "SecurePass123!")
    manager.authenticate("jane_smith", "WrongPassword")
    
    # User info
    print("\n=== User Information ===")
    user = manager.get_user("john_doe")
    print(user.get_info())
    
    # List active users
    print(f"\n=== Active Users ===")
    print(f"Active users: {manager.list_active_users()}")
    
    # Password reset
    print("\n=== Password Reset ===")
    manager.reset_password("john_doe", "SecurePass123!", "NewP@ssw0rd456")
```

---

## 🎯 Expected Output

```
=== User Registration ===
✓ User 'john_doe' registered successfully
✓ User 'jane_smith' registered successfully
✓ User 'bob_wilson' registered successfully

=== Authentication ===
✓ User 'john_doe' logged in successfully
✗ Authentication failed for 'jane_smith': Invalid password

=== User Information ===
{
    'username': 'john_doe',
    'email': 'john@example.com',
    'is_active': True,
    'account_age_days': 0,
    'last_login': '2024-01-15 10:30:45'
}

=== Active Users ===
Active users: ['john_doe', 'jane_smith', 'bob_wilson']

=== Password Reset ===
✓ Password reset successful for 'john_doe'
```

---

## ✅ Validation Checklist

Your implementation should:
- [ ] All sensitive attributes are private (double underscore)
- [ ] Username is read-only (only getter, no setter)
- [ ] Email validation works correctly
- [ ] Passwords are never stored in plain text
- [ ] Password hashing uses hashlib.sha256
- [ ] PasswordValidator checks all requirements
- [ ] Password strength calculation works correctly
- [ ] Cannot access private attributes directly from outside
- [ ] Properties provide controlled access to data
- [ ] account_age calculates days correctly
- [ ] Failed login attempts are tracked
- [ ] Inactive accounts cannot log in
- [ ] UserManager prevents duplicate usernames
- [ ] Password reset verifies old password first

---

## 🚀 Extension Challenges

1. **Account Lockout**: Lock account after 5 failed login attempts
2. **Password History**: Prevent reusing last 3 passwords
3. **Email Verification**: Add email verification token system
4. **Two-Factor Auth**: Add 2FA with token generation
5. **Session Management**: Track active sessions with timeout
6. **Password Expiry**: Force password change after 90 days
7. **User Roles**: Add role-based access control (admin, user, guest)
8. **Audit Log**: Track all user actions with timestamps

---

## 💡 Key Concepts Demonstrated

- **Encapsulation**: Private attributes with controlled access
- **Properties**: Using @property for getters and setters
- **Data Validation**: Email and password validation
- **Security**: Password hashing, never storing plain text
- **Name Mangling**: Using double underscore for privacy
- **Read-only Properties**: Preventing modification of sensitive data
- **Static Methods**: Utility functions that don't need instance

---

## 📚 Related Theory Sections

- `06_encapsulation.md` - Data hiding and access control
- `08_property_decorators.md` - Using @property decorator
- `03_methods.md` - Static methods and class methods

---

**Good luck! 🔒🔐**
