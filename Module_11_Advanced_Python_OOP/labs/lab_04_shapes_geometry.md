# Lab 04: Shapes & Geometry System

**Difficulty**: ⭐⭐⭐⭐ (Intermediate-Advanced)  
**Estimated Time**: 45-60 minutes  
**Topics**: Polymorphism, Abstract Base Classes, Method Overriding

---

## 🎯 Objectives

By completing this lab, you will:
- Implement abstract base classes to define interfaces
- Create a polymorphic shape hierarchy
- Override methods to provide specialized behavior
- Use `@abstractmethod` for enforcing implementation
- Calculate areas and perimeters using polymorphism
- Work with collections of polymorphic objects

---

## 📋 Requirements

### Part 1: Abstract Base Class

Create an abstract `Shape` class using the `ABC` module:

**Shape Class Requirements**:
- Must be abstract (inherit from `ABC`)
- Abstract method: `area()` - returns the area
- Abstract method: `perimeter()` - returns the perimeter
- Concrete method: `describe()` - returns a description string
- Instance attributes: `name`, `color`

### Part 2: Concrete Shape Classes

Implement these concrete shape classes inheriting from `Shape`:

**Circle Class**:
- Attribute: `radius`
- Implement `area()` using π × r²
- Implement `perimeter()` using 2 × π × r
- Override `describe()` to include radius

**Rectangle Class**:
- Attributes: `width`, `height`
- Implement `area()` using width × height
- Implement `perimeter()` using 2 × (width + height)
- Override `describe()` to include dimensions

**Triangle Class**:
- Attributes: `side1`, `side2`, `side3`
- Implement `area()` using Heron's formula
- Implement `perimeter()` using sum of sides
- Override `describe()` to include all sides
- Validate that sides can form a triangle

**Square Class** (inherits from Rectangle):
- Attribute: `side`
- Call Rectangle's `__init__` with width=height=side
- Override `describe()` to emphasize it's a square

### Part 3: ShapeCollection Manager

**ShapeCollection Class**:
- Manage a list of Shape objects
- Method: `add_shape(shape)` - add a shape to collection
- Method: `total_area()` - sum of all shape areas
- Method: `total_perimeter()` - sum of all perimeters
- Method: `get_shapes_by_color(color)` - filter by color
- Method: `get_largest_shape()` - shape with largest area
- Method: `display_all()` - print all shape descriptions

---

## 💻 Starter Code

```python
from abc import ABC, abstractmethod
import math

class Shape(ABC):
    """Abstract base class for all shapes"""
    
    def __init__(self, name, color):
        self.name = name
        self.color = color
    
    @abstractmethod
    def area(self):
        """Calculate and return the area of the shape"""
        pass
    
    @abstractmethod
    def perimeter(self):
        """Calculate and return the perimeter of the shape"""
        pass
    
    def describe(self):
        """Return a description of the shape"""
        return f"{self.color} {self.name}"

class Circle(Shape):
    """Circle shape"""
    
    def __init__(self, radius, color="red"):
        # TODO: Initialize Circle
        pass
    
    def area(self):
        # TODO: Implement area calculation
        pass
    
    def perimeter(self):
        # TODO: Implement perimeter calculation
        pass
    
    def describe(self):
        # TODO: Override to include radius
        pass

class Rectangle(Shape):
    """Rectangle shape"""
    
    def __init__(self, width, height, color="blue"):
        # TODO: Initialize Rectangle
        pass
    
    def area(self):
        # TODO: Implement area calculation
        pass
    
    def perimeter(self):
        # TODO: Implement perimeter calculation
        pass

class Triangle(Shape):
    """Triangle shape"""
    
    def __init__(self, side1, side2, side3, color="green"):
        # TODO: Initialize Triangle and validate sides
        pass
    
    def area(self):
        # TODO: Implement using Heron's formula
        # s = (a + b + c) / 2
        # area = sqrt(s * (s-a) * (s-b) * (s-c))
        pass
    
    def perimeter(self):
        # TODO: Implement perimeter calculation
        pass

class Square(Rectangle):
    """Square shape (special case of Rectangle)"""
    
    def __init__(self, side, color="yellow"):
        # TODO: Initialize Square using Rectangle
        pass
    
    def describe(self):
        # TODO: Override to emphasize it's a square
        pass

class ShapeCollection:
    """Manages a collection of shapes"""
    
    def __init__(self):
        self.shapes = []
    
    def add_shape(self, shape):
        # TODO: Add shape to collection
        pass
    
    def total_area(self):
        # TODO: Calculate total area
        pass
    
    def total_perimeter(self):
        # TODO: Calculate total perimeter
        pass
    
    def get_shapes_by_color(self, color):
        # TODO: Return list of shapes with given color
        pass
    
    def get_largest_shape(self):
        # TODO: Return shape with largest area
        pass
    
    def display_all(self):
        # TODO: Display all shapes with their properties
        pass

# Test your implementation
if __name__ == "__main__":
    # Create shape collection
    collection = ShapeCollection()
    
    # Add various shapes
    collection.add_shape(Circle(5, "red"))
    collection.add_shape(Rectangle(4, 6, "blue"))
    collection.add_shape(Triangle(3, 4, 5, "green"))
    collection.add_shape(Square(4, "yellow"))
    collection.add_shape(Circle(3, "red"))
    
    # Display all shapes
    collection.display_all()
    
    # Show statistics
    print(f"\nTotal Area: {collection.total_area():.2f}")
    print(f"Total Perimeter: {collection.total_perimeter():.2f}")
    
    # Filter by color
    red_shapes = collection.get_shapes_by_color("red")
    print(f"\nRed shapes: {len(red_shapes)}")
    
    # Find largest
    largest = collection.get_largest_shape()
    print(f"\nLargest shape: {largest.describe()}")
    print(f"Area: {largest.area():.2f}")
```

