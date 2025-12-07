# Lab 03 Solution: Banking System with Inheritance

"""
Complete solution for the Banking System lab.
Demonstrates: Inheritance, Encapsulation, Private Attributes, Security

Author: Data Engineering Curriculum
Module: 11 - Advanced Python & OOP
"""

import hashlib
from datetime import datetime
from typing import List, Optional


class BankAccount:
    """Base class for all bank accounts with encapsulation and security"""
    
    # Class variables
    _account_counter = 10000
    total_accounts = 0
    
    def __init__(self, owner_name: str, pin: str, initial_balance: float = 0):
        """
        Initialize a bank account with security.
        
        Args:
            owner_name (str): Account owner's name
            pin (str): 4-digit PIN for account security
            initial_balance (float): Starting balance
        """
        # Private attributes (name mangling for security)
        self.__account_number = self._generate_account_number()
        self.__owner_name = owner_name
        self.__balance = initial_balance
        self.__pin_hash = self._hash_pin(pin)
        self.__transaction_history = []
        self.__is_locked = False
        self.__failed_attempts = 0
        self.created_date = datetime.now()
        
        BankAccount.total_accounts += 1
        self._log_transaction("Account created", initial_balance)
    
    @classmethod
    def _generate_account_number(cls) -> str:
        """
        Generate unique account number.
        
        Returns:
            str: Account number in format 'ACC10001'
        """
        cls._account_counter += 1
        return f"ACC{cls._account_counter}"
    
    @staticmethod
    def _hash_pin(pin: str) -> str:
        """
        Hash PIN for secure storage.
        
        Args:
            pin (str): Plain text PIN
            
        Returns:
            str: Hashed PIN
        """
        return hashlib.sha256(pin.encode()).hexdigest()
    
    def verify_pin(self, pin: str) -> bool:
        """
        Verify PIN against stored hash.
        
        Args:
            pin (str): PIN to verify
            
        Returns:
            bool: True if PIN matches
        """
        if self.__is_locked:
            print("❌ Account is locked due to multiple failed attempts")
            return False
        
        if self._hash_pin(pin) == self.__pin_hash:
            self.__failed_attempts = 0  # Reset on successful verification
            return True
        else:
            self.__failed_attempts += 1
            if self.__failed_attempts >= 3:
                self.__is_locked = True
                print("🔒 Account locked after 3 failed attempts")
            return False
    
    def change_pin(self, old_pin: str, new_pin: str) -> bool:
        """
        Change account PIN.
        
        Args:
            old_pin (str): Current PIN
            new_pin (str): New PIN
            
        Returns:
            bool: True if successful
        """
        if not self.verify_pin(old_pin):
            print("✗ Invalid current PIN")
            return False
        
        if len(new_pin) != 4 or not new_pin.isdigit():
            print("✗ New PIN must be 4 digits")
            return False
        
        self.__pin_hash = self._hash_pin(new_pin)
        self._log_transaction("PIN changed", 0)
        print("✓ PIN changed successfully")
        return True
    
    def deposit(self, amount: float, pin: str) -> bool:
        """
        Deposit money into account.
        
        Args:
            amount (float): Amount to deposit
            pin (str): PIN for verification
            
        Returns:
            bool: True if successful
        """
        if not self.verify_pin(pin):
            print("✗ Invalid PIN")
            return False
        
        if amount <= 0:
            print("✗ Deposit amount must be positive")
            return False
        
        self.__balance += amount
        self._log_transaction("Deposit", amount)
        print(f"✓ Deposited ${amount:.2f}. New balance: ${self.__balance:.2f}")
        return True
    
    def withdraw(self, amount: float, pin: str) -> bool:
        """
        Withdraw money from account.
        
        Args:
            amount (float): Amount to withdraw
            pin (str): PIN for verification
            
        Returns:
            bool: True if successful
        """
        if not self.verify_pin(pin):
            print("✗ Invalid PIN")
            return False
        
        if amount <= 0:
            print("✗ Withdrawal amount must be positive")
            return False
        
        if not self._can_withdraw(amount):
            print(f"✗ Insufficient funds. Available: ${self.get_balance(pin):.2f}")
            return False
        
        self.__balance -= amount
        self._log_transaction("Withdrawal", -amount)
        print(f"✓ Withdrew ${amount:.2f}. New balance: ${self.__balance:.2f}")
        return True
    
    def _can_withdraw(self, amount: float) -> bool:
        """
        Check if withdrawal is allowed (can be overridden).
        
        Args:
            amount (float): Amount to check
            
        Returns:
            bool: True if withdrawal allowed
        """
        return amount <= self.__balance
    
    def get_balance(self, pin: str) -> Optional[float]:
        """
        Get current balance (requires PIN).
        
        Args:
            pin (str): PIN for verification
            
        Returns:
            float or None: Balance if PIN valid
        """
        if not self.verify_pin(pin):
            print("✗ Invalid PIN")
            return None
        return self.__balance
    
    def get_account_info(self, pin: str) -> Optional[dict]:
        """
        Get account information (requires PIN).
        
        Args:
            pin (str): PIN for verification
            
        Returns:
            dict or None: Account info if PIN valid
        """
        if not self.verify_pin(pin):
            print("✗ Invalid PIN")
            return None
        
        return {
            'account_number': self.__account_number,
            'owner_name': self.__owner_name,
            'account_type': self.get_account_type(),
            'balance': self.__balance,
            'created_date': self.created_date.strftime("%Y-%m-%d"),
            'is_locked': self.__is_locked
        }
    
    def get_transaction_history(self, pin: str, limit: int = 10) -> Optional[List[dict]]:
        """
        Get recent transaction history (requires PIN).
        
        Args:
            pin (str): PIN for verification
            limit (int): Number of recent transactions to return
            
        Returns:
            list or None: Transaction history if PIN valid
        """
        if not self.verify_pin(pin):
            print("✗ Invalid PIN")
            return None
        return self.__transaction_history[-limit:]
    
    def _log_transaction(self, transaction_type: str, amount: float):
        """
        Log a transaction (private method).
        
        Args:
            transaction_type (str): Type of transaction
            amount (float): Transaction amount
        """
        transaction = {
            'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            'type': transaction_type,
            'amount': amount,
            'balance': self.__balance
        }
        self.__transaction_history.append(transaction)
    
    def get_account_type(self) -> str:
        """
        Get account type (to be overridden by subclasses).
        
        Returns:
            str: Account type name
        """
        return "Basic Account"
    
    def __str__(self):
        """String representation (no sensitive data)"""
        return f"{self.get_account_type()} - {self.__account_number} ({self.__owner_name})"
    
    def __repr__(self):
        """Official representation"""
        return f"BankAccount(account='{self.__account_number}')"


