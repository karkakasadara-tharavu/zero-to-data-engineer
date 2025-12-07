# Lab 06: Advanced Calculator with Special Methods

**Difficulty**: ⭐⭐⭐⭐ (Intermediate-Advanced)  
**Estimated Time**: 45-55 minutes  
**Topics**: Special Methods, Operator Overloading, Magic Methods

---

## 🎯 Objectives

By completing this lab, you will:
- Implement special/magic methods (`__dunder__` methods)
- Overload arithmetic operators (+, -, *, /)
- Implement comparison operators (<, >, ==, etc.)
- Create string representations (`__str__`, `__repr__`)
- Make objects callable with `__call__`
- Support in-place operations (+=, -=, etc.)

---

## 📋 Requirements

### Part 1: Fraction Class

Create a `Fraction` class that represents mathematical fractions:

**Attributes**:
- `numerator` - top number
- `denominator` - bottom number (cannot be zero)

**Special Methods to Implement**:
- `__init__(numerator, denominator)` - initialize and simplify
- `__str__()` - return "3/4" format
- `__repr__()` - return "Fraction(3, 4)" format
- `__add__()` - add two fractions
- `__sub__()` - subtract fractions
- `__mul__()` - multiply fractions
- `__truediv__()` - divide fractions
- `__eq__()` - check equality
- `__lt__()` - less than comparison
- `__float__()` - convert to float
- `__int__()` - convert to integer

**Helper Methods**:
- `simplify()` - reduce fraction to lowest terms
- `_gcd(a, b)` - greatest common divisor (static method)

### Part 2: Vector Class

Create a `Vector` class for 2D mathematical vectors:

**Attributes**:
- `x` - x-coordinate
- `y` - y-coordinate

**Special Methods to Implement**:
- `__init__(x, y)` - initialize vector
- `__str__()` - return "<x, y>" format
- `__repr__()` - return "Vector(x, y)" format
- `__add__()` - add vectors
- `__sub__()` - subtract vectors
- `__mul__()` - scalar multiplication or dot product
- `__abs__()` - magnitude of vector
- `__eq__()` - check equality
- `__len__()` - return 2 (for unpacking support)
- `__getitem__()` - support indexing (v[0] = x, v[1] = y)
- `__neg__()` - negate vector

**Regular Methods**:
- `magnitude()` - length of vector
- `normalize()` - return unit vector
- `dot(other)` - dot product with another vector

### Part 3: CalculatorHistory Class

Create a `CalculatorHistory` class that tracks operations:

**Special Methods**:
- `__init__()` - initialize empty history
- `__len__()` - return number of operations
- `__getitem__(index)` - access operation by index
- `__contains__(operation)` - check if operation in history
- `__iter__()` - make history iterable
- `__call__(operation)` - add operation when called

**Methods**:
- `add_operation(operation)` - add to history
- `clear()` - clear all history
- `get_last_n(n)` - return last n operations

---

## 💻 Starter Code

