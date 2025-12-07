"""
Lab 01: Variables and Data Types
Module 10: Python Fundamentals

Objective: Practice creating variables, working with different data types,
          and performing type conversions.

Estimated Time: 1 hour
Difficulty: ⭐ Beginner
"""

# ============================================================================
# PART 1: Variable Assignment (10 minutes)
# ============================================================================

print("=" * 60)
print("PART 1: Variable Assignment")
print("=" * 60)

# TODO 1.1: Create variables for a product
# Create the following variables:
# - product_name: "Wireless Mouse" (string)
# - product_id: 101 (integer)
# - price: 29.99 (float)
# - in_stock: True (boolean)
# - supplier: None (NoneType)

# YOUR CODE HERE


# TODO 1.2: Print all variables with labels
# Expected output format:
# Product Name: Wireless Mouse
# Product ID: 101
# Price: $29.99
# In Stock: True
# Supplier: None

# YOUR CODE HERE


# ============================================================================
# PART 2: Data Types and type() Function (10 minutes)
# ============================================================================

print("\n" + "=" * 60)
print("PART 2: Data Types")
print("=" * 60)

# TODO 2.1: Check types of your variables
# Use type() function to print the type of each variable
# Example: print(f"Type of product_name: {type(product_name)}")

# YOUR CODE HERE


# TODO 2.2: Create variables of each basic type
# Create one variable for each type:
my_integer = None  # Replace None with an integer
my_float = None    # Replace None with a float
my_string = None   # Replace None with a string
my_boolean = None  # Replace None with a boolean

# Print all with their types
# YOUR CODE HERE


# ============================================================================
# PART 3: Type Conversion (15 minutes)
# ============================================================================

print("\n" + "=" * 60)
print("PART 3: Type Conversion")
print("=" * 60)

# Given string variables
age_str = "28"
salary_str = "75000.50"
quantity_str = "100"

# TODO 3.1: Convert strings to appropriate numeric types
# Convert age_str to integer
age = None  # YOUR CODE HERE

# Convert salary_str to float
salary = None  # YOUR CODE HERE

# Convert quantity_str to integer
quantity = None  # YOUR CODE HERE

# Print the converted values and their types
# YOUR CODE HERE


# TODO 3.2: Convert numbers to strings
# Convert the following numbers to strings
current_year = 2025
pi_value = 3.14159

year_str = None  # YOUR CODE HERE
pi_str = None    # YOUR CODE HERE

# Verify they are strings using type()
# YOUR CODE HERE


# TODO 3.3: Handle conversion errors (CHALLENGE)
# Try to convert invalid strings and handle the error

invalid_number = "abc123"

# Try converting invalid_number to int
# Use try-except to catch ValueError
# YOUR CODE HERE


# ============================================================================
# PART 4: Arithmetic Operations (10 minutes)
# ============================================================================

print("\n" + "=" * 60)
print("PART 4: Arithmetic Operations")
print("=" * 60)

# Given values
item_price = 45.50
tax_rate = 0.08  # 8%
quantity = 5

# TODO 4.1: Calculate order totals
# Calculate:
# - subtotal (price * quantity)
# - tax_amount (subtotal * tax_rate)
# - grand_total (subtotal + tax_amount)

subtotal = None      # YOUR CODE HERE
tax_amount = None    # YOUR CODE HERE
grand_total = None   # YOUR CODE HERE

# Print results formatted to 2 decimal places
# Expected output:
# Subtotal: $227.50
# Tax (8%): $18.20
# Grand Total: $245.70

# YOUR CODE HERE


# TODO 4.2: Division operations
# Given: total_items = 47, boxes = 6

total_items = 47
boxes = 6

# Calculate:
# - items_per_box (regular division)
# - full_boxes (floor division)
# - remaining_items (modulus)

items_per_box = None    # YOUR CODE HERE
full_boxes = None       # YOUR CODE HERE
remaining_items = None  # YOUR CODE HERE

print(f"\nItems per box: {items_per_box}")
print(f"Full boxes: {full_boxes}")
print(f"Remaining items: {remaining_items}")


# ============================================================================
# PART 5: String Operations (10 minutes)
# ============================================================================

print("\n" + "=" * 60)
print("PART 5: String Operations")
print("=" * 60)

# Given data
first_name = "John"
last_name = "Doe"
age = 30
city = "New York"

# TODO 5.1: String concatenation
# Create full_name by concatenating first_name and last_name with a space

full_name = None  # YOUR CODE HERE

print(f"Full Name: {full_name}")


# TODO 5.2: f-string formatting
# Create a formatted message using all variables
# Expected: "John Doe is 30 years old and lives in New York"

message = None  # YOUR CODE HERE (use f-string)

print(f"Message: {message}")


# TODO 5.3: Multi-line strings
# Create a multi-line address using triple quotes

address = None  # YOUR CODE HERE
"""
Expected format:
John Doe
123 Main Street
New York, NY 10001
"""

print("Address:")
print(address)


# ============================================================================
# PART 6: Boolean Operations (10 minutes)
# ============================================================================

