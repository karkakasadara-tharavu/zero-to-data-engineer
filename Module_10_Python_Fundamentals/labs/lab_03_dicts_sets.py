"""
Module 10 - Lab 03: Dictionaries and Sets
=========================================
Practice working with dictionaries and sets.

கற்க கசடற - Learn Flawlessly

Estimated Time: 60 minutes
Concepts: Dictionaries, sets, keys, values, set operations
"""

# Part 1: Dictionary Basics (10 minutes)
# ---------------------------------------
# TODO: Create a dictionary called 'student' with keys: name, age, grade, major


# TODO: Print the student's name


# TODO: Print the student's age using get() method


# TODO: Add a new key 'gpa' with value 3.8


# TODO: Update the grade to 'A+'


# TODO: Print all keys


# TODO: Print all values


# Part 2: Dictionary Methods (15 minutes)
# ---------------------------------------
# TODO: Create a dictionary of products with prices
# Example: {'apple': 1.50, 'banana': 0.75, 'orange': 1.25}


# TODO: Get the price of 'apple' with default value 0.0 if not found


# TODO: Check if 'grape' is in the dictionary


# TODO: Get all items as (key, value) pairs


# TODO: Update the dictionary with new products: {'grape': 2.00, 'melon': 3.50}


# TODO: Remove 'banana' using pop() and store the price


# TODO: Get the number of products


# Part 3: Dictionary Comprehensions (15 minutes)
# ----------------------------------------------
# TODO: Create a dictionary of numbers 1-5 and their squares
# Example: {1: 1, 2: 4, 3: 9, 4: 16, 5: 25}
squares_dict = None  # Replace None


# TODO: Create a dictionary from two lists using zip
names = ['Alice', 'Bob', 'Charlie']
scores = [95, 87, 92]
name_scores = None  # Replace None


# TODO: Filter dictionary to include only items with value > 90
high_scores = None  # Replace None


# TODO: Convert string list to uppercase dictionary
# Input: ['apple', 'banana', 'cherry']
# Output: {'APPLE': 5, 'BANANA': 6, 'CHERRY': 6} (key: uppercase, value: length)
fruits = ['apple', 'banana', 'cherry']
fruit_dict = None  # Replace None


# Part 4: Set Basics (10 minutes)
# -------------------------------
# TODO: Create a set called 'colors' with 5 colors


# TODO: Add a new color to the set


# TODO: Try to add the same color again (notice it won't be duplicated)


# TODO: Remove a color using discard()


# TODO: Check if 'blue' is in the set


# TODO: Print the number of unique colors


# Part 5: Set Operations (15 minutes)
# -----------------------------------
# TODO: Create two sets of numbers
set_a = None  # Numbers 1-10
set_b = None  # Numbers 5-15


# TODO: Find the union (all unique numbers from both sets)
union_set = None


# TODO: Find the intersection (numbers in both sets)
intersection_set = None


# TODO: Find the difference (numbers in set_a but not in set_b)
difference_set = None


# TODO: Find the symmetric difference (numbers in either set, but not both)
symmetric_diff = None


# TODO: Check if {1, 2} is a subset of set_a


# TODO: Check if set_a is a superset of {1, 2}


# Part 6: Practical Dictionary - Student Records (15 minutes)
# -----------------------------------------------------------
"""
Create a student records system using dictionaries.

Requirements:
1. Store students in a dictionary (student_id: student_info)
2. Each student_info is a dictionary with: name, age, grade, courses
3. Implement functions to:
   - Add student
   - Update student grade
   - Add course to student
   - Display student info
   - Calculate average grade for all students
"""

# TODO: Create an empty dictionary to store students
students_db = {}


# TODO: Create function to add a student
def add_student(student_id, name, age, grade):
    """
    Add a student to the database.
    
    Args:
        student_id: Unique student ID (str)
        name: Student name (str)
        age: Student age (int)
        grade: Student grade (str)
    
    Returns:
        None
    """
    pass  # Replace with your code


# TODO: Create function to update student grade
def update_grade(student_id, new_grade):
    """
    Update a student's grade.
    
    Args:
        student_id: Student ID (str)
        new_grade: New grade (str)
    
    Returns:
        bool: True if updated, False if student not found
    """
    pass  # Replace with your code


# TODO: Create function to add a course to student
def add_course(student_id, course):
    """
    Add a course to student's course list.
    
    Args:
        student_id: Student ID (str)
        course: Course name (str)
    
    Returns:
        bool: True if added, False if student not found
    """
    pass  # Replace with your code


# TODO: Create function to display student info
def display_student(student_id):
    """
    Display student information.
    
    Args:
        student_id: Student ID (str)
    
    Returns:
        None
    """
    pass  # Replace with your code


