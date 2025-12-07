# Lab 05 Solution: User Authentication System

"""Complete solution for User Authentication System lab.
Demonstrates: Encapsulation, Properties, Data Validation, Security"""

import hashlib
import re
from datetime import datetime, timedelta


class PasswordValidator:
    @staticmethod
    def is_valid(password):
        if len(password) < 8:
            return False
        has_upper = bool(re.search(r'[A-Z]', password))
        has_lower = bool(re.search(r'[a-z]', password))
        has_digit = bool(re.search(r'\d', password))
        has_special = bool(re.search(r'[@$!%*?&]', password))
        return all([has_upper, has_lower, has_digit, has_special])
    
    @staticmethod
    def get_strength(password):
        if not PasswordValidator.is_valid(password):
            return "weak"
        if len(password) >= 12:
            return "strong"
        if len(password) >= 10:
            return "medium"
        return "weak"


class User:
    def __init__(self, username, email, password):
        if not PasswordValidator.is_valid(password):
            raise ValueError("Password does not meet requirements")
        
        self.__username = username
        self.__email = None
        self.__password_hash = None
        self.__is_active = True
        self.__created_at = datetime.now()
        self.__last_login = None
        
        self.email = email  # Use setter
        self.set_password(password)
    
    @property
    def username(self):
        return self.__username
    
    @property
    def email(self):
        return self.__email
    
    @email.setter
    def email(self, value):
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(pattern, value):
            raise ValueError("Invalid email format")
        self.__email = value
    
    @property
    def is_active(self):
        return self.__is_active
    
    @is_active.setter
    def is_active(self, value):
        self.__is_active = bool(value)
    
    @property
    def account_age(self):
        return (datetime.now() - self.__created_at).days
    
    def set_password(self, password):
        if not PasswordValidator.is_valid(password):
            raise ValueError("Password does not meet requirements")
        self.__password_hash = hashlib.sha256(password.encode()).hexdigest()
    
    def check_password(self, password):
        return hashlib.sha256(password.encode()).hexdigest() == self.__password_hash
    
    def login(self):
        if not self.__is_active:
            raise Exception("Account is not active")
        self.__last_login = datetime.now()
    
    def activate(self):
        self.__is_active = True
    
    def deactivate(self):
        self.__is_active = False
    
    def get_info(self):
        return {
            'username': self.__username,
            'email': self.__email,
            'is_active': self.__is_active,
            'account_age_days': self.account_age,
            'last_login': self.__last_login.strftime("%Y-%m-%d %H:%M:%S") if self.__last_login else "Never"
        }


class UserManager:
    def __init__(self):
        self.__users = {}
        self.__failed_login_attempts = {}
    
    def register_user(self, username, email, password):
        if username in self.__users:
            return f"✗ Username '{username}' already exists"
        try:
            user = User(username, email, password)
            self.__users[username] = user
            return f"✓ User '{username}' registered successfully"
        except ValueError as e:
            return f"✗ Registration failed: {e}"
    
    def authenticate(self, username, password):
        if username not in self.__users:
            return f"✗ User '{username}' not found"
        
        user = self.__users[username]
        
        if not user.is_active:
            return f"✗ Account '{username}' is not active"
        
        if user.check_password(password):
            user.login()
            self.__failed_login_attempts[username] = 0
            return f"✓ User '{username}' logged in successfully"
        else:
            self.__failed_login_attempts[username] = self.__failed_login_attempts.get(username, 0) + 1
            return f"✗ Authentication failed for '{username}': Invalid password"
    
    def get_user(self, username):
        return self.__users.get(username)
    
    def delete_user(self, username):
        if username in self.__users:
            del self.__users[username]
            return f"✓ User '{username}' deleted"
        return f"✗ User '{username}' not found"
    
    def list_active_users(self):
        return [u for u, user in self.__users.items() if user.is_active]
    
    def get_user_count(self):
        return len(self.__users)
    
    def reset_password(self, username, old_password, new_password):
        user = self.get_user(username)
        if not user:
            return f"✗ User not found"
        
        if not user.check_password(old_password):
            return f"✗ Invalid current password"
        
        try:
            user.set_password(new_password)
            return f"✓ Password reset successful for '{username}'"
        except ValueError as e:
            return f"✗ Password reset failed: {e}"


if __name__ == "__main__":
    manager = UserManager()
    
    print("=== User Registration ===")
    print(manager.register_user("john_doe", "john@example.com", "SecurePass123!"))
    print(manager.register_user("jane_smith", "jane@example.com", "MyP@ssw0rd"))
    print(manager.register_user("bob_wilson", "bob@example.com", "Str0ng!Pass"))
    
    print("\n=== Authentication ===")
    print(manager.authenticate("john_doe", "SecurePass123!"))
    print(manager.authenticate("jane_smith", "WrongPassword"))
    
    print("\n=== User Information ===")
    user = manager.get_user("john_doe")
    print(user.get_info())
    
    print(f"\n=== Active Users ===")
    print(f"Active users: {manager.list_active_users()}")
    
    print("\n=== Password Reset ===")
    print(manager.reset_password("john_doe", "SecurePass123!", "NewP@ssw0rd456"))