---

## 🎯 Expected Output

```
Shape Collection:
==================
1. red Circle (radius: 5.0) - Area: 78.54, Perimeter: 31.42
2. blue Rectangle (4.0 x 6.0) - Area: 24.00, Perimeter: 20.00
3. green Triangle (sides: 3.0, 4.0, 5.0) - Area: 6.00, Perimeter: 12.00
4. yellow Square (side: 4.0) - Area: 16.00, Perimeter: 16.00
5. red Circle (radius: 3.0) - Area: 28.27, Perimeter: 18.85

Total Area: 152.81
Total Perimeter: 98.27

Red shapes: 2

Largest shape: red Circle (radius: 5.0)
Area: 78.54
```

---

## ✅ Validation Checklist

Your implementation should:
- [ ] Shape class is abstract and cannot be instantiated
- [ ] All concrete shapes implement area() and perimeter()
- [ ] Circle calculations use math.pi correctly
- [ ] Triangle validates that sides can form a valid triangle
- [ ] Square properly inherits from Rectangle
- [ ] ShapeCollection can add and manage multiple shapes
- [ ] total_area() and total_perimeter() work correctly
- [ ] Filtering by color returns correct shapes
- [ ] get_largest_shape() identifies the shape with maximum area
- [ ] All area/perimeter values are accurate to 2 decimal places
- [ ] describe() methods provide useful information
- [ ] Code demonstrates polymorphism effectively

---

## 🚀 Extension Challenges

1. **More Shapes**: Add Pentagon, Hexagon, or Ellipse classes
2. **Shape Comparison**: Implement `__eq__` and `__lt__` for sorting shapes
3. **Scale Method**: Add a `scale(factor)` method to all shapes
4. **Validation**: Add more validation (negative dimensions, etc.)
5. **Area Ratio**: Method to calculate what percentage each shape is of total area
6. **Export**: Add method to export collection data to JSON
7. **Drawing**: Use turtle or matplotlib to visualize the shapes
8. **3D Shapes**: Extend to 3D with volume calculations

---

## 💡 Key Concepts Demonstrated

- **Abstract Base Classes**: Using ABC to define interfaces
- **Polymorphism**: Different shapes with same interface
- **Method Overriding**: Specialized implementations in subclasses
- **Inheritance Hierarchy**: Square extends Rectangle
- **Collections Management**: Working with polymorphic object lists
- **Mathematical Formulas**: Implementing real-world calculations

---

## 📚 Related Theory Sections

- `04_inheritance.md` - Inheritance hierarchies
- `05_polymorphism.md` - Polymorphic behavior
- `09_abstract_base_classes.md` - ABC module usage

---

**Good luck! 🎨🔺⭕**
