"""
Module 10 - Lab 02: Lists and Tuples
====================================
Practice working with lists and tuples.

கற்க கசடற - Learn Flawlessly

Estimated Time: 60 minutes
Concepts: Lists, tuples, indexing, slicing, methods, comprehensions
"""

# Part 1: List Basics (10 minutes)
# ---------------------------------
# TODO: Create a list called 'fruits' with 5 different fruits


# TODO: Print the first fruit


# TODO: Print the last fruit using negative indexing


# TODO: Print the middle 3 fruits using slicing


# TODO: Change the second fruit to 'blueberry'


# Part 2: List Methods (15 minutes)
# ---------------------------------
# TODO: Create an empty list called 'numbers'


# TODO: Add numbers 1-5 to the list using append()


# TODO: Insert the number 0 at the beginning


# TODO: Remove the number 3 from the list


# TODO: Sort the list in descending order


# TODO: Print the length of the list


# Part 3: List Comprehensions (15 minutes)
# ----------------------------------------
# TODO: Create a list of squares of numbers 1-10 using list comprehension
squares = None  # Replace None


# TODO: Create a list of even numbers from 1-20 using list comprehension
evens = None  # Replace None


# TODO: Create a list of uppercase words from ['hello', 'world', 'python']
words = ['hello', 'world', 'python']
uppercase_words = None  # Replace None


# TODO: Create a list of lengths of the words
word_lengths = None  # Replace None


# Part 4: Tuple Basics (10 minutes)
# ---------------------------------
# TODO: Create a tuple called 'coordinates' with x=10, y=20, z=30


# TODO: Try to change the first value (this should fail)
# Uncomment the next line to see the error:
# coordinates[0] = 15


# TODO: Create a tuple with one element (remember the comma!)
single_item = None  # Replace None


# TODO: Unpack the coordinates tuple into three variables x, y, z


# TODO: Print each variable


# Part 5: Tuple Packing and Unpacking (10 minutes)
# ------------------------------------------------
# TODO: Create a function that returns multiple values as a tuple
def get_student_info():
    """Return name, age, grade as tuple"""
    pass  # Replace with your code


# TODO: Call the function and unpack the values


# TODO: Use tuple unpacking in a for loop to iterate over pairs
pairs = [(1, 'one'), (2, 'two'), (3, 'three')]
# for num, word in pairs:
#     print(f"{num}: {word}")


# Part 6: List vs Tuple (5 minutes)
# ---------------------------------
# TODO: Create a list and tuple with same elements [1, 2, 3]
my_list = None  # Replace None
my_tuple = None  # Replace None


# TODO: Try appending 4 to both (one will fail)
# Uncomment to test:
# my_list.append(4)
# my_tuple.append(4)  # This will raise AttributeError


# TODO: Compare which one is faster using timeit (optional)


# Part 7: Practical Challenge - Contact List (15 minutes)
# -------------------------------------------------------
"""
Create a contact management system using lists and tuples.

Requirements:
1. Store contacts as tuples (name, phone, email)
2. Maintain a list of contacts
3. Implement functions to:
   - Add contact
   - Find contact by name
   - List all contacts
   - Remove contact by name
"""

# TODO: Create an empty list to store contacts
contacts = []


# TODO: Create function to add a contact
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
    pass  # Replace with your code


# TODO: Create function to find a contact by name
def find_contact(name):
    """
    Find a contact by name.
    
    Args:
        name: Name to search for (str)
    
    Returns:
        Contact tuple if found, None otherwise
    """
    pass  # Replace with your code


# TODO: Create function to list all contacts
def list_contacts():
    """
    Display all contacts in a formatted way.
    
    Returns:
        None
    """
    pass  # Replace with your code


# TODO: Create function to remove a contact by name
def remove_contact(name):
    """
    Remove a contact by name.
    
    Args:
        name: Name of contact to remove (str)
    
    Returns:
        bool: True if removed, False if not found
    """
    pass  # Replace with your code


# TODO: Test your contact system
# Uncomment to test:
# add_contact("Alice", "555-0100", "alice@email.com")
# add_contact("Bob", "555-0101", "bob@email.com")
# add_contact("Charlie", "555-0102", "charlie@email.com")
# list_contacts()
# print("\nFinding Alice:")
# print(find_contact("Alice"))
# print("\nRemoving Bob:")
# remove_contact("Bob")
# list_contacts()


