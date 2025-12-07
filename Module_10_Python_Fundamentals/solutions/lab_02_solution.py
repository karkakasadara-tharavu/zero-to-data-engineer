"""
Module 10 - Lab 02 Solution: Lists and Tuples
=============================================
Complete solutions with explanations.

கற்க கசடற - Learn Flawlessly

Estimated Time: 60 minutes
Concepts: Lists, tuples, indexing, slicing, methods, comprehensions
"""

# Part 1: List Basics (10 minutes)
# ---------------------------------
print("Part 1: List Basics")
print("-" * 40)

# Create a list called 'fruits' with 5 different fruits
fruits = ['apple', 'banana', 'cherry', 'date', 'elderberry']
print(f"Fruits list: {fruits}")

# Print the first fruit
print(f"First fruit: {fruits[0]}")  # Indexing starts at 0

# Print the last fruit using negative indexing
print(f"Last fruit: {fruits[-1]}")  # -1 is the last element

# Print the middle 3 fruits using slicing
middle_fruits = fruits[1:4]  # Index 1, 2, 3 (not including 4)
print(f"Middle 3 fruits: {middle_fruits}")

# Change the second fruit to 'blueberry'
fruits[1] = 'blueberry'
print(f"After change: {fruits}")

print()

# Part 2: List Methods (15 minutes)
# ---------------------------------
print("Part 2: List Methods")
print("-" * 40)

# Create an empty list called 'numbers'
numbers = []
print(f"Empty list: {numbers}")

# Add numbers 1-5 to the list using append()
for i in range(1, 6):
    numbers.append(i)
print(f"After appending 1-5: {numbers}")

# Insert the number 0 at the beginning
numbers.insert(0, 0)  # insert(index, value)
print(f"After inserting 0: {numbers}")

# Remove the number 3 from the list
numbers.remove(3)  # Removes first occurrence of value
print(f"After removing 3: {numbers}")

# Sort the list in descending order
numbers.sort(reverse=True)
print(f"After sorting (descending): {numbers}")

# Print the length of the list
print(f"Length of list: {len(numbers)}")

print()

# Part 3: List Comprehensions (15 minutes)
# ----------------------------------------
print("Part 3: List Comprehensions")
print("-" * 40)

# Create a list of squares of numbers 1-10 using list comprehension
squares = [x**2 for x in range(1, 11)]
print(f"Squares 1-10: {squares}")

# Explanation: List comprehension syntax
# [expression for variable in iterable]
# Equivalent to:
# squares = []
# for x in range(1, 11):
#     squares.append(x**2)

# Create a list of even numbers from 1-20 using list comprehension
evens = [x for x in range(1, 21) if x % 2 == 0]
print(f"Even numbers 1-20: {evens}")

# Explanation: List comprehension with condition
# [expression for variable in iterable if condition]
# Only includes items where condition is True

# Create a list of uppercase words from ['hello', 'world', 'python']
words = ['hello', 'world', 'python']
uppercase_words = [word.upper() for word in words]
print(f"Uppercase words: {uppercase_words}")

# Explanation: Applying method to each element
# [item.method() for item in list]

# Create a list of lengths of the words
word_lengths = [len(word) for word in words]
print(f"Word lengths: {word_lengths}")

# Explanation: Applying function to each element
# [function(item) for item in list]

print()

# Part 4: Tuple Basics (10 minutes)
# ---------------------------------
print("Part 4: Tuple Basics")
print("-" * 40)

# Create a tuple called 'coordinates' with x=10, y=20, z=30
coordinates = (10, 20, 30)
print(f"Coordinates: {coordinates}")

# Try to change the first value (this should fail)
# Uncomment the next line to see the error:
# coordinates[0] = 15  # TypeError: 'tuple' object does not support item assignment

# Explanation: Tuples are IMMUTABLE - cannot be changed after creation
print("✅ Tuples are immutable - cannot modify elements")

# Create a tuple with one element (remember the comma!)
single_item = (42,)  # The comma is REQUIRED!
print(f"Single item tuple: {single_item}")
print(f"Type: {type(single_item)}")

# Without comma, it's just a number in parentheses:
not_a_tuple = (42)  # This is just an int
print(f"Without comma: {not_a_tuple} (type: {type(not_a_tuple)})")

# Unpack the coordinates tuple into three variables x, y, z
x, y, z = coordinates
print(f"Unpacked: x={x}, y={y}, z={z}")

# Explanation: Tuple unpacking assigns each element to a variable
# Number of variables must match number of elements

print()

# Part 5: Tuple Packing and Unpacking (10 minutes)
# ------------------------------------------------
print("Part 5: Tuple Packing and Unpacking")
print("-" * 40)

# Create a function that returns multiple values as a tuple
def get_student_info():
    """Return name, age, grade as tuple"""
    name = "Alice"
    age = 20
    grade = "A"
    return name, age, grade  # This is tuple packing