class SavingsAccount(BankAccount):
    """Savings account with interest and minimum balance"""
    
    def __init__(self, owner_name: str, pin: str, initial_balance: float = 0,
                 interest_rate: float = 0.02, min_balance: float = 100):
        """
        Initialize savings account.
        
        Args:
            owner_name (str): Account owner
            pin (str): 4-digit PIN
            initial_balance (float): Starting balance
            interest_rate (float): Annual interest rate (e.g., 0.02 = 2%)
            min_balance (float): Minimum balance requirement
        """
        super().__init__(owner_name, pin, initial_balance)
        self.interest_rate = interest_rate
        self.min_balance = min_balance
    
    def _can_withdraw(self, amount: float) -> bool:
        """
        Override to enforce minimum balance.
        
        Args:
            amount (float): Amount to withdraw
            
        Returns:
            bool: True if withdrawal allowed
        """
        # Get current balance (use parent's private attribute through getter)
        current_balance = super().get_balance(None) if hasattr(self, '_BankAccount__balance') else 0
        
        # Allow withdrawal only if balance stays above minimum
        return (current_balance - amount) >= self.min_balance
    
    def calculate_interest(self, pin: str) -> Optional[float]:
        """
        Calculate interest for current balance.
        
        Args:
            pin (str): PIN for verification
            
        Returns:
            float or None: Interest amount
        """
        balance = self.get_balance(pin)
        if balance is None:
            return None
        
        interest = balance * self.interest_rate
        return interest
    
    def apply_interest(self, pin: str) -> bool:
        """
        Apply interest to account.
        
        Args:
            pin (str): PIN for verification
            
        Returns:
            bool: True if successful
        """
        interest = self.calculate_interest(pin)
        if interest is None:
            return False
        
        if self.deposit(interest, pin):
            print(f"✓ Interest applied: ${interest:.2f}")
            return True
        return False
    
    def get_account_type(self) -> str:
        """Return account type"""
        return "Savings Account"