```python
import math

class Fraction:
    """Represents a mathematical fraction with operator overloading"""
    
    def __init__(self, numerator, denominator):
        """Initialize fraction and simplify"""
        if denominator == 0:
            raise ValueError("Denominator cannot be zero")
        
        # TODO: Store numerator and denominator
        # TODO: Call simplify()
        pass
    
    @staticmethod
    def _gcd(a, b):
        """Calculate greatest common divisor"""
        # TODO: Implement Euclidean algorithm
        # Hint: Use recursion or while loop
        pass
    
    def simplify(self):
        """Reduce fraction to lowest terms"""
        # TODO: Find GCD of numerator and denominator
        # TODO: Divide both by GCD
        pass
    
    def __str__(self):
        """String representation for printing"""
        # TODO: Return "numerator/denominator"
        pass
    
    def __repr__(self):
        """Official string representation"""
        # TODO: Return "Fraction(numerator, denominator)"
        pass
    
    def __add__(self, other):
        """Add two fractions: a/b + c/d = (ad + bc) / bd"""
        # TODO: Implement addition
        pass
    
    def __sub__(self, other):
        """Subtract two fractions"""
        # TODO: Implement subtraction
        pass
    
    def __mul__(self, other):
        """Multiply two fractions: (a/b) * (c/d) = (ac) / (bd)"""
        # TODO: Implement multiplication
        pass
    
    def __truediv__(self, other):
        """Divide two fractions: (a/b) / (c/d) = (ad) / (bc)"""
        # TODO: Implement division
        pass
    
    def __eq__(self, other):
        """Check if two fractions are equal"""
        # TODO: Compare numerators and denominators
        pass
    
    def __lt__(self, other):
        """Check if this fraction is less than another"""
        # TODO: Compare using cross multiplication
        pass
    
    def __float__(self):
        """Convert fraction to float"""
        # TODO: Return numerator / denominator
        pass
    
    def __int__(self):
        """Convert fraction to integer (truncated)"""
        # TODO: Return integer part
        pass

class Vector:
    """Represents a 2D vector with operator overloading"""
    
    def __init__(self, x, y):
        """Initialize vector"""
        self.x = x
        self.y = y
    
    def __str__(self):
        """String representation"""
        # TODO: Return "<x, y>"
        pass
    
    def __repr__(self):
        """Official representation"""
        # TODO: Return "Vector(x, y)"
        pass
    
    def __add__(self, other):
        """Add two vectors"""
        # TODO: Return new Vector(x1+x2, y1+y2)
        pass
    
    def __sub__(self, other):
        """Subtract vectors"""
        # TODO: Return new Vector(x1-x2, y1-y2)
        pass
    
    def __mul__(self, scalar):
        """Multiply by scalar or calculate dot product"""
        if isinstance(scalar, (int, float)):
            # Scalar multiplication
            # TODO: Return new Vector(x*scalar, y*scalar)
            pass
        elif isinstance(scalar, Vector):
            # Dot product
            # TODO: Return x1*x2 + y1*y2
            pass
    
    def __abs__(self):
        """Return magnitude of vector"""
        # TODO: Return sqrt(x² + y²)
        pass
    
    def __eq__(self, other):
        """Check equality"""
        # TODO: Compare x and y components
        pass
    
    def __len__(self):
        """Return 2 (for unpacking support)"""
        return 2
    
    def __getitem__(self, index):
        """Support indexing: v[0] = x, v[1] = y"""
        # TODO: Return x if index=0, y if index=1
        pass
    
    def __neg__(self):
        """Negate vector"""
        # TODO: Return Vector(-x, -y)
        pass
    
    def magnitude(self):
        """Calculate magnitude"""
        return abs(self)
    
    def normalize(self):
        """Return unit vector"""
        # TODO: Divide by magnitude
        pass
    
    def dot(self, other):
        """Calculate dot product"""
        return self * other

class CalculatorHistory:
    """Tracks calculator operations with special methods"""
    
    def __init__(self):
        """Initialize empty history"""
        self.operations = []
    
    def __len__(self):
        """Return number of operations"""
        # TODO: Return length of operations list
        pass
    
    def __getitem__(self, index):
        """Access operation by index"""
        # TODO: Return operation at index
        pass
    
    def __contains__(self, operation):
        """Check if operation exists in history"""
        # TODO: Return True if operation in operations
        pass
    
    def __iter__(self):
        """Make history iterable"""
        # TODO: Return iterator of operations
        pass
    
    def __call__(self, operation):
        """Add operation when object is called"""
        # TODO: Add operation to history
        pass
    
    def add_operation(self, operation):
        """Add operation to history"""
        self.operations.append(operation)
    
    def clear(self):
        """Clear all history"""
        self.operations.clear()
    
    def get_last_n(self, n):
        """Return last n operations"""
        return self.operations[-n:]

# Test your implementation
if __name__ == "__main__":
    print("=== Testing Fraction Class ===")
    f1 = Fraction(3, 4)
    f2 = Fraction(2, 5)
    
    print(f"f1 = {f1}")
    print(f"f2 = {f2}")
    print(f"f1 + f2 = {f1 + f2}")
    print(f"f1 - f2 = {f1 - f2}")
    print(f"f1 * f2 = {f1 * f2}")
    print(f"f1 / f2 = {f1 / f2}")
    print(f"f1 as float: {float(f1)}")
    print(f"f1 < f2: {f1 < f2}")
    
    print("\n=== Testing Vector Class ===")
    v1 = Vector(3, 4)
    v2 = Vector(1, 2)
    
    print(f"v1 = {v1}")
    print(f"v2 = {v2}")
    print(f"v1 + v2 = {v1 + v2}")
    print(f"v1 - v2 = {v1 - v2}")
    print(f"v1 * 2 = {v1 * 2}")
    print(f"v1 · v2 = {v1 * v2}")
    print(f"|v1| = {abs(v1)}")
    print(f"-v1 = {-v1}")
    print(f"v1[0] = {v1[0]}, v1[1] = {v1[1]}")
    
    print("\n=== Testing CalculatorHistory ===")
    history = CalculatorHistory()
    
    # Add operations using __call__
    history("3 + 4 = 7")
    history("5 * 2 = 10")
    history("10 - 3 = 7")
    
    print(f"Operations in history: {len(history)}")
    print(f"First operation: {history[0]}")
    print(f"'5 * 2 = 10' in history: {'5 * 2 = 10' in history}")
    
    print("\nAll operations:")
    for op in history:
        print(f"  {op}")
```

