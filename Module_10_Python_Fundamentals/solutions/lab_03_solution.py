"""
Module 10 - Lab 03 Solution: Dictionaries and Sets
==================================================
Complete solutions with explanations.

கற்க கசடற - Learn Flawlessly

Estimated Time: 60 minutes
Concepts: Dictionaries, sets, keys, values, set operations
"""

# Part 1: Dictionary Basics (10 minutes)
# ---------------------------------------
print("Part 1: Dictionary Basics")
print("-" * 40)

# Create a dictionary called 'student' with keys: name, age, grade, major
student = {
    'name': 'Alice Johnson',
    'age': 20,
    'grade': 'A',
    'major': 'Computer Science'
}
print(f"Student dictionary: {student}")

# Print the student's name
print(f"Student name: {student['name']}")

# Print the student's age using get() method
# get() is safer - returns None instead of raising KeyError if key doesn't exist
age = student.get('age')
print(f"Student age: {age}")

# Add a new key 'gpa' with value 3.8
student['gpa'] = 3.8
print(f"After adding GPA: {student}")

# Update the grade to 'A+'
student['grade'] = 'A+'
print(f"After updating grade: {student}")

# Print all keys
print(f"Keys: {list(student.keys())}")

# Print all values
print(f"Values: {list(student.values())}")

print()

# Part 2: Dictionary Methods (15 minutes)
# ---------------------------------------
print("Part 2: Dictionary Methods")
print("-" * 40)

# Create a dictionary of products with prices
products = {
    'apple': 1.50,
    'banana': 0.75,
    'orange': 1.25,
    'pear': 1.75
}
print(f"Products: {products}")

# Get the price of 'apple' with default value 0.0 if not found
apple_price = products.get('apple', 0.0)
print(f"Apple price: ${apple_price}")

# Get price of non-existent item
grape_price = products.get('grape', 0.0)
print(f"Grape price (not found): ${grape_price}")

# Check if 'grape' is in the dictionary
has_grape = 'grape' in products
print(f"Has grape: {has_grape}")

# Get all items as (key, value) pairs
items = products.items()
print(f"Items: {list(items)}")

# Update the dictionary with new products
products.update({'grape': 2.00, 'melon': 3.50})
print(f"After update: {products}")

# Remove 'banana' using pop() and store the price
banana_price = products.pop('banana')
print(f"Removed banana (price: ${banana_price})")
print(f"After removal: {products}")

# Get the number of products
count = len(products)
print(f"Number of products: {count}")

print()

# Part 3: Dictionary Comprehensions (15 minutes)
# ----------------------------------------------
print("Part 3: Dictionary Comprehensions")
print("-" * 40)

# Create a dictionary of numbers 1-5 and their squares
squares_dict = {x: x**2 for x in range(1, 6)}
print(f"Squares dict: {squares_dict}")

# Explanation: Dict comprehension syntax
# {key_expression: value_expression for variable in iterable}

# Create a dictionary from two lists using zip
names = ['Alice', 'Bob', 'Charlie']
scores = [95, 87, 92]
name_scores = {name: score for name, score in zip(names, scores)}
print(f"Name scores: {name_scores}")

# Explanation: zip() pairs elements from two lists
# zip(['A', 'B'], [1, 2]) → [('A', 1), ('B', 2)]

# Filter dictionary to include only items with value > 90
high_scores = {name: score for name, score in name_scores.items() if score > 90}
print(f"High scores (>90): {high_scores}")

# Explanation: Add condition to filter items
# {k: v for k, v in dict.items() if condition}

# Convert string list to uppercase dictionary
fruits = ['apple', 'banana', 'cherry']
fruit_dict = {fruit.upper(): len(fruit) for fruit in fruits}
print(f"Fruit dict: {fruit_dict}")

# Explanation: Apply transformations to both key and value
# {item.upper(): len(item) for item in list}

print()

# Part 4: Set Basics (10 minutes)
# -------------------------------
print("Part 4: Set Basics")
print("-" * 40)

