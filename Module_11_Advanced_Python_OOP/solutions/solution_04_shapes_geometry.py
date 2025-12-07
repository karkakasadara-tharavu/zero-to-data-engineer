# Lab 04 Solution: Shapes & Geometry System

"""Complete solution for Shapes & Geometry System lab.
Demonstrates: ABC, Polymorphism, Geometric Calculations"""

from abc import ABC, abstractmethod
import math


class Shape(ABC):
    """Abstract base class for all shapes"""
    
    def __init__(self, name, color):
        self.name = name
        self.color = color
    
    @property
    @abstractmethod
    def vehicle_type(self):
        pass
    
    @abstractmethod
    def area(self):
        pass
    
    @abstractmethod
    def perimeter(self):
        pass
    
    def describe(self):
        return f"{self.color} {self.name}"


class Circle(Shape):
    def __init__(self, radius, color="red"):
        super().__init__("Circle", color)
        self.radius = radius
    
    @property
    def vehicle_type(self):
        return "Circle"
    
    def area(self):
        return math.pi * self.radius ** 2
    
    def perimeter(self):
        return 2 * math.pi * self.radius
    
    def describe(self):
        return f"{super().describe()} (radius: {self.radius})"


class Rectangle(Shape):
    def __init__(self, width, height, color="blue"):
        super().__init__("Rectangle", color)
        self.width = width
        self.height = height
    
    @property
    def vehicle_type(self):
        return "Rectangle"
    
    def area(self):
        return self.width * self.height
    
    def perimeter(self):
        return 2 * (self.width + self.height)
    
    def describe(self):
        return f"{super().describe()} ({self.width} x {self.height})"


class Triangle(Shape):
    def __init__(self, side1, side2, side3, color="green"):
        if not self._valid_triangle(side1, side2, side3):
            raise ValueError("Invalid triangle sides")
        super().__init__("Triangle", color)
        self.side1 = side1
        self.side2 = side2
        self.side3 = side3
    
    @staticmethod
    def _valid_triangle(a, b, c):
        return a + b > c and b + c > a and a + c > b
    
    @property
    def vehicle_type(self):
        return "Triangle"
    
    def area(self):
        s = (self.side1 + self.side2 + self.side3) / 2
        return math.sqrt(s * (s - self.side1) * (s - self.side2) * (s - self.side3))
    
    def perimeter(self):
        return self.side1 + self.side2 + self.side3
    
    def describe(self):
        return f"{super().describe()} (sides: {self.side1}, {self.side2}, {self.side3})"


class Square(Rectangle):
    def __init__(self, side, color="yellow"):
        super().__init__(side, side, color)
        self.side = side
    
    def describe(self):
        return f"{self.color} Square (side: {self.side})"


class ShapeCollection:
    def __init__(self):
        self.shapes = []
    
    def add_shape(self, shape):
        self.shapes.append(shape)
    
    def total_area(self):
        return sum(shape.area() for shape in self.shapes)
    
    def total_perimeter(self):
        return sum(shape.perimeter() for shape in self.shapes)
    
    def get_shapes_by_color(self, color):
        return [s for s in self.shapes if s.color == color]
    
    def get_largest_shape(self):
        return max(self.shapes, key=lambda s: s.area())
    
    def display_all(self):
        print("\nShape Collection:")
        print("="*60)
        for i, shape in enumerate(self.shapes, 1):
            print(f"{i}. {shape.describe()} - Area: {shape.area():.2f}, Perimeter: {shape.perimeter():.2f}")


if __name__ == "__main__":
    collection = ShapeCollection()
    collection.add_shape(Circle(5, "red"))
    collection.add_shape(Rectangle(4, 6, "blue"))
    collection.add_shape(Triangle(3, 4, 5, "green"))
    collection.add_shape(Square(4, "yellow"))
    collection.add_shape(Circle(3, "red"))
    
    collection.display_all()
    print(f"\nTotal Area: {collection.total_area():.2f}")
    print(f"Total Perimeter: {collection.total_perimeter():.2f}")
    print(f"\nRed shapes: {len(collection.get_shapes_by_color('red'))}")
    largest = collection.get_largest_shape()
    print(f"\nLargest shape: {largest.describe()}")
    print(f"Area: {largest.area():.2f}")