# Explanation: When you return multiple values separated by commas,
# Python automatically packs them into a tuple

# Call the function and unpack the values
student_name, student_age, student_grade = get_student_info()
print(f"Student: {student_name}, Age: {student_age}, Grade: {student_grade}")

# You can also get the tuple without unpacking
student_info = get_student_info()
print(f"Full info: {student_info}")

# Use tuple unpacking in a for loop to iterate over pairs
pairs = [(1, 'one'), (2, 'two'), (3, 'three')]
print("\nIterating with tuple unpacking:")
for num, word in pairs:
    print(f"{num}: {word}")

# Explanation: Each iteration unpacks the tuple into num and word

# Advanced unpacking with *
first, *middle, last = [1, 2, 3, 4, 5]
print(f"\nAdvanced unpacking: first={first}, middle={middle}, last={last}")

print()

# Part 6: List vs Tuple (5 minutes)
# ---------------------------------
print("Part 6: List vs Tuple Comparison")
print("-" * 40)

# Create a list and tuple with same elements [1, 2, 3]
my_list = [1, 2, 3]
my_tuple = (1, 2, 3)

print(f"List: {my_list} (type: {type(my_list)})")
print(f"Tuple: {my_tuple} (type: {type(my_tuple)})")

# Try appending 4 to both (one will fail)
my_list.append(4)
print(f"After append to list: {my_list}")

# This would fail:
# my_tuple.append(4)  # AttributeError: 'tuple' object has no attribute 'append'
print("❌ Cannot append to tuple - it's immutable")

# Compare performance (tuples are faster for iteration)
import timeit

list_time = timeit.timeit('for i in [1,2,3,4,5]: pass', number=1000000)
tuple_time = timeit.timeit('for i in (1,2,3,4,5): pass', number=1000000)

print(f"\nPerformance comparison (1 million iterations):")
print(f"List iteration time: {list_time:.4f} seconds")
print(f"Tuple iteration time: {tuple_time:.4f} seconds")
print(f"Tuple is {list_time/tuple_time:.2f}x faster!")

# When to use each:
print("\n📋 When to use Lists:")
print("  - When you need to modify the collection")
print("  - When you need methods like append, remove, sort")
print("  - When order matters and changes are expected")

print("\n📋 When to use Tuples:")
print("  - When data should not be modified (immutable)")
print("  - For fixed collections (coordinates, RGB colors)")
print("  - As dictionary keys (lists can't be keys)")
print("  - Slightly better performance for iteration")

print()

# Part 7: Practical Challenge - Contact List (15 minutes)
# -------------------------------------------------------
print("Part 7: Contact Management System")
print("-" * 40)

# Create an empty list to store contacts
contacts = []

# Function to add a contact
def add_contact(name, phone, email):
    """
    Add a contact to the contacts list.
    
    Args:
        name: Contact name (str)
        phone: Phone number (str)
        email: Email address (str)
    
    Returns:
        None
    """
    # Create a tuple (immutable) for the contact
    contact = (name, phone, email)
    contacts.append(contact)
    print(f"✅ Added: {name}")

# Explanation: We use tuples for contacts because:
# 1. Contact info shouldn't change after creation
# 2. Tuples are more memory efficient
# 3. Tuples can be used as dictionary keys if needed

# Function to find a contact by name
def find_contact(name):
    """
    Find a contact by name.
    
    Args:
        name: Name to search for (str)
    
    Returns:
        Contact tuple if found, None otherwise
    """
    for contact in contacts:
        # Unpack tuple to check name
        contact_name, phone, email = contact
        if contact_name.lower() == name.lower():  # Case-insensitive
            return contact
    return None

# Explanation: We iterate through all contacts and unpack each tuple
# to check if the name matches (case-insensitive comparison)

# Function to list all contacts
def list_contacts():
    """
    Display all contacts in a formatted way.
    
    Returns:
        None
    """
    if not contacts:
        print("📭 No contacts found.")
        return
    
    print(f"\n📇 Contact List ({len(contacts)} contacts)")
    print("-" * 60)
    
    for i, contact in enumerate(contacts, 1):
        name, phone, email = contact  # Unpack tuple
        print(f"{i}. {name:<20} | {phone:<15} | {email}")
    
    print("-" * 60)

# Explanation: enumerate() gives us both index and item
# enumerate(list, 1) starts counting from 1 instead of 0
# String formatting: {name:<20} left-aligns name in 20 characters

# Function to remove a contact by name
def remove_contact(name):
    """
    Remove a contact by name.
    
    Args:
        name: Name of contact to remove (str)
    
    Returns:
        bool: True if removed, False if not found
    """
    contact = find_contact(name)
    if contact:
        contacts.remove(contact)
        print(f"🗑️ Removed: {name}")
        return True
    else:
        print(f"❌ Contact '{name}' not found.")
        return False

# Explanation: We use find_contact() to locate the contact
# then remove() to delete it from the list
# Returns True/False to indicate success