# Create a set called 'colors' with 5 colors
colors = {'red', 'blue', 'green', 'yellow', 'purple'}
print(f"Colors: {colors}")

# Add a new color to the set
colors.add('orange')
print(f"After adding orange: {colors}")

# Try to add the same color again (notice it won't be duplicated)
colors.add('orange')  # No duplicate!
print(f"After adding orange again (no duplicate): {colors}")

# Explanation: Sets automatically maintain uniqueness
# Adding an existing element has no effect

# Remove a color using discard()
colors.discard('yellow')
print(f"After discarding yellow: {colors}")

# Explanation: discard() vs remove()
# - discard(): Doesn't raise error if element doesn't exist
# - remove(): Raises KeyError if element doesn't exist

# Check if 'blue' is in the set
has_blue = 'blue' in colors
print(f"Has blue: {has_blue}")

# Print the number of unique colors
count = len(colors)
print(f"Number of unique colors: {count}")

print()

# Part 5: Set Operations (15 minutes)
# -----------------------------------
print("Part 5: Set Operations")
print("-" * 40)

# Create two sets of numbers
set_a = set(range(1, 11))  # Numbers 1-10
set_b = set(range(5, 16))  # Numbers 5-15
print(f"Set A: {set_a}")
print(f"Set B: {set_b}")

# Find the union (all unique numbers from both sets)
union_set = set_a | set_b  # or set_a.union(set_b)
print(f"Union (A ∪ B): {sorted(union_set)}")

# Explanation: Union combines all elements from both sets
# {1, 2, 3} ∪ {2, 3, 4} = {1, 2, 3, 4}

# Find the intersection (numbers in both sets)
intersection_set = set_a & set_b  # or set_a.intersection(set_b)
print(f"Intersection (A ∩ B): {sorted(intersection_set)}")

# Explanation: Intersection finds common elements
# {1, 2, 3} ∩ {2, 3, 4} = {2, 3}

# Find the difference (numbers in set_a but not in set_b)
difference_set = set_a - set_b  # or set_a.difference(set_b)
print(f"Difference (A - B): {sorted(difference_set)}")

# Explanation: Difference finds elements in first but not second
# {1, 2, 3} - {2, 3, 4} = {1}

# Find the symmetric difference (numbers in either set, but not both)
symmetric_diff = set_a ^ set_b  # or set_a.symmetric_difference(set_b)
print(f"Symmetric Difference (A △ B): {sorted(symmetric_diff)}")

# Explanation: Symmetric difference = (A - B) ∪ (B - A)
# Elements in either set but not in both
# {1, 2, 3} △ {2, 3, 4} = {1, 4}

# Check if {1, 2} is a subset of set_a
is_subset = {1, 2}.issubset(set_a)
print(f"{1, 2} is subset of A: {is_subset}")

# Check if set_a is a superset of {1, 2}
is_superset = set_a.issuperset({1, 2})
print(f"A is superset of {1, 2}: {is_superset}")

# Explanation: 
# - Subset: All elements of A are in B
# - Superset: All elements of A are in B (reverse of subset)

print()

# Part 6: Practical Dictionary - Student Records (15 minutes)
# -----------------------------------------------------------
print("Part 6: Student Records System")
print("-" * 40)

# Create an empty dictionary to store students
students_db = {}

def add_student(student_id, name, age, grade):
    """Add a student to the database."""
    students_db[student_id] = {
        'name': name,
        'age': age,
        'grade': grade,
        'courses': []  # Initialize empty course list
    }
    print(f"✅ Added student: {name} (ID: {student_id})")

def update_grade(student_id, new_grade):
    """Update a student's grade."""
    if student_id in students_db:
        old_grade = students_db[student_id]['grade']
        students_db[student_id]['grade'] = new_grade
        print(f"✅ Updated {student_id} grade: {old_grade} → {new_grade}")
        return True
    else:
        print(f"❌ Student {student_id} not found")
        return False