# TODO: Create function to get all students with a specific grade
def get_students_by_grade(grade):
    """
    Get all students with a specific grade.
    
    Args:
        grade: Grade to filter by (str)
    
    Returns:
        list: List of student IDs with that grade
    """
    pass  # Replace with your code


# TODO: Test your student records system
# Uncomment to test:
# add_student("S001", "Alice", 20, "A")
# add_student("S002", "Bob", 21, "B")
# add_student("S003", "Charlie", 19, "A")
# add_course("S001", "Math")
# add_course("S001", "Physics")
# add_course("S002", "Chemistry")
# display_student("S001")
# update_grade("S002", "A")
# print("Students with grade A:", get_students_by_grade("A"))


# Part 7: Practical Sets - Data Deduplication (10 minutes)
# --------------------------------------------------------
"""
Use sets to deduplicate and analyze data.

Requirements:
1. Remove duplicates from a list
2. Find common elements between datasets
3. Find unique elements in each dataset
"""

# TODO: Remove duplicates from a list using set
emails = ['alice@email.com', 'bob@email.com', 'alice@email.com', 
          'charlie@email.com', 'bob@email.com']
unique_emails = None  # Replace None


# TODO: Find common customers between two stores
store_a_customers = {'Alice', 'Bob', 'Charlie', 'David'}
store_b_customers = {'Bob', 'David', 'Eve', 'Frank'}
common_customers = None  # Replace None


# TODO: Find customers who shop only at store A
only_store_a = None  # Replace None


# TODO: Find customers who shop only at store B
only_store_b = None  # Replace None


# TODO: Find all unique customers across both stores
all_customers = None  # Replace None


# ============================================================================
# DO NOT MODIFY BELOW THIS LINE - Verification Code
# ============================================================================

def verify_lab_03():
    """
    Verify that all lab exercises are completed correctly.
    
    Returns:
        None
    """
    print("\n" + "="*50)
    print("Lab 03 Verification")
    print("="*50)
    
    try:
        # Verify Part 1
        assert 'student' in dir(), "❌ Part 1: 'student' dict not created"
        assert isinstance(student, dict), "❌ Part 1: 'student' should be a dict"
        assert 'name' in student, "❌ Part 1: 'name' key missing"
        print("✅ Part 1: Dictionary basics - PASSED")
    except (AssertionError, NameError) as e:
        print(f"❌ Part 1: {e}")
    
    try:
        # Verify Part 2
        assert 'products' in dir(), "❌ Part 2: 'products' dict not created"
        assert isinstance(products, dict), "❌ Part 2: 'products' should be a dict"
        print("✅ Part 2: Dictionary methods - PASSED")
    except (AssertionError, NameError) as e:
        print(f"❌ Part 2: {e}")
    
    try:
        # Verify Part 3
        assert squares_dict is not None, "❌ Part 3: 'squares_dict' not created"
        assert name_scores is not None, "❌ Part 3: 'name_scores' not created"
        print("✅ Part 3: Dictionary comprehensions - PASSED")
    except (AssertionError, NameError) as e:
        print(f"❌ Part 3: {e}")
    
    try:
        # Verify Part 4
        assert 'colors' in dir(), "❌ Part 4: 'colors' set not created"
        assert isinstance(colors, set), "❌ Part 4: 'colors' should be a set"
        print("✅ Part 4: Set basics - PASSED")
    except (AssertionError, NameError) as e:
        print(f"❌ Part 4: {e}")
    
    try:
        # Verify Part 5
        assert set_a is not None, "❌ Part 5: 'set_a' not created"
        assert set_b is not None, "❌ Part 5: 'set_b' not created"
        assert union_set is not None, "❌ Part 5: 'union_set' not created"
        assert intersection_set is not None, "❌ Part 5: 'intersection_set' not created"
        print("✅ Part 5: Set operations - PASSED")
    except (AssertionError, NameError) as e:
        print(f"❌ Part 5: {e}")
    
    try:
        # Verify Part 6
        assert 'students_db' in dir(), "❌ Part 6: 'students_db' not created"
        assert callable(add_student), "❌ Part 6: 'add_student' not created"
        assert callable(update_grade), "❌ Part 6: 'update_grade' not created"
        assert callable(add_course), "❌ Part 6: 'add_course' not created"
        assert callable(display_student), "❌ Part 6: 'display_student' not created"
        print("✅ Part 6: Student records - PASSED")
    except (AssertionError, NameError) as e:
        print(f"❌ Part 6: {e}")
    
    try:
        # Verify Part 7
        assert unique_emails is not None, "❌ Part 7: 'unique_emails' not created"
        assert common_customers is not None, "❌ Part 7: 'common_customers' not created"
        print("✅ Part 7: Data deduplication - PASSED")
    except (AssertionError, NameError) as e:
        print(f"❌ Part 7: {e}")
    
    print("="*50)
    print("Verification complete!")
    print("="*50)

# Uncomment the line below to run verification after completing the lab
# verify_lab_03()