# ============================================================================
# DO NOT MODIFY BELOW THIS LINE - Verification Code
# ============================================================================

def verify_lab_02():
    """
    Verify that all lab exercises are completed correctly.
    
    Returns:
        None
    """
    print("\n" + "="*50)
    print("Lab 02 Verification")
    print("="*50)
    
    try:
        # Verify Part 1
        assert 'fruits' in dir(), "❌ Part 1: 'fruits' list not created"
        assert isinstance(fruits, list), "❌ Part 1: 'fruits' should be a list"
        assert len(fruits) >= 3, "❌ Part 1: 'fruits' should have at least 3 items"
        print("✅ Part 1: List basics - PASSED")
    except (AssertionError, NameError) as e:
        print(f"❌ Part 1: {e}")
    
    try:
        # Verify Part 2
        assert 'numbers' in dir(), "❌ Part 2: 'numbers' list not created"
        assert isinstance(numbers, list), "❌ Part 2: 'numbers' should be a list"
        print("✅ Part 2: List methods - PASSED")
    except (AssertionError, NameError) as e:
        print(f"❌ Part 2: {e}")
    
    try:
        # Verify Part 3
        assert squares is not None, "❌ Part 3: 'squares' not created"
        assert evens is not None, "❌ Part 3: 'evens' not created"
        assert uppercase_words is not None, "❌ Part 3: 'uppercase_words' not created"
        assert word_lengths is not None, "❌ Part 3: 'word_lengths' not created"
        print("✅ Part 3: List comprehensions - PASSED")
    except (AssertionError, NameError) as e:
        print(f"❌ Part 3: {e}")
    
    try:
        # Verify Part 4
        assert 'coordinates' in dir(), "❌ Part 4: 'coordinates' tuple not created"
        assert isinstance(coordinates, tuple), "❌ Part 4: 'coordinates' should be a tuple"
        assert len(coordinates) == 3, "❌ Part 4: 'coordinates' should have 3 elements"
        print("✅ Part 4: Tuple basics - PASSED")
    except (AssertionError, NameError) as e:
        print(f"❌ Part 4: {e}")
    
    try:
        # Verify Part 5
        assert callable(get_student_info), "❌ Part 5: 'get_student_info' function not created"
        result = get_student_info()
        assert isinstance(result, tuple), "❌ Part 5: Function should return a tuple"
        print("✅ Part 5: Tuple packing/unpacking - PASSED")
    except (AssertionError, NameError) as e:
        print(f"❌ Part 5: {e}")
    
    try:
        # Verify Part 6
        assert 'my_list' in dir() and my_list is not None, "❌ Part 6: 'my_list' not created"
        assert 'my_tuple' in dir() and my_tuple is not None, "❌ Part 6: 'my_tuple' not created"
        assert isinstance(my_list, list), "❌ Part 6: 'my_list' should be a list"
        assert isinstance(my_tuple, tuple), "❌ Part 6: 'my_tuple' should be a tuple"
        print("✅ Part 6: List vs Tuple - PASSED")
    except (AssertionError, NameError) as e:
        print(f"❌ Part 6: {e}")
    
    try:
        # Verify Part 7
        assert 'contacts' in dir(), "❌ Part 7: 'contacts' list not created"
        assert callable(add_contact), "❌ Part 7: 'add_contact' function not created"
        assert callable(find_contact), "❌ Part 7: 'find_contact' function not created"
        assert callable(list_contacts), "❌ Part 7: 'list_contacts' function not created"
        assert callable(remove_contact), "❌ Part 7: 'remove_contact' function not created"
        
        # Test functionality
        test_contacts = []
        
        def test_add(name, phone, email):
            test_contacts.append((name, phone, email))
        
        test_add("Test", "555-0000", "test@test.com")
        assert len(test_contacts) == 1, "❌ Part 7: add_contact not working properly"
        
        print("✅ Part 7: Contact list challenge - PASSED")
    except (AssertionError, NameError) as e:
        print(f"❌ Part 7: {e}")
    
    print("="*50)
    print("Verification complete!")
    print("="*50)

# Uncomment the line below to run verification after completing the lab
# verify_lab_02()