def add_course(student_id, course):
    """Add a course to student's course list."""
    if student_id in students_db:
        if course not in students_db[student_id]['courses']:
            students_db[student_id]['courses'].append(course)
            print(f"✅ Added course '{course}' to {student_id}")
            return True
        else:
            print(f"⚠️ {student_id} already enrolled in '{course}'")
            return False
    else:
        print(f"❌ Student {student_id} not found")
        return False

def display_student(student_id):
    """Display student information."""
    if student_id in students_db:
        student = students_db[student_id]
        print(f"\n📋 Student ID: {student_id}")
        print(f"   Name: {student['name']}")
        print(f"   Age: {student['age']}")
        print(f"   Grade: {student['grade']}")
        print(f"   Courses: {', '.join(student['courses']) if student['courses'] else 'None'}")
    else:
        print(f"❌ Student {student_id} not found")

def get_students_by_grade(grade):
    """Get all students with a specific grade."""
    students = [sid for sid, info in students_db.items() if info['grade'] == grade]
    return students

# Test the system
print("\n=== Testing Student Records System ===\n")

add_student("S001", "Alice Johnson", 20, "A")
add_student("S002", "Bob Smith", 21, "B")
add_student("S003", "Charlie Brown", 19, "A")
add_student("S004", "Diana Prince", 22, "B+")

print()
add_course("S001", "Math")
add_course("S001", "Physics")
add_course("S001", "Math")  # Duplicate
add_course("S002", "Chemistry")
add_course("S003", "Biology")

print()
display_student("S001")

print()
update_grade("S002", "A")

print(f"\n📊 Students with grade A: {get_students_by_grade('A')}")

print()

# Part 7: Practical Sets - Data Deduplication (10 minutes)
# --------------------------------------------------------
print("Part 7: Data Deduplication with Sets")
print("-" * 40)

# Remove duplicates from a list using set
emails = ['alice@email.com', 'bob@email.com', 'alice@email.com', 
          'charlie@email.com', 'bob@email.com']
print(f"Original emails: {emails}")
unique_emails = list(set(emails))
print(f"Unique emails: {unique_emails}")

# Explanation: Converting to set removes duplicates
# Convert back to list if needed: list(set(items))
# Note: Order is not preserved!

# Find common customers between two stores
store_a_customers = {'Alice', 'Bob', 'Charlie', 'David'}
store_b_customers = {'Bob', 'David', 'Eve', 'Frank'}

print(f"\nStore A customers: {store_a_customers}")
print(f"Store B customers: {store_b_customers}")

common_customers = store_a_customers & store_b_customers
print(f"Common customers: {common_customers}")

# Find customers who shop only at store A
only_store_a = store_a_customers - store_b_customers
print(f"Only store A: {only_store_a}")

# Find customers who shop only at store B
only_store_b = store_b_customers - store_a_customers
print(f"Only store B: {only_store_b}")

# Find all unique customers across both stores
all_customers = store_a_customers | store_b_customers
print(f"All customers: {all_customers}")

# Practical application
print(f"\n📊 Analysis:")
print(f"  Total unique customers: {len(all_customers)}")
print(f"  Customers at both stores: {len(common_customers)}")
print(f"  Store A exclusive: {len(only_store_a)}")
print(f"  Store B exclusive: {len(only_store_b)}")

# ============================================================================
# Verification Code
# ============================================================================

