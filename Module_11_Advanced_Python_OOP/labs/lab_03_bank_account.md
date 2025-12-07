# Lab 3: Banking System with Inheritance

**கற்க கசடற - Learn Flawlessly**

**Estimated Time:** 50-70 minutes  
**Difficulty:** Intermediate-Advanced  
**Topics:** Inheritance, Encapsulation, Method Overriding

## Objectives

- ✅ Implement secure banking system with encapsulation
- ✅ Create account hierarchy (Savings, Checking, Investment)
- ✅ Override methods for account-specific behavior
- ✅ Track transactions and generate statements

## Requirements

### Part 1: Base BankAccount Class

Attributes:
- Private: `__account_number`, `__balance`, `__pin`, `__transactions`
- Public: `account_holder`, `account_type`
- Class: `account_counter` for ID generation

Methods:
- `deposit(amount, pin)`, `withdraw(amount, pin)`, `get_balance(pin)`
- `transfer(other_account, amount, pin)`, `get_statement(pin)`
- `change_pin(old_pin, new_pin)`

### Part 2: Specialized Accounts

**SavingsAccount**:
- `interest_rate` attribute
- Override `deposit()` to add interest
- `apply_monthly_interest(pin)` method
- Minimum balance requirement

**CheckingAccount**:
- `overdraft_limit` attribute
- Override `withdraw()` to allow overdraft
- `monthly_fee` attribute

**InvestmentAccount**:
- `portfolio` dictionary (stock: shares)
- `buy_stock(symbol, shares, price, pin)` method
- `sell_stock(symbol, shares, price, pin)` method
- `get_portfolio_value()` method

## Starter Code

```python
from datetime import datetime

class BankAccount:
    account_counter = 10000
    
    def __init__(self, account_holder, initial_deposit, pin):
        # TODO: Implement with private attributes
        pass
    
    def deposit(self, amount, pin):
        # TODO: Validate pin and add to balance
        pass
    
    def withdraw(self, amount, pin):
        # TODO: Validate pin and sufficient funds
        pass

class SavingsAccount(BankAccount):
    def __init__(self, account_holder, initial_deposit, pin, interest_rate=0.02):
        # TODO: Implement
        pass
    
    def apply_monthly_interest(self, pin):
        # TODO: Apply interest to balance
        pass

class CheckingAccount(BankAccount):
    def __init__(self, account_holder, initial_deposit, pin, overdraft_limit=500):
        # TODO: Implement
        pass

class InvestmentAccount(BankAccount):
    def __init__(self, account_holder, initial_deposit, pin):
        # TODO: Implement with portfolio
        pass
```

---

**Estimated completion time: 50-70 minutes**  
**Difficulty: ⭐⭐⭐⭐ (Intermediate-Advanced)**