---

## 🎯 Expected Output

```
=== Testing Fraction Class ===
f1 = 3/4
f2 = 2/5
f1 + f2 = 23/20
f1 - f2 = 7/20
f1 * f2 = 3/10
f1 / f2 = 15/8
f1 as float: 0.75
f1 < f2: False

=== Testing Vector Class ===
v1 = <3, 4>
v2 = <1, 2>
v1 + v2 = <4, 6>
v1 - v2 = <2, 2>
v1 * 2 = <6, 8>
v1 · v2 = 11
|v1| = 5.0
-v1 = <-3, -4>
v1[0] = 3, v1[1] = 4

=== Testing CalculatorHistory ===
Operations in history: 3
First operation: 3 + 4 = 7
'5 * 2 = 10' in history: True

All operations:
  3 + 4 = 7
  5 * 2 = 10
  10 - 3 = 7
```

---

## ✅ Validation Checklist

Your implementation should:
- [ ] Fraction class simplifies fractions automatically
- [ ] All arithmetic operations work correctly for Fraction
- [ ] Fraction prevents division by zero
- [ ] Vector addition and subtraction work correctly
- [ ] Vector scalar multiplication works
- [ ] Vector dot product calculates correctly
- [ ] Vector magnitude calculation is accurate
- [ ] `__str__` and `__repr__` provide useful representations
- [ ] Comparison operators work correctly
- [ ] CalculatorHistory supports len(), [], in, iter()
- [ ] CalculatorHistory is callable (can use parentheses)
- [ ] All special methods are properly implemented
- [ ] Type checking handles invalid operations gracefully

---

## 🚀 Extension Challenges

1. **More Operations**: Add +=, -=, *=, /= for in-place operations
2. **Power Operations**: Implement `__pow__` for exponentiation
3. **Complex Numbers**: Create ComplexNumber class with i notation
4. **Matrix Class**: Extend to 2D matrices with full operations
5. **Unit Conversion**: Add measurement classes (Length, Weight, etc.)
6. **Comparison Chain**: Implement all comparison operators (`__le__`, `__gt__`, `__ge__`)
7. **Context Manager**: Make classes work with `with` statement
8. **Immutability**: Make Fraction and Vector immutable with `__hash__`

---

## 💡 Key Concepts Demonstrated

- **Operator Overloading**: Making custom objects work with +, -, *, /
- **Special Methods**: Magic methods that Python calls automatically
- **String Representations**: `__str__` for users, `__repr__` for developers
- **Type Checking**: Handling different types in operations
- **Callable Objects**: Using `__call__` to make objects callable
- **Container Protocol**: Implementing `__len__`, `__getitem__`, `__contains__`

---

## 📚 Related Theory Sections

- `07_special_methods.md` - Comprehensive guide to magic methods
- `05_polymorphism.md` - Operator overloading examples

---

**Good luck! 🔢📐**