class CheckingAccount(BankAccount):
    """Checking account with overdraft protection"""
    
    def __init__(self, owner_name: str, pin: str, initial_balance: float = 0,
                 overdraft_limit: float = 500, monthly_fee: float = 5):
        """
        Initialize checking account.
        
        Args:
            owner_name (str): Account owner
            pin (str): 4-digit PIN
            initial_balance (float): Starting balance
            overdraft_limit (float): Maximum overdraft allowed
            monthly_fee (float): Monthly maintenance fee
        """
        super().__init__(owner_name, pin, initial_balance)
        self.overdraft_limit = overdraft_limit
        self.monthly_fee = monthly_fee
        self.checks_written = 0
    
    def _can_withdraw(self, amount: float) -> bool:
        """
        Override to allow overdraft up to limit.
        
        Args:
            amount (float): Amount to withdraw
            
        Returns:
            bool: True if withdrawal allowed
        """
        balance = super().get_balance(None) if hasattr(self, '_BankAccount__balance') else 0
        return (balance - amount) >= -self.overdraft_limit
    
    def write_check(self, amount: float, payee: str, pin: str) -> bool:
        """
        Write a check (special withdrawal).
        
        Args:
            amount (float): Check amount
            payee (str): Check recipient
            pin (str): PIN for verification
            
        Returns:
            bool: True if successful
        """
        if self.withdraw(amount, pin):
            self.checks_written += 1
            print(f"✓ Check #{self.checks_written} written to {payee} for ${amount:.2f}")
            return True
        return False
    
    def charge_monthly_fee(self, pin: str) -> bool:
        """
        Charge monthly maintenance fee.
        
        Args:
            pin (str): PIN for verification
            
        Returns:
            bool: True if successful
        """
        if self.withdraw(self.monthly_fee, pin):
            print(f"✓ Monthly fee charged: ${self.monthly_fee:.2f}")
            return True
        return False
    
    def get_account_type(self) -> str:
        """Return account type"""
        return "Checking Account"


class InvestmentAccount(BankAccount):
    """Investment account with portfolio management"""
    
    def __init__(self, owner_name: str, pin: str, initial_balance: float = 0,
                 risk_level: str = "moderate"):
        """
        Initialize investment account.
        
        Args:
            owner_name (str): Account owner
            pin (str): 4-digit PIN
            initial_balance (float): Starting balance
            risk_level (str): Risk level (conservative/moderate/aggressive)
        """
        super().__init__(owner_name, pin, initial_balance)
        self.risk_level = risk_level
        self.portfolio = {}  # Dictionary: stock_symbol -> quantity
    
    def buy_stock(self, symbol: str, quantity: int, price_per_share: float, pin: str) -> bool:
        """
        Buy stocks.
        
        Args:
            symbol (str): Stock symbol (e.g., 'AAPL')
            quantity (int): Number of shares
            price_per_share (float): Price per share
            pin (str): PIN for verification
            
        Returns:
            bool: True if successful
        """
        total_cost = quantity * price_per_share
        
        if self.withdraw(total_cost, pin):
            if symbol in self.portfolio:
                self.portfolio[symbol] += quantity
            else:
                self.portfolio[symbol] = quantity
            print(f"✓ Bought {quantity} shares of {symbol} @ ${price_per_share:.2f}")
            return True
        return False
    
    def sell_stock(self, symbol: str, quantity: int, price_per_share: float, pin: str) -> bool:
        """
        Sell stocks.
        
        Args:
            symbol (str): Stock symbol
            quantity (int): Number of shares
            price_per_share (float): Price per share
            pin (str): PIN for verification
            
        Returns:
            bool: True if successful
        """
        if symbol not in self.portfolio:
            print(f"✗ You don't own {symbol}")
            return False
        
        if self.portfolio[symbol] < quantity:
            print(f"✗ Insufficient shares. You own {self.portfolio[symbol]} shares")
            return False
        
        total_proceeds = quantity * price_per_share
        
        if self.deposit(total_proceeds, pin):
            self.portfolio[symbol] -= quantity
            if self.portfolio[symbol] == 0:
                del self.portfolio[symbol]
            print(f"✓ Sold {quantity} shares of {symbol} @ ${price_per_share:.2f}")
            return True
        return False
    
    def get_portfolio_summary(self, pin: str) -> Optional[dict]:
        """
        Get portfolio summary.
        
        Args:
            pin (str): PIN for verification
            
        Returns:
            dict or None: Portfolio information
        """
        if not self.verify_pin(pin):
            print("✗ Invalid PIN")
            return None
        
        return {
            'risk_level': self.risk_level,
            'holdings': self.portfolio.copy(),
            'total_shares': sum(self.portfolio.values()),
            'cash_balance': self.get_balance(pin)
        }
    
    def get_account_type(self) -> str:
        """Return account type"""
        return "Investment Account"