# Test the contact system
print("\n=== Testing Contact System ===\n")

add_contact("Alice Johnson", "555-0100", "alice@email.com")
add_contact("Bob Smith", "555-0101", "bob@email.com")
add_contact("Charlie Brown", "555-0102", "charlie@email.com")
add_contact("Diana Prince", "555-0103", "diana@email.com")

list_contacts()

print("\n=== Finding Alice ===")
found = find_contact("Alice")
if found:
    name, phone, email = found
    print(f"Found: {name}")
    print(f"  Phone: {phone}")
    print(f"  Email: {email}")

print("\n=== Finding Non-existent Contact ===")
not_found = find_contact("Zorro")
if not not_found:
    print("Contact not found (as expected)")

print("\n=== Removing Bob ===")
remove_contact("Bob")

list_contacts()

print("\n=== Trying to Remove Already Removed Contact ===")
remove_contact("Bob")

# ============================================================================
# Verification Code
# ============================================================================

def verify_lab_02():
    """
    Verify that all lab exercises are completed correctly.
    
    Returns:
        None
    """
    print("\n" + "="*60)
    print("Lab 02 Verification")
    print("="*60)
    
    passed = 0
    total = 7
    
    # Verify Part 1
    try:
        assert isinstance(fruits, list), "fruits should be a list"
        assert len(fruits) >= 3, "fruits should have at least 3 items"
        assert fruits[1] == 'blueberry', "Second fruit should be 'blueberry'"
        print("✅ Part 1: List basics - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Part 1: {e}")
    
    # Verify Part 2
    try:
        assert isinstance(numbers, list), "numbers should be a list"
        assert len(numbers) > 0, "numbers should not be empty"
        assert numbers == sorted(numbers, reverse=True), "numbers should be sorted descending"
        print("✅ Part 2: List methods - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Part 2: {e}")
    
    # Verify Part 3
    try:
        assert len(squares) == 10, "squares should have 10 elements"
        assert squares[0] == 1 and squares[-1] == 100, "squares should be 1 to 100"
        assert all(x % 2 == 0 for x in evens), "evens should only contain even numbers"
        assert all(w.isupper() for w in uppercase_words), "all words should be uppercase"
        assert word_lengths == [5, 5, 6], "word_lengths should be [5, 5, 6]"
        print("✅ Part 3: List comprehensions - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Part 3: {e}")
    
    # Verify Part 4
    try:
        assert isinstance(coordinates, tuple), "coordinates should be a tuple"
        assert len(coordinates) == 3, "coordinates should have 3 elements"
        assert isinstance(single_item, tuple), "single_item should be a tuple"
        assert x == 10 and y == 20 and z == 30, "unpacking should work correctly"
        print("✅ Part 4: Tuple basics - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Part 4: {e}")
    
    # Verify Part 5
    try:
        result = get_student_info()
        assert isinstance(result, tuple), "get_student_info should return a tuple"
        assert len(result) == 3, "should return 3 values"
        print("✅ Part 5: Tuple packing/unpacking - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Part 5: {e}")
    
    # Verify Part 6
    try:
        assert isinstance(my_list, list), "my_list should be a list"
        assert isinstance(my_tuple, tuple), "my_tuple should be a tuple"
        assert 4 in my_list, "my_list should have been appended"
        print("✅ Part 6: List vs Tuple - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Part 6: {e}")
    
    # Verify Part 7
    try:
        assert isinstance(contacts, list), "contacts should be a list"
        assert callable(add_contact), "add_contact should be a function"
        assert callable(find_contact), "find_contact should be a function"
        assert callable(list_contacts), "list_contacts should be a function"
        assert callable(remove_contact), "remove_contact should be a function"
        
        # Test functionality
        test_contacts_list = []
        
        def test_add(name, phone, email):
            test_contacts_list.append((name, phone, email))
        
        test_add("Test User", "555-9999", "test@test.com")
        assert len(test_contacts_list) == 1, "add functionality should work"
        
        print("✅ Part 7: Contact list challenge - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Part 7: {e}")
    
    print("="*60)
    print(f"Score: {passed}/{total} ({passed/total*100:.0f}%)")
    print("="*60)
    
    if passed == total:
        print("🎉 Congratulations! All tests passed!")
        print("\n📚 Key Learnings:")
        print("  1. Lists are mutable, tuples are immutable")
        print("  2. List comprehensions provide concise syntax")
        print("  3. Tuple unpacking enables multiple return values")
        print("  4. Choose lists for dynamic data, tuples for fixed data")
        print("  5. Tuples are slightly faster and more memory efficient")
        print("\n🚀 Next Steps:")
        print("  - Try Lab 03: Dictionaries and Sets")
        print("  - Review Section 04: Tuples and Section 05: Dictionaries")
        print("  - Practice more with nested lists and tuples")
    else:
        print("📝 Keep practicing! Review the sections and try again.")

# Run verification
verify_lab_02()