def verify_lab_03():
    """Verify that all lab exercises are completed correctly."""
    print("\n" + "="*60)
    print("Lab 03 Verification")
    print("="*60)
    
    passed = 0
    total = 7
    
    # Verify Part 1
    try:
        assert isinstance(student, dict), "student should be a dict"
        assert 'name' in student and 'age' in student, "missing required keys"
        assert 'gpa' in student and student['gpa'] == 3.8, "gpa not added correctly"
        assert student['grade'] == 'A+', "grade not updated correctly"
        print("✅ Part 1: Dictionary basics - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Part 1: {e}")
    
    # Verify Part 2
    try:
        assert isinstance(products, dict), "products should be a dict"
        assert 'grape' in products and 'melon' in products, "new products not added"
        assert 'banana' not in products, "banana should be removed"
        assert len(products) >= 5, "incorrect number of products"
        print("✅ Part 2: Dictionary methods - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Part 2: {e}")
    
    # Verify Part 3
    try:
        assert squares_dict == {1:1, 2:4, 3:9, 4:16, 5:25}, "squares_dict incorrect"
        assert name_scores == {'Alice': 95, 'Bob': 87, 'Charlie': 92}, "name_scores incorrect"
        assert high_scores == {'Alice': 95, 'Charlie': 92}, "high_scores incorrect"
        assert fruit_dict == {'APPLE': 5, 'BANANA': 6, 'CHERRY': 6}, "fruit_dict incorrect"
        print("✅ Part 3: Dictionary comprehensions - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Part 3: {e}")
    
    # Verify Part 4
    try:
        assert isinstance(colors, set), "colors should be a set"
        assert 'orange' in colors, "orange should be added"
        assert 'yellow' not in colors, "yellow should be removed"
        assert len(colors) == 5, "incorrect number of colors"
        print("✅ Part 4: Set basics - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Part 4: {e}")
    
    # Verify Part 5
    try:
        assert set_a == set(range(1, 11)), "set_a incorrect"
        assert set_b == set(range(5, 16)), "set_b incorrect"
        assert union_set == set(range(1, 16)), "union incorrect"
        assert intersection_set == set(range(5, 11)), "intersection incorrect"
        assert difference_set == set(range(1, 5)), "difference incorrect"
        assert symmetric_diff == set(range(1, 5)) | set(range(11, 16)), "symmetric diff incorrect"
        print("✅ Part 5: Set operations - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Part 5: {e}")
    
    # Verify Part 6
    try:
        assert isinstance(students_db, dict), "students_db should be a dict"
        assert len(students_db) >= 3, "should have at least 3 students"
        assert 'S001' in students_db, "S001 not added"
        assert students_db['S002']['grade'] == 'A', "grade not updated"
        assert 'Math' in students_db['S001']['courses'], "course not added"
        students_with_a = get_students_by_grade('A')
        assert len(students_with_a) >= 2, "should find students with grade A"
        print("✅ Part 6: Student records - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Part 6: {e}")
    
    # Verify Part 7
    try:
        assert len(unique_emails) == 3, "should have 3 unique emails"
        assert common_customers == {'Bob', 'David'}, "common_customers incorrect"
        assert only_store_a == {'Alice', 'Charlie'}, "only_store_a incorrect"
        assert only_store_b == {'Eve', 'Frank'}, "only_store_b incorrect"
        assert all_customers == {'Alice', 'Bob', 'Charlie', 'David', 'Eve', 'Frank'}, "all_customers incorrect"
        print("✅ Part 7: Data deduplication - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Part 7: {e}")
    
    print("="*60)
    print(f"Score: {passed}/{total} ({passed/total*100:.0f}%)")
    print("="*60)
    
    if passed == total:
        print("🎉 Congratulations! All tests passed!")
        print("\n📚 Key Learnings:")
        print("  1. Dictionaries store key-value pairs")
        print("  2. Sets automatically maintain uniqueness")
        print("  3. Dict/set comprehensions provide concise syntax")
        print("  4. Set operations: union, intersection, difference")
        print("  5. Use get() to avoid KeyError with dictionaries")
        print("\n🚀 Next Steps:")
        print("  - Try Lab 04: Control Flow and Conditionals")
        print("  - Review Section 05: Dictionaries and Section 06: Sets")
        print("  - Practice nested dictionaries and frozensets")
    else:
        print("📝 Keep practicing! Review the sections and try again.")

# Run verification
verify_lab_03()
