# Lab 06 Solution: Advanced Calculator

"""Complete solution for Advanced Calculator lab.
Demonstrates: Special Methods, Operator Overloading, Magic Methods"""

import math


class Fraction:
    def __init__(self, numerator, denominator):
        if denominator == 0:
            raise ValueError("Denominator cannot be zero")
        self.numerator = numerator
        self.denominator = denominator
        self.simplify()
    
    @staticmethod
    def _gcd(a, b):
        while b:
            a, b = b, a % b
        return abs(a)
    
    def simplify(self):
        if self.numerator == 0:
            self.denominator = 1
            return
        gcd = self._gcd(self.numerator, self.denominator)
        self.numerator //= gcd
        self.denominator //= gcd
        if self.denominator < 0:
            self.numerator = -self.numerator
            self.denominator = -self.denominator
    
    def __str__(self):
        return f"{self.numerator}/{self.denominator}"
    
    def __repr__(self):
        return f"Fraction({self.numerator}, {self.denominator})"
    
    def __add__(self, other):
        num = self.numerator * other.denominator + other.numerator * self.denominator
        den = self.denominator * other.denominator
        return Fraction(num, den)
    
    def __sub__(self, other):
        num = self.numerator * other.denominator - other.numerator * self.denominator
        den = self.denominator * other.denominator
        return Fraction(num, den)
    
    def __mul__(self, other):
        return Fraction(self.numerator * other.numerator, self.denominator * other.denominator)
    
    def __truediv__(self, other):
        return Fraction(self.numerator * other.denominator, self.denominator * other.numerator)
    
    def __eq__(self, other):
        return self.numerator == other.numerator and self.denominator == other.denominator
    
    def __lt__(self, other):
        return self.numerator * other.denominator < other.numerator * self.denominator
    
    def __float__(self):
        return self.numerator / self.denominator
    
    def __int__(self):
        return self.numerator // self.denominator


class Vector:
    def __init__(self, x, y):
        self.x = x
        self.y = y
    
    def __str__(self):
        return f"<{self.x}, {self.y}>"
    
    def __repr__(self):
        return f"Vector({self.x}, {self.y})"
    
    def __add__(self, other):
        return Vector(self.x + other.x, self.y + other.y)
    
    def __sub__(self, other):
        return Vector(self.x - other.x, self.y - other.y)
    
    def __mul__(self, scalar):
        if isinstance(scalar, (int, float)):
            return Vector(self.x * scalar, self.y * scalar)
        elif isinstance(scalar, Vector):
            return self.x * scalar.x + self.y * scalar.y
    
    def __abs__(self):
        return math.sqrt(self.x ** 2 + self.y ** 2)
    
    def __eq__(self, other):
        return self.x == other.x and self.y == other.y
    
    def __len__(self):
        return 2
    
    def __getitem__(self, index):
        if index == 0:
            return self.x
        elif index == 1:
            return self.y
        raise IndexError("Index out of range")
    
    def __neg__(self):
        return Vector(-self.x, -self.y)
    
    def magnitude(self):
        return abs(self)
    
    def normalize(self):
        mag = self.magnitude()
        if mag == 0:
            return Vector(0, 0)
        return Vector(self.x / mag, self.y / mag)
    
    def dot(self, other):
        return self * other


class CalculatorHistory:
    def __init__(self):
        self.operations = []
    
    def __len__(self):
        return len(self.operations)
    
    def __getitem__(self, index):
        return self.operations[index]
    
    def __contains__(self, operation):
        return operation in self.operations
    
    def __iter__(self):
        return iter(self.operations)
    
    def __call__(self, operation):
        self.operations.append(operation)
    
    def add_operation(self, operation):
        self.operations.append(operation)
    
    def clear(self):
        self.operations.clear()
    
    def get_last_n(self, n):
        return self.operations[-n:]


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
    history("3 + 4 = 7")
    history("5 * 2 = 10")
    history("10 - 3 = 7")
    print(f"Operations in history: {len(history)}")
    print(f"First operation: {history[0]}")
    print(f"'5 * 2 = 10' in history: {'5 * 2 = 10' in history}")
    print("\nAll operations:")
    for op in history:
        print(f"  {op}")