# ==================== TESTING ====================

def main():
    """Test the complete banking system"""
    
    print("="*80)
    print("BANKING SYSTEM - COMPLETE SOLUTION")
    print("="*80)
    
    # Create different account types
    print("\n=== Creating Accounts ===\n")
    
    savings = SavingsAccount("Alice Johnson", "1234", 1000, interest_rate=0.03, min_balance=100)
    print(f"✓ Created: {savings}")
    
    checking = CheckingAccount("Bob Smith", "5678", 500, overdraft_limit=500, monthly_fee=10)
    print(f"✓ Created: {checking}")
    
    investment = InvestmentAccount("Charlie Davis", "9012", 5000, risk_level="aggressive")
    print(f"✓ Created: {investment}")
    
    # Test basic operations
    print(f"\n{'='*80}")
    print("=== Testing Basic Operations ===")
    print("="*80)
    
    print("\nDeposit to savings:")
    savings.deposit(500, "1234")
    
    print("\nWithdraw from savings:")
    savings.withdraw(200, "1234")
    
    print("\nCheck balance:")
    balance = savings.get_balance("1234")
    print(f"Savings balance: ${balance:.2f}")
    
    # Test minimum balance enforcement
    print(f"\n{'='*80}")
    print("=== Testing Minimum Balance (Savings) ===")
    print("="*80)
    print(f"\nAttempt to withdraw below minimum balance:")
    savings.withdraw(1500, "1234")  # Should fail
    
    # Test interest calculation
    print(f"\n{'='*80}")
    print("=== Testing Interest (Savings) ===")
    print("="*80)
    interest = savings.calculate_interest("1234")
    print(f"\nCalculated interest: ${interest:.2f}")
    savings.apply_interest("1234")
    
    # Test overdraft
    print(f"\n{'='*80}")
    print("=== Testing Overdraft (Checking) ===")
    print("="*80)
    print(f"\nAttempt overdraft withdrawal:")
    checking.withdraw(800, "5678")  # Should succeed with overdraft
    
    # Test check writing
    print(f"\n{'='*80}")
    print("=== Testing Check Writing ===")
    print("="*80)
    checking.write_check(50, "Electric Company", "5678")
    checking.write_check(30, "Water Company", "5678")
    
    # Test investment operations
    print(f"\n{'='*80}")
    print("=== Testing Stock Trading (Investment) ===")
    print("="*80)
    investment.buy_stock("AAPL", 10, 150.00, "9012")
    investment.buy_stock("GOOGL", 5, 120.00, "9012")
    investment.sell_stock("AAPL", 3, 155.00, "9012")
    
    portfolio = investment.get_portfolio_summary("9012")
    print(f"\nPortfolio Summary:")
    print(f"  Risk Level: {portfolio['risk_level']}")
    print(f"  Holdings: {portfolio['holdings']}")
    print(f"  Cash Balance: ${portfolio['cash_balance']:.2f}")
    
    # Test PIN security
    print(f"\n{'='*80}")
    print("=== Testing PIN Security ===")
    print("="*80)
    print("\nAttempting wrong PIN:")
    savings.withdraw(10, "0000")  # Wrong PIN
    savings.withdraw(10, "1111")  # Wrong PIN
    savings.withdraw(10, "2222")  # Wrong PIN - should lock account
    
    # Test transaction history
    print(f"\n{'='*80}")
    print("=== Transaction History ===")
    print("="*80)
    
    print("\nChecking account history:")
    history = checking.get_transaction_history("5678", limit=5)
    if history:
        for trans in history:
            print(f"  [{trans['timestamp']}] {trans['type']}: ${trans['amount']:.2f} (Balance: ${trans['balance']:.2f})")
    
    # Display account info
    print(f"\n{'='*80}")
    print("=== Account Information ===")
    print("="*80)
    
    for account, pin in [(savings, "1234"), (checking, "5678"), (investment, "9012")]:
        print(f"\n{account}:")
        info = account.get_account_info(pin)
        if info:
            for key, value in info.items():
                print(f"  {key}: {value}")
    
    # System statistics
    print(f"\n{'='*80}")
    print("=== System Statistics ===")
    print("="*80)
    print(f"Total Accounts Created: {BankAccount.total_accounts}")
    print("="*80)


if __name__ == "__main__":
    main()