print("\n" + "=" * 60)
print("PART 6: Boolean Operations")
print("=" * 60)

# Customer data
customer_age = 25
account_balance = 5000
has_credit_card = True
credit_score = 720

# TODO 6.1: Comparison operations
# Create boolean variables using comparisons

is_adult = None           # age >= 18
has_sufficient_funds = None  # balance >= 1000
is_senior = None          # age >= 65

# Print results
# YOUR CODE HERE


# TODO 6.2: Logical operations
# Combine conditions using AND, OR, NOT

# Customer qualifies for premium if:
# - Is adult AND has credit card AND credit score >= 700
qualifies_for_premium = None  # YOUR CODE HERE

# Customer gets discount if:
# - Is senior OR has credit card
gets_discount = None  # YOUR CODE HERE

# Account needs review if:
# - NOT has_sufficient_funds OR credit_score < 650
needs_review = None  # YOUR CODE HERE

print(f"Qualifies for Premium: {qualifies_for_premium}")
print(f"Gets Discount: {gets_discount}")
print(f"Needs Review: {needs_review}")


# ============================================================================
# PART 7: Practical Challenge (15 minutes)
# ============================================================================

print("\n" + "=" * 60)
print("PART 7: Sales Commission Calculator")
print("=" * 60)

"""
CHALLENGE: Calculate sales commission for an employee

Given data:
- Employee: "Sarah Johnson"
- Base salary: $50,000
- Total sales: $250,000
- Commission rate: 5% for sales up to $200k, 7% for sales above $200k
- Tax rate: 22%

Calculate:
1. Commission on first $200k
2. Commission on remaining sales
3. Total commission
4. Gross income (base + commission)
5. Tax amount
6. Net income (gross - tax)

Print all values formatted nicely
"""

# Given data
employee_name = "Sarah Johnson"
base_salary = 50000
total_sales = 250000
standard_commission_rate = 0.05  # 5%
bonus_commission_rate = 0.07     # 7%
sales_threshold = 200000
tax_rate = 0.22  # 22%

# YOUR CODE HERE
# Calculate all required values


# Print formatted report
# YOUR CODE HERE
"""
Expected output format:
===== Sales Commission Report =====
Employee: Sarah Johnson
Base Salary: $50,000.00
Total Sales: $250,000.00

Commission Breakdown:
- First $200,000 @ 5%: $10,000.00
- Remaining $50,000 @ 7%: $3,500.00
- Total Commission: $13,500.00

Income Summary:
- Gross Income: $63,500.00
- Tax (22%): $13,970.00
- Net Income: $49,530.00
"""


# ============================================================================
# LAB COMPLETION CHECKLIST
# ============================================================================

print("\n" + "=" * 60)
print("LAB 01 COMPLETION CHECKLIST")
print("=" * 60)

print("""
[ ] Part 1: Created all product variables
[ ] Part 2: Used type() to check data types
[ ] Part 3: Performed type conversions
[ ] Part 4: Calculated arithmetic operations
[ ] Part 5: Formatted strings with f-strings
[ ] Part 6: Used boolean logic correctly
[ ] Part 7: Completed sales commission challenge

✅ If all parts complete, you're ready for Lab 02!
""")

# ============================================================================
# VERIFICATION TESTS (Don't modify - for self-checking)
# ============================================================================

def verify_lab():
    """Run basic verification checks"""
    print("\n" + "=" * 60)
    print("RUNNING VERIFICATION CHECKS...")
    print("=" * 60)
    
    checks_passed = 0
    total_checks = 5
    
    # Check 1: Variables exist
    try:
        assert 'product_name' in locals() or 'product_name' in globals()
        print("✅ Check 1: Variables created")
        checks_passed += 1
    except:
        print("❌ Check 1: Missing variables")
    
    # Check 2: Type conversions
    try:
        assert isinstance(age, int)
        assert isinstance(salary, float)
        print("✅ Check 2: Type conversions correct")
        checks_passed += 1
    except:
        print("❌ Check 2: Type conversion issues")
    
    # Check 3: Calculations
    try:
        assert subtotal == 227.50
        print("✅ Check 3: Arithmetic calculations correct")
        checks_passed += 1
    except:
        print("❌ Check 3: Calculation errors")
    
    # Check 4: String operations
    try:
        assert full_name == "John Doe"
        print("✅ Check 4: String operations correct")
        checks_passed += 1
    except:
        print("❌ Check 4: String operation issues")
    
    # Check 5: Boolean logic
    try:
        assert is_adult == True
        print("✅ Check 5: Boolean logic correct")
        checks_passed += 1
    except:
        print("❌ Check 5: Boolean logic issues")
    
    print(f"\n📊 Score: {checks_passed}/{total_checks} checks passed")
    
    if checks_passed == total_checks:
        print("🎉 Excellent! All checks passed!")
    elif checks_passed >= 3:
        print("👍 Good progress! Review failed checks.")
    else:
        print("📚 Keep practicing! Review the sections.")

# Uncomment to run verification
# verify_lab()
